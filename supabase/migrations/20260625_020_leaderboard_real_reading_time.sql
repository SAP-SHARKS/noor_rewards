-- ─────────────────────────────────────────────────────────────────────────────
-- 20260625_020_leaderboard_real_reading_time.sql
--
-- Surface real Quran reading time on the leaderboard (replaces the
-- ayahs × 30s estimate in the Flutter UI). Source of truth is
-- `user_analytics.quran_time_sec`, which is accumulated by the Mushaf
-- timer via `record_activity_stats`.
--
-- Additive — same columns as before, plus `quran_time_sec`.
-- Safe to re-run (CREATE OR REPLACE).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW public.leaderboard_global_v2 AS
  SELECT
    p.id,
    p.display_name,
    p.avatar_url,
    p.avatar_color,
    p.country,
    p.city,
    p.total_xp,
    p.noor_points,
    p.level,
    p.day_streak,
    p.best_login_streak,
    p.best_dhikr_streak,
    p.best_quran_streak,
    p.ayahs_read,
    p.dhikr_count,
    COALESCE(a.quran_time_sec, 0)::int AS quran_time_sec
  FROM profiles p
  LEFT JOIN user_analytics a ON a.user_id = p.id
  WHERE p.merged_into_id IS NULL
    AND COALESCE(p.setup_done, false) = true
  ORDER BY p.total_xp DESC NULLS LAST, p.created_at ASC;

ALTER VIEW public.leaderboard_global_v2 SET (security_invoker = true);
GRANT SELECT ON public.leaderboard_global_v2 TO authenticated, anon;
