-- =============================================================================
-- 20260525_011_aggregate_orphan_stats
--
-- Bugfix: orphan card progress (current_seeds / sponsor_count) appeared as 0
-- for all users even when sponsorships existed. user_donations RLS limits
-- non-owner SELECTs, so direct queries — and the older non-SECURITY-DEFINER
-- versions of get_orphan_stats / get_orphan_stats_bulk — only saw the
-- caller's own donations. Re-creating both with SECURITY DEFINER so they
-- return community totals (mirrors get_project_donor_counts pattern).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_orphan_stats(p_orphan_id UUID)
RETURNS TABLE (
  current_seeds  BIGINT,
  sponsor_count  BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    COALESCE(SUM(ud.points_donated), 0)::BIGINT AS current_seeds,
    COUNT(DISTINCT ud.user_id)::BIGINT          AS sponsor_count
  FROM user_donations ud
  WHERE ud.orphan_id = p_orphan_id;
$$;

REVOKE ALL ON FUNCTION public.get_orphan_stats(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_orphan_stats(uuid) TO authenticated;


CREATE OR REPLACE FUNCTION public.get_orphan_stats_bulk(p_orphan_ids UUID[])
RETURNS TABLE (
  orphan_id      UUID,
  current_seeds  BIGINT,
  sponsor_count  BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    ud.orphan_id,
    COALESCE(SUM(ud.points_donated), 0)::BIGINT AS current_seeds,
    COUNT(DISTINCT ud.user_id)::BIGINT          AS sponsor_count
  FROM user_donations ud
  WHERE ud.orphan_id = ANY(p_orphan_ids)
  GROUP BY ud.orphan_id;
$$;

REVOKE ALL ON FUNCTION public.get_orphan_stats_bulk(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_orphan_stats_bulk(uuid[]) TO authenticated;


-- Verify
SELECT routine_name, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_orphan_stats', 'get_orphan_stats_bulk')
ORDER BY routine_name;
