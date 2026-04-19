import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get all FCM tokens with their timezone
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);

    const now = new Date();
    const morningUsers: string[] = [];
    const eveningUsers: string[] = [];
    const tokensMap = new Map<string, string>();

    // Step 1: Filter users based on their local time
    for (const row of fcmTokens || []) {
      const tz = row.timezone || 'UTC';
      let hourStr;
      
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz,
          hour: 'numeric',
          hour12: false,
        }).formatToParts(now);
        hourStr = parts.find(p => p.type === 'hour')?.value;
      } catch (e) {
        // Fallback to UTC if timezone is invalid
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: 'UTC',
          hour: 'numeric',
          hour12: false,
        }).formatToParts(now);
        hourStr = parts.find(p => p.type === 'hour')?.value;
      }

      if (hourStr) {
        const hour = parseInt(hourStr, 10);
        if (hour === 8) {
          morningUsers.push(row.user_id);
          tokensMap.set(row.user_id, row.token);
        } else if (hour === 17) {
          eveningUsers.push(row.user_id);
          tokensMap.set(row.user_id, row.token);
        }
      }
    }

    if (morningUsers.length === 0 && eveningUsers.length === 0) {
      return new Response(JSON.stringify({ message: 'No users at 08:00 or 17:00 in their timezone right now.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 2: Check azkaar_logs within the last 12 hours
    const twelveHoursAgo = new Date(now.getTime() - 12 * 60 * 60 * 1000).toISOString();
    
    const tokensToSendMorning: string[] = [];
    const tokensToSendEvening: string[] = [];

    // Check morning users 
    if (morningUsers.length > 0) {
      const { data: recentMorning, error: morningErr } = await supabase
        .from('azkaar_logs')
        .select('user_id')
        .in('user_id', morningUsers)
        .eq('category', 'morning')
        .gte('created_at', twelveHoursAgo);

      if (morningErr) throw new Error(`Morning logs error: ${morningErr.message}`);

      const loggedMorning = new Set((recentMorning || []).map(r => r.user_id));
      for (const userId of morningUsers) {
        if (!loggedMorning.has(userId)) {
          tokensToSendMorning.push(tokensMap.get(userId)!);
        }
      }
    }

    // Check evening users
    if (eveningUsers.length > 0) {
      const { data: recentEvening, error: eveningErr } = await supabase
        .from('azkaar_logs')
        .select('user_id')
        .in('user_id', eveningUsers)
        .eq('category', 'evening')
        .gte('created_at', twelveHoursAgo);

      if (eveningErr) throw new Error(`Evening logs error: ${eveningErr.message}`);

      const loggedEvening = new Set((recentEvening || []).map(r => r.user_id));
      for (const userId of eveningUsers) {
        if (!loggedEvening.has(userId)) {
          tokensToSendEvening.push(tokensMap.get(userId)!);
        }
      }
    }

    if (tokensToSendMorning.length === 0 && tokensToSendEvening.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users have already logged their azkaar.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 2.5: Deduplicate — skip users already notified today
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id, notification_type')
      .in('notification_type', ['morning_azkaar', 'evening_azkaar'])
      .gte('sent_at', todayStart.toISOString());

    const sentMorningSet = new Set<string>();
    const sentEveningSet = new Set<string>();
    for (const r of alreadySent || []) {
      if (r.notification_type === 'morning_azkaar') sentMorningSet.add(r.user_id);
      if (r.notification_type === 'evening_azkaar') sentEveningSet.add(r.user_id);
    }

    const dedupedMorningUsers: string[] = [];
    const dedupedMorningTokens: string[] = [];
    for (const userId of morningUsers) {
      const token = tokensMap.get(userId);
      if (token && tokensToSendMorning.includes(token) && !sentMorningSet.has(userId)) {
        dedupedMorningUsers.push(userId);
        dedupedMorningTokens.push(token);
      }
    }

    const dedupedEveningUsers: string[] = [];
    const dedupedEveningTokens: string[] = [];
    for (const userId of eveningUsers) {
      const token = tokensMap.get(userId);
      if (token && tokensToSendEvening.includes(token) && !sentEveningSet.has(userId)) {
        dedupedEveningUsers.push(userId);
        dedupedEveningTokens.push(token);
      }
    }

    if (dedupedMorningTokens.length === 0 && dedupedEveningTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users already notified today.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 3: Build Google OAuth2 Token utilizing Service Account Secrets
    const projectId = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyStr) {
      throw new Error('FCM configs missing (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY)');
    }

    const privateKey = privateKeyStr.replace(/\\n/g, '\n');
    const privateKeyObj = await importPKCS8(privateKey, 'RS256');
    
    const jwt = await new SignJWT({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
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

    const tokenDataRes = await tokenResponse.json();
    if (!tokenResponse.ok) {
      throw new Error(`Google Auth error: ${tokenDataRes.error_description || tokenDataRes.error}`);
    }

    const accessToken = tokenDataRes.access_token;
    const results = [];

    // Step 4: Send Firebase Notifications in bulk loop
    // Morning reminders
    for (let i = 0; i < dedupedMorningTokens.length; i++) {
      const token = dedupedMorningTokens[i];
      const userId = dedupedMorningUsers[i];
      const fcmPayload = {
        message: {
          token: token,
          notification: {
            title: '🌅 Morning Azkaar',
            body: 'Start your day with blessings. Tap to read your morning Azkaar.'
          },
          android: {
            priority: 'high',
            notification: { sound: 'default' }
          }
        }
      };

      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      const resJson = await fcmResponse.json();
      results.push({ token, type: 'morning', success: fcmResponse.ok, result: resJson });

      if (fcmResponse.ok) {
        await supabase.from('notification_log').insert({
          user_id: userId,
          notification_type: 'morning_azkaar',
          sent_at: now.toISOString(),
        }).catch(() => {});
      }
    }

    // Evening reminders
    for (let i = 0; i < dedupedEveningTokens.length; i++) {
      const token = dedupedEveningTokens[i];
      const userId = dedupedEveningUsers[i];
      const fcmPayload = {
        message: {
          token: token,
          notification: {
            title: '🌇 Evening Azkaar',
            body: 'Protect yourself for the night. Tap to read your evening Azkaar.'
          },
          android: {
            priority: 'high',
            notification: { sound: 'default' }
          }
        }
      };

      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      const resJson = await fcmResponse.json();
      results.push({ token, type: 'evening', success: fcmResponse.ok, result: resJson });

      if (fcmResponse.ok) {
        await supabase.from('notification_log').insert({
          user_id: userId,
          notification_type: 'evening_azkaar',
          sent_at: now.toISOString(),
        }).catch(() => {});
      }
    }

    return new Response(JSON.stringify({
      success: true,
      sent_morning_count: dedupedMorningTokens.length,
      sent_evening_count: dedupedEveningTokens.length,
      results
    }), {
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
