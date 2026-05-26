-- =============================================================================
-- 20260525_012_aggregate_project_seed_totals
--
-- Bugfix: community project cards showed current_points = 0 even after
-- donations. The Flutter loader was overriding `current_points` by
-- summing user_donations directly on the client, but user_donations RLS
-- restricts non-owner SELECTs, so the sum reflected only the caller's
-- own contribution. Same root cause + same fix pattern as the orphan
-- stats RPC (20260525_011): wrap the aggregation in a SECURITY DEFINER
-- function so it returns community totals.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_project_seed_totals()
RETURNS TABLE (
  project_id     UUID,
  current_seeds  BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    ud.project_id,
    COALESCE(SUM(ud.points_donated), 0)::BIGINT AS current_seeds
  FROM user_donations ud
  WHERE ud.project_id IS NOT NULL
  GROUP BY ud.project_id;
$$;

REVOKE ALL ON FUNCTION public.get_project_seed_totals() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_project_seed_totals() TO authenticated;


-- Per-user RPC for "my contribution per project" — same RLS workaround
-- so the impact tab's per-card "my donation" badge is accurate.
CREATE OR REPLACE FUNCTION public.get_my_project_donations(p_user_id UUID)
RETURNS TABLE (
  project_id  UUID,
  my_seeds    BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    ud.project_id,
    COALESCE(SUM(ud.points_donated), 0)::BIGINT AS my_seeds
  FROM user_donations ud
  WHERE ud.project_id IS NOT NULL
    AND ud.user_id = p_user_id
  GROUP BY ud.project_id;
$$;

REVOKE ALL ON FUNCTION public.get_my_project_donations(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_project_donations(uuid) TO authenticated;


-- Verify
SELECT routine_name, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_project_seed_totals', 'get_my_project_donations')
ORDER BY routine_name;
