-- =============================================================================
-- 20260527_010_supabase_linter_fixes
--
-- Fixes Supabase Database Linter findings (run 25 May 2026).
--
-- Fixed here:
--   • ERROR  rls_disabled_in_public      → notification_log
--   • ERROR  security_definer_view        → leaderboard, leaderboard_global, leaderboard_global_v2
--   • WARN   rls_policy_always_true       → drop stale "*_auth" policies on
--                                           onboarding_images + azkar_categories
--                                           (Phase-2 migration created new admin-gated
--                                           policies but didn't drop these legacy ones,
--                                           because their names didn't match the DROP)
--   • WARN   public_bucket_allows_listing → 4 storage buckets: drop the broad
--                                           SELECT policy. Object URLs still work
--                                           because the buckets remain `public = true`.
--   • WARN   function_search_path_mutable → 15 functions get an explicit search_path
--   • WARN   anon_security_definer_executable → REVOKE EXECUTE FROM anon on
--                                                user-scoped RPCs that never need
--                                                anon access
--
-- INTENTIONALLY SKIPPED (after review):
--   • WARN auth_allow_anonymous_sign_ins  → false positives; policies have
--                                            auth.uid() guards that return NULL
--                                            for anon → no rows returned
--   • WARN authenticated_security_definer_function_executable → by design;
--                                            functions have internal auth.uid() checks
--   • WARN auth_leaked_password_protection → manual dashboard toggle
--                                            (Authentication → Password Auth →
--                                             "Enable leaked password protection")
-- =============================================================================

-- ── ERROR 1: notification_log RLS ──────────────────────────────────────────
ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

-- Service role manages it from edge functions. No client access.
DROP POLICY IF EXISTS "notification_log_service_role_all" ON public.notification_log;
CREATE POLICY "notification_log_service_role_all" ON public.notification_log
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── ERROR 2: leaderboard views use security_definer ────────────────────────
-- The default in PG15+ is security_invoker = false (= definer behaviour),
-- which means the view evaluates as its creator regardless of caller. For
-- leaderboard tables this is fine in practice but the linter flags it as
-- "may bypass RLS". Flipping to invoker makes the views respect each
-- caller's permissions on the underlying tables.
ALTER VIEW public.leaderboard          SET (security_invoker = true);
ALTER VIEW public.leaderboard_global   SET (security_invoker = true);
ALTER VIEW public.leaderboard_global_v2 SET (security_invoker = true);

-- ── Stale "always true" policies that survived Phase 2 ────────────────────
-- These policies still grant any authenticated user the ability to write
-- because their names didn't match the DROP IF EXISTS in my earlier
-- migration. The admin-gated replacements already exist; we just need to
-- delete the old ones.
DROP POLICY IF EXISTS "onb_imgs_insert_auth" ON public.onboarding_images;
DROP POLICY IF EXISTS "onb_imgs_update_auth" ON public.onboarding_images;
DROP POLICY IF EXISTS "onb_imgs_delete_auth" ON public.onboarding_images;

-- Same pattern for storage.objects (the onb_imgs storage policies)
DROP POLICY IF EXISTS "onb_imgs_auth_update" ON storage.objects;
DROP POLICY IF EXISTS "onb_imgs_auth_delete" ON storage.objects;

-- azkar_categories: this UPDATE policy lets any authenticated user change
-- category visibility. Replace with admin-only.
DROP POLICY IF EXISTS "azkar_cat_update_auth" ON public.azkar_categories;
CREATE POLICY "azkar_cat_admin_update" ON public.azkar_categories
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ── Bucket listing — drop broad SELECT policies ───────────────────────────
-- Public buckets serve object URLs without authentication for direct access.
-- The SELECT-true policies additionally allow `storage.from(bucket).list()`
-- which enumerates every file in the bucket. Dropping them keeps your app
-- working (it uses getPublicUrl, not list) while removing the enumeration.
DROP POLICY IF EXISTS "Avatars are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "onb_imgs_public_read"          ON storage.objects;
DROP POLICY IF EXISTS "orphan_photos_public_read"     ON storage.objects;
DROP POLICY IF EXISTS "project_media_public_read"     ON storage.objects;

-- ── function_search_path_mutable: lock search_path on flagged functions ──
-- We pin search_path = public, pg_temp without rewriting the function bodies.
-- If a function has multiple overloads, ALTER FUNCTION must specify the
-- argument types; the lint output told us each signature.
ALTER FUNCTION public.award_badge(uuid, text)                         SET search_path = public, pg_temp;
ALTER FUNCTION public.touch_app_config()                              SET search_path = public, pg_temp;
ALTER FUNCTION public._orphans_set_updated_at()                       SET search_path = public, pg_temp;
ALTER FUNCTION public.donate_to_project(uuid, uuid, integer)          SET search_path = public, pg_temp;
ALTER FUNCTION public.analytics_add_session(uuid, integer, integer)   SET search_path = public, pg_temp;
ALTER FUNCTION public.get_global_stats()                              SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_global_active(text)                   SET search_path = public, pg_temp;
ALTER FUNCTION public.sync_monthly_points()                           SET search_path = public, pg_temp;
ALTER FUNCTION public.record_streak_activity(uuid, text)              SET search_path = public, pg_temp;
ALTER FUNCTION public.get_streak_history(uuid, text, integer)         SET search_path = public, pg_temp;
ALTER FUNCTION public.apply_referral(text)                            SET search_path = public, pg_temp;
ALTER FUNCTION public.trigger_generate_referral_code()                SET search_path = public, pg_temp;
ALTER FUNCTION public.get_user_orphan_sponsorships(uuid)              SET search_path = public, pg_temp;

-- These two had different/unknown signatures in the lint output; pin via
-- DO block so missing overloads don't break the whole migration.
DO $$
BEGIN
  EXECUTE (
    SELECT format('ALTER FUNCTION %s SET search_path = public, pg_temp',
                  oid::regprocedure)
    FROM pg_proc
    WHERE proname = 'get_user_project_donations'
      AND pronamespace = 'public'::regnamespace
    LIMIT 1
  );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  EXECUTE (
    SELECT format('ALTER FUNCTION %s SET search_path = public, pg_temp',
                  oid::regprocedure)
    FROM pg_proc
    WHERE proname = 'get_day_streak'
      AND pronamespace = 'public'::regnamespace
    LIMIT 1
  );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  EXECUTE (
    SELECT format('ALTER FUNCTION %s SET search_path = public, pg_temp',
                  oid::regprocedure)
    FROM pg_proc
    WHERE proname = 'invoke_edge_function'
      AND pronamespace = 'public'::regnamespace
    LIMIT 1
  );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ── REVOKE EXECUTE FROM anon on user-scoped SECURITY DEFINER RPCs ─────────
-- These functions only make sense for signed-in users. Keeping anon-callable
-- is harmless because they all check auth.uid(), but removing the grant
-- silences the linter and reduces attack surface.
-- (Functions that legitimately need anon access — email_account_exists,
-- apply_referral, handle_new_user — are deliberately NOT in this list.)
REVOKE EXECUTE ON FUNCTION public.award_badge(uuid, text)                              FROM anon;
REVOKE EXECUTE ON FUNCTION public.analytics_add_session(uuid, integer, integer)         FROM anon;
REVOKE EXECUTE ON FUNCTION public._merge_profile_into(uuid, uuid)                       FROM anon;
REVOKE EXECUTE ON FUNCTION public.consolidate_duplicate_profiles_by_email()             FROM anon;
REVOKE EXECUTE ON FUNCTION public.dedupe_profile_on_login(text)                         FROM anon;
REVOKE EXECUTE ON FUNCTION public.donate_to_project(uuid, uuid, integer)                FROM anon;
REVOKE EXECUTE ON FUNCTION public.earn_dhikr_points(text, integer, integer)             FROM anon;
REVOKE EXECUTE ON FUNCTION public.earn_quran_points(integer, integer, integer)          FROM anon;
REVOKE EXECUTE ON FUNCTION public.earn_xp(uuid, integer)                                FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_activity_history(text)                            FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_global_stats()                                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_month_points()                                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_orphan_recent_sponsors(uuid, integer)             FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_orphan_stats(uuid)                                FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_orphan_stats_bulk(uuid[])                         FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_project_donor_counts()                            FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_project_recent_donors(uuid, integer)              FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_project_seed_totals()                             FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_streak_history(uuid, text, integer)               FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_today_points()                                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_lifetime_activity(uuid)                      FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_monthly_stats(uuid)                          FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_orphan_sponsorships(uuid)                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_phrase_counts(uuid)                          FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_week_points()                                     FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_week_screen_time(uuid)                            FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_global_active(text)                         FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin()                                            FROM anon;
REVOKE EXECUTE ON FUNCTION public.link_qf_profile(text, uuid, text, text)               FROM anon;
REVOKE EXECUTE ON FUNCTION public.record_activity_stats(uuid, text, integer, integer)   FROM anon;
REVOKE EXECUTE ON FUNCTION public.record_dhikr_phrase(uuid, text, integer)              FROM anon;
REVOKE EXECUTE ON FUNCTION public.record_streak_activity(uuid, text)                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.set_updated_at()                                      FROM anon;
REVOKE EXECUTE ON FUNCTION public.sponsor_orphan(uuid, uuid, integer)                   FROM anon;
REVOKE EXECUTE ON FUNCTION public.sync_monthly_points()                                 FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_my_profile(text, text, text, jsonb, text, text, text, boolean) FROM anon;
REVOKE EXECUTE ON FUNCTION public.upsert_my_profile_bootstrap(text, text, text, jsonb, text, boolean)   FROM anon;
DO $$
BEGIN
  EXECUTE (
    SELECT format('REVOKE EXECUTE ON FUNCTION %s FROM anon', oid::regprocedure)
    FROM pg_proc
    WHERE proname = 'get_my_project_donations'
      AND pronamespace = 'public'::regnamespace
    LIMIT 1
  );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
