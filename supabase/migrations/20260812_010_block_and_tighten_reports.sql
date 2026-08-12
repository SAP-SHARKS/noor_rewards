-- =============================================================================
-- 20260812_010_block_and_tighten_reports
--
-- Three closely-related UGC-safety adjustments:
--
-- 1. blocked_users table + RLS. Adds Apple 1.2's "block" leg. Blocking
--    hides a reported user from the caller's leaderboard rows.
--    Leaderboard views stay unchanged; the Flutter side applies the
--    filter after fetch (view rewrite would force security_invoker=true
--    and drop the whole board for new users again — same trap that hit
--    us in 20260711_020). Filtering client-side is fine because the
--    block is per-caller UX, not a global visibility change.
--
-- 2. user_reports tightening:
--    - Drop user-facing SELECT (users only INSERT; they don't need to
--      see their own submitted reports). Eliminates the reporter_user_id
--      exposure surface the senior flagged.
--    - Unique constraint on (reporter, reported, per-UTC-day) blocks
--      spam / accidental double-reports.
--
-- 3. Expand the display-name blocklist:
--    - Non-English profanity for the 7 other locales Sabiq ships.
--    - Sacred names & Islamic titles — the realistic abuse vector on
--      an Islamic leaderboard is impersonating Allah, the Prophet ﷺ,
--      or well-known scholars, not generic profanity.
--    Client mirror in `lib/utils/display_name_check.dart` gets the same
--    list in the follow-up subagent pass.
-- =============================================================================

BEGIN;

-- ── 1. blocked_users ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.blocked_users (
  blocker_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_user_id, blocked_user_id),
  CONSTRAINT no_self_block CHECK (blocker_user_id != blocked_user_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker
  ON public.blocked_users(blocker_user_id);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- User manages only their own block list
DROP POLICY IF EXISTS "blocked_users_own_all" ON public.blocked_users;
CREATE POLICY "blocked_users_own_all" ON public.blocked_users
  FOR ALL TO authenticated
  USING (auth.uid() = blocker_user_id)
  WITH CHECK (auth.uid() = blocker_user_id);

-- Admins can inspect for triage
DROP POLICY IF EXISTS "blocked_users_admin_read" ON public.blocked_users;
CREATE POLICY "blocked_users_admin_read" ON public.blocked_users
  FOR SELECT TO authenticated
  USING (public.is_admin());

GRANT SELECT, INSERT, DELETE ON public.blocked_users TO authenticated;

-- ── 2. Tighten user_reports ──────────────────────────────────────────────
-- Drop the reporter's own-SELECT policy — users don't need to see their
-- reports back, and dropping it means the row's contents are never
-- readable to a regular authenticated user, only to admins.
DROP POLICY IF EXISTS "user_reports_select_own" ON public.user_reports;

-- Rate-limit: one report per (reporter, reported) per UTC day.
-- Duplicate INSERTs raise unique_violation which the client translates
-- into "you've already reported this user today".
CREATE UNIQUE INDEX IF NOT EXISTS user_reports_daily_unique
  ON public.user_reports (
    reporter_user_id,
    reported_user_id,
    ((created_at AT TIME ZONE 'UTC')::date)
  );

-- Revoke the now-unnecessary SELECT grant to authenticated (admin still
-- reads via the admin policy).
REVOKE SELECT ON public.user_reports FROM authenticated;

-- ── 3. Expand display-name blocklist ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public._check_display_name()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  -- Generic English profanity (from 20260811_020) + additions for the
  -- 7 other shipped locales + Islamic sacred names/titles. Kept as one
  -- flat list because the normalisation strips non-alphanumerics so
  -- most transliterations catch too (e.g. "Allah" catches "A.l.l.a.h").
  banned TEXT[] := ARRAY[
    -- English
    'fuck','shit','bitch','cunt','dick','pussy','whore','slut','asshole',
    'nigger','nigga','faggot','fag','retard','kike','chink','spic',
    'porn','sex','xxx','nsfw','hitler','nazi','isis','daesh',
    -- Arabic transliterations (kafir/apostate slurs, sexual)
    'kafir','murtad','zani','zaniya','sharmuta','ayr','kus','zeb',
    -- Urdu / Hindi
    'chutiya','madarchod','behenchod','randi','gandu','harami',
    -- Turkish
    'orospu','piç','amina','sikeyim','sikerim',
    -- Indonesian / Malay
    'anjing','babi','memek','kontol','bangsat','pukimak','sundal',
    -- French
    'putain','salope','encule','connard','pute','merde',
    -- Russian (transliterated)
    'suka','blyad','pizda','huy','yobana',
    -- Sacred names & titles — impersonation is the realistic abuse
    -- vector on an Islamic leaderboard. Any display name that reduces
    -- (after normalisation) to one of these is rejected. Users with
    -- legitimate similar names can add a distinguisher.
    'allah','muhammad','rasulullah','prophet','nabi','muhammadsaw',
    'jesus','isa','moses','musa','abraham','ibrahim',
    'quran','koran','islam',
    'admin','sabiq','sabiqteam','support','moderator','staff'
  ];
  lowered TEXT;
  word TEXT;
BEGIN
  IF NEW.display_name IS NULL OR trim(NEW.display_name) = '' THEN
    RETURN NEW;
  END IF;

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

COMMIT;

-- ── Verify ────────────────────────────────────────────────────────────────
-- blocked_users exists with RLS + 2 policies.
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'blocked_users';
SELECT policyname, cmd, roles FROM pg_policies
WHERE tablename = 'blocked_users' ORDER BY policyname;

-- user_reports now has only INSERT (users) + SELECT/UPDATE (admins).
SELECT policyname, cmd, roles FROM pg_policies
WHERE tablename = 'user_reports' ORDER BY policyname;

-- Daily unique index present.
SELECT indexname, indexdef FROM pg_indexes
WHERE tablename = 'user_reports' AND indexname = 'user_reports_daily_unique';

-- Optional: verify sacred-name trigger blocks a test name (ROLLBACK).
-- BEGIN;
--   INSERT INTO public.profiles (id, display_name) VALUES
--     (gen_random_uuid(), 'Allah Almighty')
--   ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
-- ROLLBACK;
