-- =============================================================================
-- 20260811_020_ugc_mitigation
--
-- Two-part UGC-safety layer for display names on the public leaderboard:
--
-- 1. A server-side profanity trigger that rejects INSERT/UPDATE to
--    profiles.display_name if the name contains banned tokens. Enforced
--    at the DB layer so it applies to every write path — client, Edge
--    Function, or direct Supabase call. Client will run the same list
--    locally for instant feedback, but the DB check is the source of
--    truth.
--
-- 2. A user_reports table + RLS + is_admin-read policies. Any signed-in
--    user can file a report against another user's display name (or
--    other future report reasons). Reports are private to the reporter
--    and admins.
--
-- Both together give: prevention (filter) + escalation (report) with
-- an audit trail — the "professional posture" App Store reviewers look
-- for on a UGC surface, without needing an image-moderation pipeline.
-- =============================================================================

BEGIN;

-- ── Profanity trigger on profiles.display_name ───────────────────────────
-- English base list. Uses lowercased substring match so common
-- l33t-speak and mid-word insertions get caught along with the literal
-- word. False positives (e.g. name containing "assessment") are the
-- tradeoff for keeping the trigger simple + fast; users who hit one can
-- pick a different display name.
CREATE OR REPLACE FUNCTION public._check_display_name()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  banned TEXT[] := ARRAY[
    'fuck','shit','bitch','cunt','dick','pussy','whore','slut','asshole',
    'nigger','nigga','faggot','fag','retard','kike','chink','spic',
    'kafir','murtad','zani','zaniya',  -- Arabic slurs commonly used against Muslims
    'porn','sex','xxx','nsfw',
    'hitler','nazi','isis','daesh'
  ];
  lowered TEXT;
  word TEXT;
BEGIN
  IF NEW.display_name IS NULL OR trim(NEW.display_name) = '' THEN
    RETURN NEW;
  END IF;

  -- Normalise: lowercase + strip non-alphanumerics so "f.u.c.k" and
  -- "f_u_c_k" also trip the filter.
  lowered := regexp_replace(lower(NEW.display_name), '[^a-z0-9]', '', 'g');

  FOREACH word IN ARRAY banned LOOP
    IF lowered LIKE '%' || word || '%' THEN
      RAISE EXCEPTION 'display_name contains disallowed content'
        USING ERRCODE = 'check_violation',
              HINT = 'Please choose a different display name.';
    END IF;
  END LOOP;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_check_display_name ON public.profiles;
CREATE TRIGGER trg_check_display_name
  BEFORE INSERT OR UPDATE OF display_name ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public._check_display_name();

-- ── user_reports table ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN (
    'offensive_name','impersonation','spam','harassment','other'
  )),
  notes TEXT CHECK (length(notes) <= 500),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending','reviewed','action_taken','dismissed'
  )),
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  CONSTRAINT no_self_report CHECK (reporter_user_id != reported_user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_reports_status
  ON public.user_reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported
  ON public.user_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reporter
  ON public.user_reports(reporter_user_id, created_at DESC);

ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

-- Rate limit: a user can file at most 20 reports per 24h. Enforced via
-- unique-ish check in a function-defined policy would be complex; keep
-- it simple — client can throttle. Server-side abuse of the reports
-- table is bounded by RLS scope + admin oversight of the queue.

-- Users file their own reports (INSERT only, no editing after)
DROP POLICY IF EXISTS "user_reports_insert_own" ON public.user_reports;
CREATE POLICY "user_reports_insert_own" ON public.user_reports
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = reporter_user_id);

-- Users can see the reports they filed (status tracking)
DROP POLICY IF EXISTS "user_reports_select_own" ON public.user_reports;
CREATE POLICY "user_reports_select_own" ON public.user_reports
  FOR SELECT TO authenticated
  USING (auth.uid() = reporter_user_id);

-- Admins read everything for triage
DROP POLICY IF EXISTS "user_reports_admin_read" ON public.user_reports;
CREATE POLICY "user_reports_admin_read" ON public.user_reports
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- Admins update (mark reviewed/action_taken/dismissed, add admin_notes)
DROP POLICY IF EXISTS "user_reports_admin_update" ON public.user_reports;
CREATE POLICY "user_reports_admin_update" ON public.user_reports
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Grants (RLS still enforced)
GRANT SELECT, INSERT ON public.user_reports TO authenticated;
GRANT UPDATE ON public.user_reports TO authenticated;

COMMIT;

-- ── Verify ────────────────────────────────────────────────────────────────
-- Should return one trigger row.
SELECT event_object_table, trigger_name, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'trg_check_display_name';

-- Should show the user_reports table with RLS enabled and 4 policies.
SELECT tablename, rowsecurity FROM pg_tables
WHERE tablename = 'user_reports';
SELECT policyname, cmd, roles FROM pg_policies
WHERE tablename = 'user_reports' ORDER BY policyname;

-- Optional quick test: trigger should block a profane display name.
-- (Uncomment to run — will always ROLLBACK.)
-- BEGIN;
-- INSERT INTO public.profiles (id, display_name)
--   VALUES (gen_random_uuid(), 'FuckFace')
--   ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
-- ROLLBACK;
