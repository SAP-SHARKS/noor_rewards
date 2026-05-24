-- ════════════════════════════════════════════════════════════════════════════
-- Sponsored Orphans Migration
--
-- Adds a dedicated `sponsored_orphans` table for individual orphans who
-- can be sponsored by users via the existing Seeds economy.
--
-- Design decisions (already locked with the product owner):
--   • One-time Seeds donations (no recurring billing) — reuses user_donations
--   • Multiple sponsors per orphan (progress bar fills like community_projects)
--   • Public identity = first name + age + city
--
-- Run this in Supabase SQL Editor (idempotent — safe to re-run).
-- ════════════════════════════════════════════════════════════════════════════

-- ── 1. Table ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sponsored_orphans (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity (kept minimal — first name + initial is the public default)
  first_name           TEXT NOT NULL,
  last_initial         TEXT,
  age                  INTEGER NOT NULL CHECK (age >= 0 AND age <= 25),
  gender               TEXT CHECK (gender IN ('male', 'female')),

  -- Education
  grade                TEXT,
  school               TEXT,

  -- Location
  city                 TEXT,
  country              TEXT,

  -- Family background
  father_passed_cause  TEXT,       -- one short sentence, displayed verbatim
  mother_status        TEXT,       -- e.g. 'alive', 'passed', 'remarried'
  siblings_count       INTEGER DEFAULT 0,

  -- Story (2–3 sentences shown on detail screen)
  story                TEXT,

  -- Media
  photo_url            TEXT,       -- public URL from orphan-photos bucket

  -- Sponsorship economy
  target_seeds         INTEGER NOT NULL DEFAULT 1000,
  min_sponsorship      INTEGER NOT NULL DEFAULT 50,

  -- Partner / source
  partner_org          TEXT,

  -- Admin controls
  is_active            BOOLEAN NOT NULL DEFAULT true,
  sort_order           INTEGER NOT NULL DEFAULT 0,

  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orphans_active_sort
  ON sponsored_orphans(is_active, sort_order);

-- ── 2. Link orphans into user_donations (alongside project_id) ──────────────
ALTER TABLE user_donations
  ADD COLUMN IF NOT EXISTS orphan_id UUID REFERENCES sponsored_orphans(id) ON DELETE SET NULL;

-- project_id was originally NOT NULL — drop that so orphan donations
-- (which have project_id NULL + orphan_id set) can be inserted.
ALTER TABLE user_donations ALTER COLUMN project_id DROP NOT NULL;

-- A donation row references exactly ONE entity: either a project OR an orphan
ALTER TABLE user_donations DROP CONSTRAINT IF EXISTS donation_target_xor;
ALTER TABLE user_donations
  ADD CONSTRAINT donation_target_xor CHECK (
    (project_id IS NOT NULL AND orphan_id IS NULL) OR
    (project_id IS NULL     AND orphan_id IS NOT NULL)
  );

CREATE INDEX IF NOT EXISTS idx_user_donations_orphan
  ON user_donations(orphan_id) WHERE orphan_id IS NOT NULL;

-- ── 3. RLS — public read, authenticated write (admin gated in app) ─────────
ALTER TABLE sponsored_orphans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orphans_select_all"   ON sponsored_orphans;
DROP POLICY IF EXISTS "orphans_insert_auth"  ON sponsored_orphans;
DROP POLICY IF EXISTS "orphans_update_auth"  ON sponsored_orphans;
DROP POLICY IF EXISTS "orphans_delete_auth"  ON sponsored_orphans;

CREATE POLICY "orphans_select_all" ON sponsored_orphans
  FOR SELECT USING (true);
CREATE POLICY "orphans_insert_auth" ON sponsored_orphans
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "orphans_update_auth" ON sponsored_orphans
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "orphans_delete_auth" ON sponsored_orphans
  FOR DELETE TO authenticated USING (true);

-- ── 4. Storage bucket for orphan photos ─────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'orphan-photos',
  'orphan-photos',
  true,
  10485760,  -- 10 MB max per photo (portraits don't need video size)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

DROP POLICY IF EXISTS "orphan_photos_public_read"  ON storage.objects;
DROP POLICY IF EXISTS "orphan_photos_auth_insert"  ON storage.objects;
DROP POLICY IF EXISTS "orphan_photos_auth_update"  ON storage.objects;
DROP POLICY IF EXISTS "orphan_photos_auth_delete"  ON storage.objects;

CREATE POLICY "orphan_photos_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'orphan-photos');
CREATE POLICY "orphan_photos_auth_insert" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'orphan-photos');
CREATE POLICY "orphan_photos_auth_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'orphan-photos') WITH CHECK (bucket_id = 'orphan-photos');
CREATE POLICY "orphan_photos_auth_delete" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'orphan-photos');

-- ── 5. RPCs ─────────────────────────────────────────────────────────────────

-- 5a. Sponsor an orphan — mirrors donate_to_project pattern
--     Inserts a row into user_donations and lets your existing balance
--     trigger (or app-level deduction) handle seed accounting.
CREATE OR REPLACE FUNCTION sponsor_orphan(
  p_user_id   UUID,
  p_orphan_id UUID,
  p_amount    INTEGER
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_min_sponsorship INTEGER;
  v_is_active       BOOLEAN;
  v_balance         INTEGER;
BEGIN
  -- Validate orphan
  SELECT min_sponsorship, is_active
    INTO v_min_sponsorship, v_is_active
  FROM sponsored_orphans WHERE id = p_orphan_id;

  IF NOT FOUND OR NOT v_is_active THEN
    RETURN FALSE;
  END IF;

  IF p_amount < v_min_sponsorship THEN
    RETURN FALSE;
  END IF;

  -- Check + deduct balance (profiles.noor_points is the seeds column —
  -- same one donate_to_project uses).
  SELECT noor_points INTO v_balance FROM profiles WHERE id = p_user_id FOR UPDATE;
  IF v_balance IS NULL OR v_balance < p_amount THEN
    RETURN FALSE;
  END IF;

  UPDATE profiles SET noor_points = noor_points - p_amount WHERE id = p_user_id;

  INSERT INTO user_donations (user_id, orphan_id, points_donated, created_at)
  VALUES (p_user_id, p_orphan_id, p_amount, now());

  RETURN TRUE;
END $$;

-- 5b. Aggregate stats per orphan (current seeds + distinct sponsor count)
CREATE OR REPLACE FUNCTION get_orphan_stats(p_orphan_id UUID)
RETURNS TABLE (
  current_seeds   BIGINT,
  sponsor_count   BIGINT
)
LANGUAGE sql STABLE AS $$
  SELECT
    COALESCE(SUM(points_donated), 0)::BIGINT AS current_seeds,
    COUNT(DISTINCT user_id)::BIGINT          AS sponsor_count
  FROM user_donations
  WHERE orphan_id = p_orphan_id;
$$;

-- 5c. Bulk variant — stats for many orphans at once (used by the list screen)
CREATE OR REPLACE FUNCTION get_orphan_stats_bulk(p_orphan_ids UUID[])
RETURNS TABLE (
  orphan_id      UUID,
  current_seeds  BIGINT,
  sponsor_count  BIGINT
)
LANGUAGE sql STABLE AS $$
  SELECT
    ud.orphan_id,
    COALESCE(SUM(ud.points_donated), 0)::BIGINT AS current_seeds,
    COUNT(DISTINCT ud.user_id)::BIGINT          AS sponsor_count
  FROM user_donations ud
  WHERE ud.orphan_id = ANY(p_orphan_ids)
  GROUP BY ud.orphan_id;
$$;

-- 5d. Recent sponsors for an orphan (for the detail screen "sponsored by" list)
CREATE OR REPLACE FUNCTION get_orphan_recent_sponsors(
  p_orphan_id UUID,
  p_limit     INTEGER DEFAULT 5
)
RETURNS TABLE (
  user_id        UUID,
  display_name   TEXT,
  avatar_url     TEXT,
  points_donated INTEGER,
  donated_at     TIMESTAMPTZ
)
LANGUAGE sql STABLE AS $$
  SELECT
    ud.user_id,
    p.display_name,
    p.avatar_url,
    ud.points_donated,
    ud.created_at
  FROM user_donations ud
  LEFT JOIN profiles p ON p.id = ud.user_id
  WHERE ud.orphan_id = p_orphan_id
  ORDER BY ud.created_at DESC
  LIMIT p_limit;
$$;

-- 5e. Per-user list of orphans they have sponsored (for My Donations view)
CREATE OR REPLACE FUNCTION get_user_orphan_sponsorships(p_user_id UUID)
RETURNS TABLE (
  orphan_id       UUID,
  first_name      TEXT,
  last_initial    TEXT,
  photo_url       TEXT,
  city            TEXT,
  country         TEXT,
  total_donated   BIGINT,
  last_donated_at TIMESTAMPTZ
)
LANGUAGE sql STABLE AS $$
  SELECT
    o.id,
    o.first_name,
    o.last_initial,
    o.photo_url,
    o.city,
    o.country,
    SUM(ud.points_donated)::BIGINT  AS total_donated,
    MAX(ud.created_at)              AS last_donated_at
  FROM user_donations ud
  JOIN sponsored_orphans o ON o.id = ud.orphan_id
  WHERE ud.user_id = p_user_id
  GROUP BY o.id
  ORDER BY MAX(ud.created_at) DESC;
$$;

-- ── 6. updated_at trigger ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION _orphans_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

DROP TRIGGER IF EXISTS orphans_updated_at ON sponsored_orphans;
CREATE TRIGGER orphans_updated_at
  BEFORE UPDATE ON sponsored_orphans
  FOR EACH ROW EXECUTE FUNCTION _orphans_set_updated_at();

-- ── 7. Verify ──────────────────────────────────────────────────────────────
SELECT 'sponsored_orphans table' AS object,
       (SELECT count(*) FROM information_schema.tables
         WHERE table_name = 'sponsored_orphans') AS exists;
SELECT 'orphan-photos bucket' AS object,
       (SELECT count(*) FROM storage.buckets WHERE id = 'orphan-photos') AS exists;
SELECT 'orphan_id column on user_donations' AS object,
       (SELECT count(*) FROM information_schema.columns
         WHERE table_name = 'user_donations' AND column_name = 'orphan_id') AS exists;
