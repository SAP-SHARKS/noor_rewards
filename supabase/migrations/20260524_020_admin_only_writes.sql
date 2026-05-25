-- =============================================================================
-- 20260524_020_admin_only_writes
--
-- Fixes audit-final.md F-3 + F-5: the four admin-managed tables and three
-- storage buckets currently allow ANY authenticated user to insert/update/
-- delete. Replaces every `WITH CHECK (true)` policy with `public.is_admin()`.
--
-- Affected:
--   • Tables:   app_config, sponsored_orphans,
--               community_project_media, onboarding_images
--   • Buckets:  project-media, orphan-photos, onboarding-images
--
-- Reads stay open (these are public content); writes require admin.
-- =============================================================================

-- ── app_config (admin-tunable economy, theme, feature flags) ────────────────
DROP POLICY IF EXISTS "config_insert_auth"        ON public.app_config;
DROP POLICY IF EXISTS "config_update_auth"        ON public.app_config;
DROP POLICY IF EXISTS "config_delete_auth"        ON public.app_config;
DROP POLICY IF EXISTS "app_config_admin_insert"   ON public.app_config;
DROP POLICY IF EXISTS "app_config_admin_update"   ON public.app_config;
DROP POLICY IF EXISTS "app_config_admin_delete"   ON public.app_config;

CREATE POLICY "app_config_admin_insert" ON public.app_config
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "app_config_admin_update" ON public.app_config
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "app_config_admin_delete" ON public.app_config
  FOR DELETE TO authenticated USING (public.is_admin());

-- ── sponsored_orphans ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "orphans_insert_auth"   ON public.sponsored_orphans;
DROP POLICY IF EXISTS "orphans_update_auth"   ON public.sponsored_orphans;
DROP POLICY IF EXISTS "orphans_delete_auth"   ON public.sponsored_orphans;

CREATE POLICY "orphans_admin_insert" ON public.sponsored_orphans
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "orphans_admin_update" ON public.sponsored_orphans
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "orphans_admin_delete" ON public.sponsored_orphans
  FOR DELETE TO authenticated USING (public.is_admin());

-- ── community_project_media ────────────────────────────────────────────────
DROP POLICY IF EXISTS "media_insert_auth"   ON public.community_project_media;
DROP POLICY IF EXISTS "media_update_auth"   ON public.community_project_media;
DROP POLICY IF EXISTS "media_delete_auth"   ON public.community_project_media;

CREATE POLICY "media_admin_insert" ON public.community_project_media
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "media_admin_update" ON public.community_project_media
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "media_admin_delete" ON public.community_project_media
  FOR DELETE TO authenticated USING (public.is_admin());

-- ── onboarding_images ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "onboarding_images_insert_auth"   ON public.onboarding_images;
DROP POLICY IF EXISTS "onboarding_images_update_auth"   ON public.onboarding_images;
DROP POLICY IF EXISTS "onboarding_images_delete_auth"   ON public.onboarding_images;

CREATE POLICY "onboarding_images_admin_insert" ON public.onboarding_images
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "onboarding_images_admin_update" ON public.onboarding_images
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "onboarding_images_admin_delete" ON public.onboarding_images
  FOR DELETE TO authenticated USING (public.is_admin());

-- ── Storage bucket: project-media ──────────────────────────────────────────
DROP POLICY IF EXISTS "project_media_auth_insert" ON storage.objects;
DROP POLICY IF EXISTS "project_media_auth_update" ON storage.objects;
DROP POLICY IF EXISTS "project_media_auth_delete" ON storage.objects;

CREATE POLICY "project_media_admin_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'project-media' AND public.is_admin());
CREATE POLICY "project_media_admin_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING      (bucket_id = 'project-media' AND public.is_admin())
  WITH CHECK (bucket_id = 'project-media' AND public.is_admin());
CREATE POLICY "project_media_admin_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING      (bucket_id = 'project-media' AND public.is_admin());

-- ── Storage bucket: orphan-photos ──────────────────────────────────────────
DROP POLICY IF EXISTS "orphan_photos_auth_insert" ON storage.objects;
DROP POLICY IF EXISTS "orphan_photos_auth_update" ON storage.objects;
DROP POLICY IF EXISTS "orphan_photos_auth_delete" ON storage.objects;

CREATE POLICY "orphan_photos_admin_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'orphan-photos' AND public.is_admin());
CREATE POLICY "orphan_photos_admin_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING      (bucket_id = 'orphan-photos' AND public.is_admin())
  WITH CHECK (bucket_id = 'orphan-photos' AND public.is_admin());
CREATE POLICY "orphan_photos_admin_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING      (bucket_id = 'orphan-photos' AND public.is_admin());

-- ── Storage bucket: onboarding-images ──────────────────────────────────────
DROP POLICY IF EXISTS "onboarding_images_auth_insert" ON storage.objects;
DROP POLICY IF EXISTS "onboarding_images_auth_update" ON storage.objects;
DROP POLICY IF EXISTS "onboarding_images_auth_delete" ON storage.objects;

CREATE POLICY "onboarding_images_admin_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'onboarding-images' AND public.is_admin());
CREATE POLICY "onboarding_images_admin_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING      (bucket_id = 'onboarding-images' AND public.is_admin())
  WITH CHECK (bucket_id = 'onboarding-images' AND public.is_admin());
CREATE POLICY "onboarding_images_admin_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING      (bucket_id = 'onboarding-images' AND public.is_admin());

-- ── Verify ──────────────────────────────────────────────────────────────────
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('app_config', 'sponsored_orphans',
                    'community_project_media', 'onboarding_images')
ORDER BY tablename, policyname;
