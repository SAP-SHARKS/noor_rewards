-- ============================================================================
-- Project Recent Donors Migration
-- Adds an RPC that returns the most recent donations for a project,
-- joined with the donor's profile (display name + avatar). Used to render
-- the LaunchGood-style donor list on the Project Detail page.
--
-- Run this in Supabase SQL Editor.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_project_recent_donors(
  p_project_id uuid,
  p_limit      int DEFAULT 20
)
RETURNS TABLE (
  user_id      uuid,
  display_name text,
  avatar_url   text,
  amount       int,
  donated_at   timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ud.user_id,
    COALESCE(p.display_name, 'A generous soul') AS display_name,
    p.avatar_url,
    ud.points_donated::int AS amount,
    ud.created_at          AS donated_at
  FROM user_donations ud
  LEFT JOIN profiles p ON p.id = ud.user_id
  WHERE ud.project_id = p_project_id
  ORDER BY ud.created_at DESC
  LIMIT GREATEST(p_limit, 1);
$$;

-- Allow the app's signed-in users (and anon, if projects are browsable
-- while logged out) to call the RPC.
GRANT EXECUTE ON FUNCTION get_project_recent_donors(uuid, int) TO authenticated, anon;
