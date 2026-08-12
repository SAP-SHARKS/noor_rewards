-- =============================================================================
-- 20260808_010_rls_tighten
--
-- Tightens four RLS + grant issues found in the security audit:
--
-- 1. azkar_animations, azkar_item_animations, azkar_item_categories
--    Previously allowed ANY authenticated user to INSERT/UPDATE/DELETE
--    (USING true, WITH CHECK true). Rewritten as admin-only, matching
--    the pattern used by community_projects, sponsored_orphans, and
--    onboarding_images.
--
-- 2. profiles — REVOKE ALL from anon.
--    Anon (unauthenticated) queries were granted SELECT + REFERENCES on
--    every profile column including email, total_xp, level, referred_by.
--    RLS on profiles scopes rows to `auth.uid() = id` so anon queries
--    already return 0 rows in practice — but the grants are a second
--    layer of defense that was wide open. Anon should never touch
--    profiles directly; server-side aggregations (e.g. leaderboard
--    views owned by postgres) bypass RLS and the anon grant separately.
--
-- 3. notification_log + user_analytics
--    Two policies used a hardcoded email whitelist:
--      (auth.jwt() ->> 'email') = ANY (ARRAY['pak.zakn@gmail.com', ...])
--    Rewritten to use the existing public.is_admin() function so admin
--    identity has a single source of truth (app_roles) and adding /
--    removing admins doesn't require another migration.
--
-- 4. app_config
--    Two SELECT policies existed:
--      "anyone reads config"     USING (auth.role() = 'authenticated')
--      "config_select_auth"      USING (true)   ← allowed anon
--    Dropped the broader (anon-permitting) one; the authenticated-only
--    policy remains.
--
-- Idempotent — DROP POLICY IF EXISTS guards each policy replacement so
-- the migration is safe to re-run.
-- =============================================================================

BEGIN;

-- ── 1. Lock azkar admin tables to admins only ─────────────────────────────
-- The old policies allowed any signed-in user to modify these — meaning a
-- malicious account could delete azkar-illustration mappings and break the
-- visual for everyone. Replace with admin-only ALL policies.
DROP POLICY IF EXISTS "azkar_animations_write_auth" ON public.azkar_animations;
CREATE POLICY "azkar_animations_admin_write" ON public.azkar_animations
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "azkar_item_animations_write_auth" ON public.azkar_item_animations;
CREATE POLICY "azkar_item_animations_admin_write" ON public.azkar_item_animations
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "azkar_item_categories_write_auth" ON public.azkar_item_categories;
CREATE POLICY "azkar_item_categories_admin_write" ON public.azkar_item_categories
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ── 2. Strip anon grants from profiles ────────────────────────────────────
-- Removes SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
-- from the anon role. Authenticated user grants (SELECT on all columns,
-- UPDATE on the narrow set from 20260525_020) are unaffected.
REVOKE ALL ON public.profiles FROM anon;

-- ── 3. Replace hardcoded email whitelists with is_admin() ────────────────
DROP POLICY IF EXISTS "admins read all notification_log" ON public.notification_log;
CREATE POLICY "notif_log_admin_read" ON public.notification_log
  FOR SELECT TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "admins read all user_analytics" ON public.user_analytics;
CREATE POLICY "user_analytics_admin_read" ON public.user_analytics
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- ── 4. Drop the duplicate anon-permitting app_config SELECT policy ───────
-- Keeps "anyone reads config" which restricts to authenticated.
DROP POLICY IF EXISTS "config_select_auth" ON public.app_config;

COMMIT;

-- ── Verify ────────────────────────────────────────────────────────────────
-- Expected: three azkar tables now show admin-only write policies.
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('azkar_animations','azkar_item_animations','azkar_item_categories')
ORDER BY tablename, policyname;

-- Expected: no rows returned (anon has zero direct grants on profiles).
SELECT grantee, privilege_type, column_name
FROM information_schema.column_privileges
WHERE table_schema = 'public' AND table_name = 'profiles' AND grantee = 'anon';

-- Expected: notification_log and user_analytics admin policies use is_admin().
SELECT tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname IN ('notif_log_admin_read','user_analytics_admin_read');

-- Expected: only "anyone reads config" (authenticated) remains as SELECT.
SELECT policyname, cmd, roles, qual
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'app_config' AND cmd = 'SELECT';
