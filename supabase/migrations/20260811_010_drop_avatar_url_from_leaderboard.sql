-- =============================================================================
-- 20260811_010_drop_avatar_url_from_leaderboard
--
-- Removes `avatar_url` from all four leaderboard views so authenticated
-- clients (including anyone with the anon key) can no longer read every
-- user's profile-photo URL via PostgREST. The Flutter app already stopped
-- rendering avatars in favour of initials — but until this migration
-- ships, the data was still queryable directly against the views.
--
-- avatar_color stays. It's a small integer used by the client to tint
-- the initials chip, not linkable to any external resource.
--
-- IMPORTANT: PostgreSQL disallows dropping columns from a view via
-- CREATE OR REPLACE VIEW. Must DROP then CREATE. Grants and reloptions
-- (security_invoker) are wiped by DROP, so they're re-applied after
-- each CREATE.
-- =============================================================================

-- ── v2 (all-time) ────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.leaderboard_global_v2;
CREATE VIEW public.leaderboard_global_v2 AS
  SELECT
    p.id,
    p.display_name,
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

ALTER VIEW public.leaderboard_global_v2 SET (security_invoker = false);
GRANT SELECT ON public.leaderboard_global_v2 TO authenticated, anon;

-- ── daily ────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.leaderboard_global_daily;
CREATE VIEW public.leaderboard_global_daily AS
  SELECT
    p.id, p.display_name, p.avatar_color, p.country,
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

ALTER VIEW public.leaderboard_global_daily SET (security_invoker = false);
GRANT SELECT ON public.leaderboard_global_daily TO authenticated, anon;

-- ── weekly ───────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.leaderboard_global_weekly;
CREATE VIEW public.leaderboard_global_weekly AS
  SELECT
    p.id, p.display_name, p.avatar_color, p.country,
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

ALTER VIEW public.leaderboard_global_weekly SET (security_invoker = false);
GRANT SELECT ON public.leaderboard_global_weekly TO authenticated, anon;

-- ── monthly ──────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.leaderboard_global_monthly;
CREATE VIEW public.leaderboard_global_monthly AS
  SELECT
    p.id, p.display_name, p.avatar_color, p.country,
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

ALTER VIEW public.leaderboard_global_monthly SET (security_invoker = false);
GRANT SELECT ON public.leaderboard_global_monthly TO authenticated, anon;

-- ── Verify (should return zero rows — avatar_url gone from all views) ────
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name LIKE 'leaderboard_global%'
  AND column_name = 'avatar_url';
