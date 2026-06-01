-- =============================================================================
-- 20260531_010_azkar_tags_and_animations
--
-- Restructures azkar data to be fully admin-managed instead of code-driven:
--
--   1. Many-to-many AZKAR ↔ CATEGORIES (tags). One azkar can now appear
--      in Morning + Evening + Before-Sleep simultaneously without being
--      duplicated as separate rows.
--   2. Animation pool per azkar. Each azkar has a list of compatible
--      animations; the app picks one per day so the user sees variety.
--
-- The existing `azkar_items.category_id` column is preserved as the
-- "default / fallback" category so old code keeps working. Reads should
-- prefer the new junction tables once the Flutter side is updated.
--
-- Idempotent — safe to re-run.
-- =============================================================================

-- ── 1. Junction: azkar_items ↔ azkar_categories ────────────────────────────
CREATE TABLE IF NOT EXISTS azkar_item_categories (
  azkar_id    TEXT NOT NULL REFERENCES azkar_items(id) ON DELETE CASCADE,
  category_id TEXT NOT NULL REFERENCES azkar_categories(id) ON DELETE CASCADE,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (azkar_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_azkar_item_categories_cat
  ON azkar_item_categories(category_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_azkar_item_categories_azkar
  ON azkar_item_categories(azkar_id);


-- ── 2. Animations catalog ──────────────────────────────────────────────────
-- `key` is the string the Flutter `_buildIllustration` switch resolves on.
-- New animations require both a new row here AND a matching case in code
-- (the painter widget lives in Dart). Removing a row removes the option
-- from the admin UI without breaking unrelated code.
CREATE TABLE IF NOT EXISTS azkar_animations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL,
  description TEXT,
  icon        TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_azkar_animations_active
  ON azkar_animations(is_active, sort_order);


-- ── 3. Junction: azkar_items ↔ azkar_animations (the daily-rotation pool) ──
CREATE TABLE IF NOT EXISTS azkar_item_animations (
  azkar_id     TEXT NOT NULL REFERENCES azkar_items(id) ON DELETE CASCADE,
  animation_id UUID NOT NULL REFERENCES azkar_animations(id) ON DELETE CASCADE,
  weight       INTEGER NOT NULL DEFAULT 1,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (azkar_id, animation_id)
);

CREATE INDEX IF NOT EXISTS idx_azkar_item_animations_azkar
  ON azkar_item_animations(azkar_id, sort_order);


-- ── 4. Backfill: copy current single-category data into the junction ──────
-- Anything that already lives in azkar_items.category_id becomes a
-- junction row. Existing junction entries are preserved (ON CONFLICT skip).
INSERT INTO azkar_item_categories (azkar_id, category_id, sort_order)
SELECT
  ai.id,
  ai.category_id,
  COALESCE(ai.sort_order, 0)
FROM azkar_items ai
WHERE ai.category_id IS NOT NULL
ON CONFLICT (azkar_id, category_id) DO NOTHING;


-- ── 5. Seed the animation catalog with the keys already used in code ──────
-- These map 1:1 to the cases inside the Flutter `_buildIllustration` switch.
-- Admin can rename / add description / add icon later via the dashboard.
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('noor_tree',             'Noor Tree (default)',       'Growing tree with colorful leaf orbs', '🌳', 0),
  ('shield',                'Protection Shield',         'Shield dome forming around the figure (Ayat al-Kursi)', '🛡️', 10),
  ('three_quls',            'Three Quls',                'Three concentric barrier rings around the Qur’an', '📿', 20),
  ('gates',                 'Gates of Jannah',           'Two gates swinging open with paradise light', '🚪', 30),
  ('chains',                'Breaking Chains',           'Four chains breaking progressively', '⛓️', 40),
  ('dua_scene',             'Dua Scene',                 'Praying-hands devotional scene', '🤲', 50),
  ('dua_hands',             'Dua Hands',                 'Hands raised in supplication', '🙏', 51),
  ('benefit_morning_1',     'Morning Benefit Text',      'Text-card reward for morning Al-Fateha', '🌅', 60),
  ('benefit_evening_1',     'Evening Benefit Text',      'Text-card reward for evening Al-Fateha', '🌇', 61),
  ('benefit_text_7',        'Benefit Text · Al-Baqarah end', 'Last verses of Baqarah – protection from evils', '📖', 70),
  ('benefit_text_16',       'Benefit Text · Gratitude',  'Gratitude reward text card', '🤲', 71),
  ('benefit_text_17',       'Benefit Text · Praise',     'Divine praise reward awaits text card', '✨', 72),
  ('benefit_text_24',       'Benefit Text · Unseen',     'Knower of the Unseen text card', '🌌', 73),
  ('baqarah_shield',        'Baqarah Shield',            'Verses-of-Baqarah opening shield', '🕯️', 80),
  ('baqarah_burden',        'Baqarah Burden Lifted',     'Last verses – Allah does not burden a soul', '💫', 81),
  ('quran_complete',        'Quran Complete (3 Quls)',   'Qur’an completion animation', '📕', 90),
  ('falaq_shield',          'Al-Falaq Shield',           'Surah Al-Falaq protection animation', '🌒', 100),
  ('dawn',                  'Dawn',                      'Sunrise / fitrah scene (morning)', '🌅', 110),
  ('dawn_dusk',             'Dawn / Dusk',               'Transition from night to day', '🌄', 111),
  ('night_peace',           'Night Peace',               'Calm starry night scene (evening)', '🌃', 112),
  ('evening_sovereignty',   'Evening Sovereignty',       'Dominion declaration text scene', '👑', 113),
  ('cycle',                 'Cycle',                     'Day/night cycle scene', '🔄', 120),
  ('noor_door',             'Noor Door',                 'Door of divine pleasure opening', '🚪', 130),
  ('afiyah_guard',          'Afiyah 6-direction Guard',  'Protection from six sides', '🛡️', 140),
  ('heavy_scales',          'Heavy Scales',              'Cosmic-weight tasbih scales', '⚖️', 150),
  ('scales',                'Unparalleled Scales',       'La ilaha illallah scales', '⚖️', 151),
  ('invincible',            'Invincible Name',           'Bismillah / perfect words protection', '🔒', 160),
  ('blinking_eyes',         'Cradled Heart',             'Ya Hayyu Ya Qayyum heart scene', '💗', 170),
  ('doors',                 'Heart Doors',               'Sayyid al-Istighfar purification doors', '🚪', 180),
  ('flame',                 'Freedom Flame',             'Freed from Hellfire flame', '🔥', 190),
  ('vessels',               'Three Vessels',             'Body, hearing, sight wellness vessels', '🫙', 200),
  ('pillars',               'Seven Pillars',             'Hasbiyallah seven pillars', '🏛️', 210),
  ('blessings',             'Blessings',                 'Morning blessings scene', '🌟', 220),
  ('ocean',                 'Ocean of Forgiveness',      'Subhanallah wa bihamdihi ocean', '🌊', 230),
  ('salawat_intercession',  'Salawat Intercession',      'Durood Ibrahim intercession scene', '🕌', 240)
ON CONFLICT (key) DO NOTHING;


-- ── 6. RLS — public read, authenticated write (admin gated client-side) ───
ALTER TABLE azkar_item_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE azkar_animations      ENABLE ROW LEVEL SECURITY;
ALTER TABLE azkar_item_animations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "azkar_item_categories_select_all" ON azkar_item_categories;
CREATE POLICY "azkar_item_categories_select_all" ON azkar_item_categories
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "azkar_item_categories_write_auth" ON azkar_item_categories;
CREATE POLICY "azkar_item_categories_write_auth" ON azkar_item_categories
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "azkar_animations_select_all" ON azkar_animations;
CREATE POLICY "azkar_animations_select_all" ON azkar_animations
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "azkar_animations_write_auth" ON azkar_animations;
CREATE POLICY "azkar_animations_write_auth" ON azkar_animations
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "azkar_item_animations_select_all" ON azkar_item_animations;
CREATE POLICY "azkar_item_animations_select_all" ON azkar_item_animations
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "azkar_item_animations_write_auth" ON azkar_item_animations;
CREATE POLICY "azkar_item_animations_write_auth" ON azkar_item_animations
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ── 7. RPC: fetch azkar tagged with a given category, ordered ─────────────
-- Joins the junction. Returns the full azkar row + category-specific sort
-- order so the screen can render them in the right sequence per tag.
CREATE OR REPLACE FUNCTION get_azkar_for_category(p_category_id TEXT)
RETURNS TABLE (
  id                 TEXT,
  arabic             TEXT,
  transliteration    TEXT,
  translation        TEXT,
  recommended_count  INTEGER,
  category_id        TEXT,
  reward             TEXT,
  reference          TEXT,
  category_sort      INTEGER,
  hadith_full        TEXT,
  audio_url          TEXT
)
LANGUAGE sql STABLE AS $$
  SELECT
    ai.id,
    ai.arabic,
    ai.transliteration,
    ai.translation,
    ai.recommended_count,
    ai.category_id,
    ai.reward,
    ai.reference,
    aic.sort_order AS category_sort,
    ai.hadith_full,
    ai.audio_url
  FROM azkar_items ai
  JOIN azkar_item_categories aic ON aic.azkar_id = ai.id
  WHERE aic.category_id = p_category_id
  ORDER BY aic.sort_order ASC, ai.id ASC;
$$;

GRANT EXECUTE ON FUNCTION get_azkar_for_category(TEXT) TO authenticated, anon;


-- ── 8. RPC: fetch the animation pool for an azkar (with names) ────────────
CREATE OR REPLACE FUNCTION get_animations_for_azkar(p_azkar_id TEXT)
RETURNS TABLE (
  animation_id UUID,
  key          TEXT,
  name         TEXT,
  description  TEXT,
  icon         TEXT,
  weight       INTEGER
)
LANGUAGE sql STABLE AS $$
  SELECT
    a.id          AS animation_id,
    a.key,
    a.name,
    a.description,
    a.icon,
    aia.weight
  FROM azkar_item_animations aia
  JOIN azkar_animations a ON a.id = aia.animation_id
  WHERE aia.azkar_id = p_azkar_id
    AND a.is_active = true
  ORDER BY aia.sort_order ASC, a.sort_order ASC;
$$;

GRANT EXECUTE ON FUNCTION get_animations_for_azkar(TEXT) TO authenticated, anon;


-- ── 9. updated_at trigger for azkar_animations ─────────────────────────────
CREATE OR REPLACE FUNCTION _azkar_animations_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

DROP TRIGGER IF EXISTS azkar_animations_updated_at ON azkar_animations;
CREATE TRIGGER azkar_animations_updated_at
  BEFORE UPDATE ON azkar_animations
  FOR EACH ROW EXECUTE FUNCTION _azkar_animations_set_updated_at();


-- ── 10. Verify ─────────────────────────────────────────────────────────────
SELECT 'azkar_item_categories rows backfilled' AS object,
       (SELECT count(*) FROM azkar_item_categories) AS count;
SELECT 'azkar_animations seeded' AS object,
       (SELECT count(*) FROM azkar_animations) AS count;
SELECT routine_name, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_azkar_for_category', 'get_animations_for_azkar')
ORDER BY routine_name;
