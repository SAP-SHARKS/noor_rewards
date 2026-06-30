// Filter out users whose notifications are paused (set by the
// `check-disengaged-users` edge function when a user goes inactive AND
// ignores a stretch of pushes). They auto-resume via the
// `mark_user_active()` RPC the next time they open the app.
//
// Usage in each push function — call right after fetching fcm_tokens
// (or any other per-user candidate list), BEFORE the timezone / dedup /
// candidate filtering:
//
//   import { filterPausedUsers } from '../_shared/disengagement.ts';
//   const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw);
//
// Silent fallback: on query failure returns the input unchanged — better
// to send a duplicate to a paused user than to skip everyone.

// deno-lint-ignore no-explicit-any
type SbClient = any;

export async function filterPausedUsers<T extends { user_id: string }>(
  supabase: SbClient,
  rows: T[],
): Promise<T[]> {
  if (!rows || rows.length === 0) return rows;
  try {
    const ids = Array.from(new Set(rows.map((r) => r.user_id)));
    const { data } = await supabase
      .from('profiles')
      .select('id')
      .in('id', ids)
      .eq('notifications_paused', true);
    const paused = new Set<string>(((data ?? []) as { id: string }[]).map((r) => r.id));
    if (paused.size === 0) return rows;
    return rows.filter((r) => !paused.has(r.user_id));
  } catch (_) {
    return rows;
  }
}
