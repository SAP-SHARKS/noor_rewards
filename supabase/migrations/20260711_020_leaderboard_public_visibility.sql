-- =============================================================================
-- 20260711_020_leaderboard_public_visibility
--
-- Restores public visibility of the four leaderboard views so every
-- authenticated user (including brand-new accounts) sees the global top
-- ranks instead of the "Be the first on the board" empty state.
--
-- Root cause: migrations 20260624_060, 20260625_010, and 20260625_020 all
-- set `security_invoker = true` on the leaderboard views. Combined with
-- the row-level SELECT rules on `profiles` (which restrict a caller to
-- their own row), that made every leaderboard view return at most one
-- row — the caller's own — and zero rows for users whose `setup_done`
-- flag was still false. `dashboard_screen.dart::_LeaderboardView` then
-- renders `_buildEmptyState()` since `_leaders.isEmpty`.
--
-- Reverting to `security_invoker = false` (the default for CREATE VIEW)
-- means the view runs with its OWNER's privileges (postgres), so RLS on
-- `profiles` is bypassed for exactly this projection. The columns
-- exposed by the leaderboard views are all safe for public display:
--   display_name, avatar_url, avatar_color, country, city, total_xp,
--   noor_points, level, day_streak, best_login_streak, best_dhikr_streak,
--   best_quran_streak, ayahs_read, dhikr_count, quran_time_sec, and
--   the period_points column added for the daily/weekly/monthly variants.
--
-- Nothing sensitive (email, phone, private stats, streak_history rows,
-- etc.) is projected, so this restores the intended leaderboard behaviour
-- without re-opening the security holes migration 20260525_020 closed.
--
-- Analytics views (`analytics_country_summary`, `analytics_device_summary`)
-- are NOT touched by this migration — they remain security_invoker = true
-- as intended, because their columns ARE sensitive.
--
-- Idempotent — re-running is a no-op.
-- =============================================================================

-- NOTE: no BEGIN/COMMIT block. An earlier revision of this file wrapped
-- the ALTERs in a transaction alongside a verification query that used
-- the non-existent `pg_options_to_table()` function. The verification
-- error rolled the whole transaction back, so the ALTERs never landed.
-- Running the four statements bare avoids that failure mode entirely.
ALTER VIEW public.leaderboard_global_v2      SET (security_invoker = false);
ALTER VIEW public.leaderboard_global_daily   SET (security_invoker = false);
ALTER VIEW public.leaderboard_global_weekly  SET (security_invoker = false);
ALTER VIEW public.leaderboard_global_monthly SET (security_invoker = false);

-- Grants stay as they were (authenticated, anon) — no changes needed.

-- ── Verify (safe query — inspect reloptions directly) ────────────────────────
-- Expected: each row's reloptions contains `security_invoker=false`.
SELECT relname, reloptions
FROM pg_class
WHERE relname LIKE 'leaderboard_global%'
ORDER BY relname;
