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
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    project_id,
    COUNT(DISTINCT user_id)::int AS donor_count
  FROM user_donations
  GROUP BY project_id;
$$;
