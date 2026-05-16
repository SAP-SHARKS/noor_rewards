-- ============================================================================
-- Project Donor Counts Migration
-- Adds an RPC that returns the number of distinct donors per community
-- project, used to surface "X contributors" on the dashboard donation cards.
--
-- Run this in Supabase SQL Editor.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_project_donor_counts()
RETURNS TABLE (
  project_id  uuid,
  donor_count int
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- The table is aliased (ud) so `ud.project_id` is never confused with
  -- the RETURNS TABLE output column also named `project_id`.
  SELECT
    ud.project_id,
    COUNT(DISTINCT ud.user_id)::int
  FROM user_donations ud
  GROUP BY ud.project_id;
$$;

GRANT EXECUTE ON FUNCTION get_project_donor_counts() TO authenticated, anon;
