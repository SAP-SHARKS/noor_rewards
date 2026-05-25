-- =============================================================================
-- 20260525_010_aggregate_orphan_sponsors
--
-- Bugfix: get_orphan_recent_sponsors returned one row per donation, so the
-- "Sponsored by" list double-counted users who contributed multiple times.
-- Now returns one row per distinct sponsor with their lifetime total + most
-- recent contribution time (matches the community-project donor pattern).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_orphan_recent_sponsors(
  p_orphan_id UUID,
  p_limit     INTEGER DEFAULT 5
)
RETURNS TABLE (
  user_id        UUID,
  display_name   TEXT,
  avatar_url     TEXT,
  points_donated INTEGER,   -- TOTAL contributed by this user
  donated_at     TIMESTAMPTZ -- MOST RECENT contribution time
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    ud.user_id,
    COALESCE(p.display_name, 'A generous soul') AS display_name,
    p.avatar_url,
    SUM(ud.points_donated)::INTEGER AS points_donated,
    MAX(ud.created_at)              AS donated_at
  FROM user_donations ud
  LEFT JOIN profiles p ON p.id = ud.user_id
  WHERE ud.orphan_id = p_orphan_id
  GROUP BY ud.user_id, p.display_name, p.avatar_url
  ORDER BY MAX(ud.created_at) DESC
  LIMIT GREATEST(p_limit, 1);
$$;

REVOKE ALL ON FUNCTION public.get_orphan_recent_sponsors(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_orphan_recent_sponsors(uuid, integer) TO authenticated;
