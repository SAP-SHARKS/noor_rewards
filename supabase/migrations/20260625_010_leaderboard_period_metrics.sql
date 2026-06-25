-- ─────────────────────────────────────────────────────────────────────────────
-- 20260625_010_leaderboard_period_metrics.sql
--
-- Extends the daily / weekly / monthly leaderboard views with per-period
-- ayahs read and dhikr counts (so the UI can show Quranly-style mini stats
-- next to each entry). Uses CREATE OR REPLACE so it's safe to re-run.
--
-- v2 (all-time) already exposes `ayahs_read` and `dhikr_count` from profiles
-- so the Flutter side falls back to those when period_* is absent.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW public.leaderboard_global_daily AS
  SELECT
    p.id, p.display_name, p.avatar_url, p.avatar_color, p.country,
    p.level, p.day_streak,
    COALESCE(a.period_points, 0) AS period_points,
    COALESCE(a.period_ayahs, 0)  AS period_ayahs,
    COALESCE(a.period_dhikr, 0)  AS period_dhikr
  FROM profiles p
  LEFT JOIN (
    SELECT
      user_id,
      SUM(points_earned)::int                                      AS period_points,
      COUNT(*) FILTER (WHERE activity_type = 'quran')::int          AS period_ayahs,
      COUNT(*) FILTER (WHERE activity_type = 'dhikr')::int          AS period_dhikr
    FROM user_activities
    WHERE created_at >= date_trunc('day', now() AT TIME ZONE 'UTC')
    GROUP BY user_id
  ) a ON a.user_id = p.id
  WHERE p.merged_into_id IS NULL
    AND COALESCE(p.setup_done, false) = true
    AND COALESCE(a.period_points, 0) > 0
  ORDER BY period_points DESC NULLS LAST, p.created_at ASC;

ALTER VIEW public.leaderboard_global_daily SET (security_invoker = true);
GRANT SELECT ON public.leaderboard_global_daily TO authenticated, anon;


CREATE OR REPLACE VIEW public.leaderboard_global_weekly AS
  SELECT
    p.id, p.display_name, p.avatar_url, p.avatar_color, p.country,
    p.level, p.day_streak,
    COALESCE(a.period_points, 0) AS period_points,
    COALESCE(a.period_ayahs, 0)  AS period_ayahs,
    COALESCE(a.period_dhikr, 0)  AS period_dhikr
  FROM profiles p
  LEFT JOIN (
    SELECT
      user_id,
      SUM(points_earned)::int                                      AS period_points,
      COUNT(*) FILTER (WHERE activity_type = 'quran')::int          AS period_ayahs,
      COUNT(*) FILTER (WHERE activity_type = 'dhikr')::int          AS period_dhikr
    FROM user_activities
    WHERE created_at >= now() - interval '7 days'
    GROUP BY user_id
  ) a ON a.user_id = p.id
  WHERE p.merged_into_id IS NULL
    AND COALESCE(p.setup_done, false) = true
    AND COALESCE(a.period_points, 0) > 0
  ORDER BY period_points DESC NULLS LAST, p.created_at ASC;

ALTER VIEW public.leaderboard_global_weekly SET (security_invoker = true);
GRANT SELECT ON public.leaderboard_global_weekly TO authenticated, anon;


CREATE OR REPLACE VIEW public.leaderboard_global_monthly AS
  SELECT
    p.id, p.display_name, p.avatar_url, p.avatar_color, p.country,
    p.level, p.day_streak,
    COALESCE(a.period_points, 0) AS period_points,
    COALESCE(a.period_ayahs, 0)  AS period_ayahs,
    COALESCE(a.period_dhikr, 0)  AS period_dhikr
  FROM profiles p
  LEFT JOIN (
    SELECT
      user_id,
      SUM(points_earned)::int                                      AS period_points,
      COUNT(*) FILTER (WHERE activity_type = 'quran')::int          AS period_ayahs,
      COUNT(*) FILTER (WHERE activity_type = 'dhikr')::int          AS period_dhikr
    FROM user_activities
    WHERE created_at >= now() - interval '30 days'
    GROUP BY user_id
  ) a ON a.user_id = p.id
  WHERE p.merged_into_id IS NULL
    AND COALESCE(p.setup_done, false) = true
    AND COALESCE(a.period_points, 0) > 0
  ORDER BY period_points DESC NULLS LAST, p.created_at ASC;

ALTER VIEW public.leaderboard_global_monthly SET (security_invoker = true);
GRANT SELECT ON public.leaderboard_global_monthly TO authenticated, anon;
