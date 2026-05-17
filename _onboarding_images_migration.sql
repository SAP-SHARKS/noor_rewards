-- ════════════════════════════════════════════════════════════════════════════
-- Onboarding Images Migration
-- Admin-uploadable images for the Phase 1 + Phase 2 onboarding flow.
-- 11 named slots — admin uploads a file per slot from the admin web panel;
-- the Flutter app reads the public URL by slot_key and renders it (with a
-- built-in fallback when no upload exists yet).
-- Run this in Supabase SQL Editor.
-- ════════════════════════════════════════════════════════════════════════════

-- ── 1. Table: one row per slot ──
CREATE TABLE IF NOT EXISTS onboarding_images (
  slot_key    TEXT PRIMARY KEY,
  image_url   TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Seed the 11 known slots so the admin panel can list them as empty rows.
INSERT INTO onboarding_images (slot_key) VALUES
  ('onb_hero_1'),
  ('onb_aid_2'),
  ('onb_quran_2'),
  ('onb_quran_3'),
  ('onb_step_quran'),
  ('onb_step_orphans'),
  ('onb_zikr_4'),
  ('onb_impact_5'),
  ('onb_akhirah_7'),
  ('cause_orphans'),
  ('cause_water'),
  ('cause_war'),
  ('cause_disaster')
ON CONFLICT (slot_key) DO NOTHING;

-- ── 2. RLS — anyone can read; only authenticated users can write
--          (admin gating happens client-side via the email whitelist) ──
ALTER TABLE onboarding_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "onb_imgs_select_all"  ON onboarding_images;
CREATE POLICY "onb_imgs_select_all"  ON onboarding_images
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "onb_imgs_insert_auth" ON onboarding_images;
CREATE POLICY "onb_imgs_insert_auth" ON onboarding_images
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "onb_imgs_update_auth" ON onboarding_images;
CREATE POLICY "onb_imgs_update_auth" ON onboarding_images
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "onb_imgs_delete_auth" ON onboarding_images;
CREATE POLICY "onb_imgs_delete_auth" ON onboarding_images
  FOR DELETE TO authenticated USING (true);

-- ── 3. Storage bucket ──
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'onboarding-images',
  'onboarding-images',
  true,
  10485760,  -- 10 MB max per file
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- ── 4. Storage policies ──
DROP POLICY IF EXISTS "onb_imgs_public_read" ON storage.objects;
CREATE POLICY "onb_imgs_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'onboarding-images');

DROP POLICY IF EXISTS "onb_imgs_auth_insert" ON storage.objects;
CREATE POLICY "onb_imgs_auth_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'onboarding-images');

DROP POLICY IF EXISTS "onb_imgs_auth_update" ON storage.objects;
CREATE POLICY "onb_imgs_auth_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'onboarding-images')
  WITH CHECK (bucket_id = 'onboarding-images');

DROP POLICY IF EXISTS "onb_imgs_auth_delete" ON storage.objects;
CREATE POLICY "onb_imgs_auth_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'onboarding-images');

-- ── 5. Verify ──
SELECT 'onboarding_images table' as object,
       (SELECT count(*) FROM information_schema.tables WHERE table_name = 'onboarding_images') as exists;

SELECT 'onboarding-images bucket' as object,
       (SELECT count(*) FROM storage.buckets WHERE id = 'onboarding-images') as exists;

SELECT 'slot rows seeded' as object,
       (SELECT count(*) FROM onboarding_images) as count;
