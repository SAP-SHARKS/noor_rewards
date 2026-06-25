-- ─────────────────────────────────────────────────────────────────────────────
-- 20260624_060_leaderboard_time_windows.sql
--
-- Adds Daily / Weekly / Monthly leaderboard views (Quranly-style tabs).
-- These are ADDITIVE — `leaderboard_global_v2` is untouched, so the existing
-- "all-time" reader keeps working.
--
-- Metric: SUM(user_activities.points_earned) inside the window. This is the
-- "Seeds earned in the period" — same magnitude unit as our XP/Seeds.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Daily (since 00:00 UTC today) ────────────────────────────────────────────
CREATE OR REPLACE VIEW public.leaderboard_global_daily AS
  SELECT
    p.id,
    p.display_name,
    p.avatar_url,
    p.avatar_color,
    p.country,
    p.level,
    p.day_streak,
    COALESCE(a.period_points, 0) AS period_points
  FROM profiles p
  LEFT JOIN (
    SELECT user_id, SUM(points_earned)::int AS period_points
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


-- ── Weekly (last 7 days, rolling) ────────────────────────────────────────────
CREATE OR REPLACE VIEW public.leaderboard_global_weekly AS
  SELECT
    p.id,
    p.display_name,
    p.avatar_url,
    p.avatar_color,
    p.country,
    p.level,
    p.day_streak,
    COALESCE(a.period_points, 0) AS period_points
  FROM profiles p
  LEFT JOIN (
    SELECT user_id, SUM(points_earned)::int AS period_points
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


-- ── Monthly (last 30 days, rolling) ──────────────────────────────────────────
CREATE OR REPLACE VIEW public.leaderboard_global_monthly AS
  SELECT
    p.id,
    p.display_name,
    p.avatar_url,
    p.avatar_color,
    p.country,
    p.level,
    p.day_streak,
    COALESCE(a.period_points, 0) AS period_points
  FROM profiles p
  LEFT JOIN (
    SELECT user_id, SUM(points_earned)::int AS period_points
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


-- ── Index hint: user_activities should already have (user_id, created_at)
-- for the dedup query in xp_service. If not, add it now so these views scan
-- a window of rows rather than the full table.
CREATE INDEX IF NOT EXISTS user_activities_user_created_idx
  ON public.user_activities (user_id, created_at DESC);
