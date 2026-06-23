import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const now = new Date();
    
    // We calculate the stats for the current month.
    const firstDayOfMonth = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));

    // ── 1. Load all FCM tokens ───────────────────────────────────────────────
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);
    if (!fcmTokens || fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No FCM tokens found in database.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ── 2. Dedup tokens per user ──────────────────────────────────────────────
    const tokensMap = new Map<string, string[]>();
    for (const row of fcmTokens) {
      if (!tokensMap.has(row.user_id)) {
        tokensMap.set(row.user_id, []);
      }
      tokensMap.get(row.user_id)!.push(row.token);
    }
    const targetUsers = Array.from(tokensMap.keys());

    // ── 3. Fetch Quran activities for the month ───────────────────────────────
    let allActivities: any[] = [];
    let page = 0;
    const pageSize = 1000;
    while (true) {
      const { data: act, error: actErr } = await supabase
        .from('user_activities')
        .select('user_id, points_earned')
        .eq('activity_type', 'quran')
        .gte('created_at', firstDayOfMonth.toISOString())
        .range(page * pageSize, (page + 1) * pageSize - 1);
        
      if (actErr) throw new Error(`Activities load error: ${actErr.message}`);
      if (!act || act.length === 0) break;
      
      allActivities = allActivities.concat(act);
      if (act.length < pageSize) break;
      page++;
    }

    const userStats = new Map<string, { verses: number, hasanat: number }>();
    for (const act of allActivities) {
      const uid = act.user_id;
      if (!userStats.has(uid)) {
        userStats.set(uid, { verses: 0, hasanat: 0 });
      }
      const st = userStats.get(uid)!;
      st.verses += 1;
      st.hasanat += (act.points_earned || 0);
    }

    // Filter users who actually read something this month
    const usersToNotify = targetUsers.filter(uid => userStats.has(uid) && userStats.get(uid)!.verses > 0);

    if (usersToNotify.length === 0) {
      return new Response(JSON.stringify({ message: 'No users with Quran activity this month.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ── 4. Dedup — skip users already notified this month ─────────────────────
    // Prevent double sending if called multiple times in the same month
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'monthly_quran')
      .gte('sent_at', firstDayOfMonth.toISOString());

    const sentSet = new Set<string>();
    for (const r of alreadySent || []) {
      sentSet.add(r.user_id);
    }

    const finalUsers = usersToNotify.filter(uid => !sentSet.has(uid));

    if (finalUsers.length === 0) {
      return new Response(JSON.stringify({ message: 'All eligible users already notified this month.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ── 5. Get Google OAuth2 access token ─────────────────────────────────────
    const { projectId, clientEmail, privateKey } = getFcmCreds();
    const privateKeyObj = await importPKCS8(privateKey, 'RS256');

    const jwt = await new SignJWT({
      iss:   clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud:   'https://oauth2.googleapis.com/token',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(privateKeyObj);

    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const tokenData = await tokenResponse.json();
    if (!tokenResponse.ok) {
      throw new Error(`Google OAuth error: ${tokenData.error_description ?? tokenData.error}`);
    }
    const accessToken = tokenData.access_token;

    // ── 6. Send notifications ──────────────────────────────────────────────────
    const results: object[] = [];

    const formatNumber = (num: number) => {
      if (num >= 1000) {
        return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
      }
      return num.toString();
    };

    for (const uid of finalUsers) {
      const stats = userStats.get(uid)!;
      const hasanatStr = formatNumber(stats.hasanat);

      const title = 'SubhanAllah! 🚀';
      const body = `This month you read ${stats.verses} verses, gained ${hasanatStr} Hasanat! May Allah accept all our deeds! Ameen 💜`;
      const route = 'quran';
      const nid = crypto.randomUUID();

      const tokens = tokensMap.get(uid)!;
      let anySuccess = false;

      for (const token of tokens) {
        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title, body },
                data: { route, nid },
                android: { priority: 'high', notification: { sound: 'default' } },
                apns: { payload: { aps: { sound: 'default' } } },
              },
            }),
          }
        );

        const resJson = await res.json();
        results.push({ userId: uid, token, success: res.ok, result: resJson });
        if (res.ok) anySuccess = true;
      }

      if (anySuccess) {
        try {
          await supabase.from('notification_log').insert({
            user_id: uid,
            notification_type: 'monthly_quran',
            notification_id: nid,
            title,
            body,
            route,
            sent_at: now.toISOString(),
          });
        } catch (_) {}
      }
    }

    return new Response(JSON.stringify({
      success: true,
      sent_count: finalUsers.length,
      results,
    }), { headers: { 'Content-Type': 'application/json' } });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
