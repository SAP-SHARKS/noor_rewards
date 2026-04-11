-- ════════════════════════════════════════════════════════════════════════════
-- Community Projects Media Migration
-- Adds carousel (images + videos) support for donation projects
-- Run this in Supabase SQL Editor
-- ════════════════════════════════════════════════════════════════════════════

-- ── 1. Media table ──
CREATE TABLE IF NOT EXISTS community_project_media (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID NOT NULL REFERENCES community_projects(id) ON DELETE CASCADE,
  media_type    TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  url           TEXT NOT NULL,
  thumbnail_url TEXT,
  caption       TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_community_project_media_project
  ON community_project_media(project_id, sort_order);

-- ── 2. RLS — anyone can read, only authenticated users can manage (admin gating done in app) ──
ALTER TABLE community_project_media ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "media_select_all" ON community_project_media;
CREATE POLICY "media_select_all" ON community_project_media
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "media_insert_auth" ON community_project_media;
CREATE POLICY "media_insert_auth" ON community_project_media
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "media_update_auth" ON community_project_media;
CREATE POLICY "media_update_auth" ON community_project_media
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "media_delete_auth" ON community_project_media;
CREATE POLICY "media_delete_auth" ON community_project_media
  FOR DELETE TO authenticated USING (true);

-- ── 3. Storage bucket for project media (public read) ──
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'project-media',
  'project-media',
  true,
  104857600,  -- 100 MB max per file (videos can be large)
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif',
        'video/mp4', 'video/quicktime', 'video/webm']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 104857600,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif',
                              'video/mp4', 'video/quicktime', 'video/webm'];

-- ── 4. Storage policies ──
DROP POLICY IF EXISTS "project_media_public_read" ON storage.objects;
CREATE POLICY "project_media_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'project-media');

DROP POLICY IF EXISTS "project_media_auth_insert" ON storage.objects;
CREATE POLICY "project_media_auth_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'project-media');

DROP POLICY IF EXISTS "project_media_auth_update" ON storage.objects;
CREATE POLICY "project_media_auth_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'project-media')
  WITH CHECK (bucket_id = 'project-media');

DROP POLICY IF EXISTS "project_media_auth_delete" ON storage.objects;
CREATE POLICY "project_media_auth_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'project-media');

-- ── 5. Verify ──
SELECT 'community_project_media table' as object,
       (SELECT count(*) FROM information_schema.tables WHERE table_name = 'community_project_media') as exists;

SELECT 'project-media bucket' as object,
       (SELECT count(*) FROM storage.buckets WHERE id = 'project-media') as exists;
