// Daily push cap — prevents any single user from receiving more than
// MAX_PER_DAY server-sent notifications in a UTC day. Local notifications
// scheduled by Flutter's LocalReminderScheduler are NOT in notification_log
// and therefore don't count against the cap — only FCM pushes do.
//
// Call inside every server push function, just before sending to each user:
//
//   import { dailyPushCapReached } from '../_shared/daily_cap.ts';
//   if (await dailyPushCapReached(supabase, userId)) continue;
//
// Fail-open on query error (returns false) — better to send one extra push
// than to silently suppress everyone if the count query is having a bad day.

// deno-lint-ignore no-explicit-any
type SbClient = any;

export const MAX_PUSHES_PER_DAY = 3;

export async function dailyPushCapReached(
  supabase: SbClient,
  userId: string,
  max: number = MAX_PUSHES_PER_DAY,
): Promise<boolean> {
  try {
    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const { count } = await supabase
      .from('notification_log')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gte('sent_at', todayStart.toISOString());
    return (count ?? 0) >= max;
  } catch (_) {
    return false; // fail open
  }
}
