import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';

serve(async (req: Request) => {
  try {
    // 1. Supabase Database Webhooks send POST requests with a JSON payload
    const payload = await req.json();

    // Verify this is an INSERT payload (ignore UPDATES or DELETES to prevent spam)
    if (payload.type !== 'INSERT' || !payload.record) {
      return new Response(JSON.stringify({ message: 'Ignored: Not an INSERT event' }), { status: 200 });
    }

    const record = payload.record;
    
    // We expect the row to have a user_id or uid foreign key
    const userId = record.user_id || record.uid;
    if (!userId) {
      return new Response(JSON.stringify({ message: 'Ignored: No user_id found in record' }), { status: 200 });
    }

    // 2. Dynamically Parse the Reward Details based on typical column names (handles user_badges and user_activities)
    const rewardName = record.reward_name || record.title || record.reason || record.badge_name || record.badge_id || record.activity_type || '';
    const pointsAmt = record.points || record.amount || record.xp || record.coins || record.points_earned;
    
    let pushMessage = 'Congratulations! You just earned a new reward!';
    if (rewardName && pointsAmt) {
      pushMessage = `You earned ${pointsAmt} points for ${rewardName}!`;
    } else if (rewardName) {
      pushMessage = `You just unlocked: ${rewardName}!`;
    } else if (pointsAmt) {
      pushMessage = `You just earned ${pointsAmt} points! Keep it up!`;
    }

    // 3. Initialize Supabase Admin Client
    // Webhooks come directly from the Postgres Database, meaning there is NO user Authorization header.
    // We must use the SERVICE_ROLE_KEY to bypass RLS and securely look up the user's FCM token.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Query FCM Token
    const { data: tokenData, error: dbError } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', userId)
      .single();

    // If no token exists, silently exit (User might have uninstalled or disabled notifications)
    if (dbError || !tokenData?.token) {
      return new Response(JSON.stringify({ message: 'User has no registered device token' }), { status: 200 });
    }

    const fcmToken = tokenData.token;

    // 4. Build Google OAuth2 Token utilizing Service Account Secrets
    const projectId = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyStr) {
      throw new Error('FCM configs missing in Supabase Settings');
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
      throw new Error(`Google Auth error: ${tokenDataRes.error_description}`);
    }

    const accessToken = tokenDataRes.access_token;

    // 5. Send Firebase Push Notification
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: 'Reward Unlocked 🎉',
          body: pushMessage
        },
        data: {
          type: 'webhook_reward',
          record_id: String(record.id || '')
        },
        android: {
          priority: 'high',
          notification: { sound: 'default' }
        },
        apns: { payload: { aps: { sound: 'default' } } },
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

    const fcmResult = await fcmResponse.json();

    // CRITICAL: We return 200 OK regardless of FCM success.
    // Database Webhooks will indefinitely retry if they receive a 4xx or 5xx code,
    // which could result in massive spam if Firebase drops the request.
    return new Response(JSON.stringify({ 
      success: fcmResponse.ok, 
      sent_to: userId,
      result: fcmResult 
    }), {
      status: 200, 
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    // Return 200 OK on structural failures too to prevent webhook queue blocking
    return new Response(JSON.stringify({ caught_error: err.message }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
