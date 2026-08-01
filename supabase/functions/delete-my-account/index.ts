// delete-my-account — user-initiated account deletion for Play/App Store
// compliance (Play Console → Data Safety → Account Deletion URL requirement,
// Apple guideline 5.1.1(v)).
//
// The caller sends their JWT in the Authorization header; we resolve it to a
// user_id server-side, then use the service_role key to hard-delete their
// data across every user-scoped table AND the auth entry itself.
//
// Deletion is intentionally hard (not soft) — Play/Apple both require that
// the "delete account" action actually removes the user's personal data,
// not just anonymises or disables it.
//
// Order matters:
//   1. fcm_tokens        — stop future pushes immediately (no dangling
//                          tokens sending to a deleted user)
//   2. All user-scoped   — profiles, streaks, xp, activities, bookmarks,
//      data tables         donations, notifications, etc. Belt-and-
//                          suspenders even though most CASCADE from
//                          profiles → auth.users FK.
//   3. auth.admin.deleteUser — removes the auth.users row. Once gone,
//                              the user can never sign in again with the
//                              same credentials.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Every table that stores per-user data keyed by `user_id`. Kept as an
// explicit list rather than relying on `information_schema` at runtime
// so a new table with a `user_id` column doesn't silently escape the
// deletion sweep — adding one here is a deliberate, reviewable act.
const USER_SCOPED_TABLES = [
  'fcm_tokens',
  'user_analytics',
  'user_activities',
  'user_progress',
  'quran_bookmarks',
  'quran_favorites',
  'user_donations',
  'streak_history',
  'user_badges',
  'user_challenge_progress',
  'notification_log',
  'user_notification_pauses',
] as const;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // ── 1. Verify caller's JWT and resolve to a user_id ─────────────────────
    const authHeader = req.headers.get('Authorization') ?? '';
    const jwt = authHeader.replace(/^Bearer\s+/i, '');
    if (!jwt) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: userRes, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userRes?.user?.id) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    const userId = userRes.user.id;

    // ── 2. Delete FCM tokens FIRST so no more pushes can go out ────────────
    //    Even a brief window between "profile deleted" and "tokens deleted"
    //    would let a scheduled push cron find the token and send a message
    //    to a now-stateless user.
    {
      const { error } = await admin
        .from('fcm_tokens')
        .delete()
        .eq('user_id', userId);
      if (error) {
        console.error(`[delete-my-account] fcm_tokens delete failed for ${userId}:`, error);
      }
    }

    // ── 3. Delete user data across every scoped table ──────────────────────
    //    Errors here are logged but not fatal — most likely reason for a
    //    failure is FK CASCADE already removed the rows before we got to
    //    them, which is fine.
    const perTableErrors: Record<string, string> = {};
    for (const table of USER_SCOPED_TABLES) {
      if (table === 'fcm_tokens') continue; // already done above
      const { error } = await admin.from(table).delete().eq('user_id', userId);
      if (error) {
        // 42P01 = undefined table; expected on rollback of a feature that
        // added a table we now list here. Don't fail the whole delete.
        if (!String(error.message).includes('does not exist')) {
          perTableErrors[table] = error.message;
        }
      }
    }

    // ── 4. Delete the profile row (some FKs cascade FROM this, not from
    //       auth.users). Do this AFTER the user-scoped sweep so we don't
    //       trigger cascades mid-iteration.
    {
      const { error } = await admin.from('profiles').delete().eq('id', userId);
      if (error && !String(error.message).includes('does not exist')) {
        perTableErrors['profiles'] = error.message;
      }
    }

    // ── 5. Finally, delete the auth entry. Once this succeeds, the user's
    //       account no longer exists in any form.
    const { error: authDelErr } = await admin.auth.admin.deleteUser(userId);
    if (authDelErr) {
      // If we got here but auth.users deletion failed, the user still
      // has an account they can sign into (though most of their data is
      // gone). Surface this loudly.
      console.error(`[delete-my-account] auth.admin.deleteUser failed for ${userId}:`, authDelErr);
      return new Response(
        JSON.stringify({
          error: 'Data deleted but auth entry removal failed. Contact support.',
          detail: authDelErr.message,
          per_table_errors: perTableErrors,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({
        ok: true,
        user_id: userId,
        per_table_errors: perTableErrors,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('[delete-my-account] unhandled:', e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
