-- =============================================================================
-- 20260531_020_azkar_animations_backfill
--
-- Pre-populates `azkar_item_animations` so every azkar starts with at
-- least one animation matching what the app already shows today. After
-- this runs, the admin sees animations populated per azkar and can ADD
-- more keys to enable the daily-rotation pool (vs. starting from "none"
-- and having to assign every azkar manually).
--
-- Translates the Dart `_pickIllustration(azkarId)` logic 1:1 into SQL.
-- Idempotent — ON CONFLICT DO NOTHING preserves any manual edits.
-- =============================================================================

-- Helper: look up animation_id by key. CTE so we don't repeat the JOIN.
WITH anim AS (
  SELECT id, key FROM azkar_animations
),

-- ── New morning/evening IDs (by content) ───────────────────────────────────
mapping AS (
  SELECT azkar_id, anim_key FROM (VALUES
    -- Al-Fateha
    ('morning_1',  'benefit_morning_1'),
    ('evening_1',  'benefit_evening_1'),
    -- Opening of Baqarah
    ('morning_2',  'baqarah_shield'),
    ('evening_2',  'baqarah_shield'),
    -- Ayat al-Kursi
    ('morning_3',  'shield'),
    ('evening_3',  'shield'),
    -- 256–257
    ('morning_4',  'dua_scene'),
    ('evening_4',  'dua_scene'),
    ('morning_5',  'dua_scene'),
    ('evening_5',  'dua_scene'),
    -- Sleep peace
    ('morning_6',  'night_peace'),
    ('evening_6',  'night_peace'),
    -- Last verses of Baqarah
    ('morning_7',  'benefit_text_7'),
    ('evening_7',  'benefit_text_7'),
    ('morning_8',  'baqarah_burden'),
    ('evening_8',  'baqarah_burden'),
    -- Ikhlas, Falaq, Nas
    ('morning_9',  'quran_complete'),
    ('evening_9',  'quran_complete'),
    ('morning_10', 'falaq_shield'),
    ('evening_10', 'falaq_shield'),
    ('morning_11', 'dua_hands'),
    ('evening_11', 'dua_hands'),
    -- Sovereignty / Fitrah
    ('morning_12', 'dawn'),
    ('morning_13', 'dawn'),
    ('evening_13', 'night_peace'),
    ('evening_12', 'evening_sovereignty'),
    -- By Your Leave / Gratitude
    ('morning_14', 'cycle'),
    ('evening_14', 'cycle'),
    ('morning_15', 'cycle'),
    ('evening_15', 'cycle'),
    ('morning_16', 'benefit_text_16'),
    ('evening_16', 'benefit_text_16'),
    ('morning_17', 'benefit_text_17'),
    ('evening_17', 'benefit_text_17'),
    -- Raditu billahi
    ('morning_18', 'noor_door'),
    ('evening_18', 'noor_door'),
    -- Afiyah
    ('morning_19', 'afiyah_guard'),
    ('evening_19', 'afiyah_guard'),
    -- SubhanAllah 'adada khalqihi
    ('morning_20', 'heavy_scales'),
    ('evening_20', 'heavy_scales'),
    -- Bismillah protection
    ('morning_21', 'invincible'),
    ('evening_21', 'invincible'),
    -- Refuge from shirk
    ('morning_22', 'shield'),
    ('evening_22', 'shield'),
    -- Perfect words
    ('morning_23', 'invincible'),
    ('evening_23', 'invincible'),
    -- Knower of unseen
    ('morning_24', 'benefit_text_24'),
    ('evening_24', 'benefit_text_24'),
    -- Ya Hayyu Ya Qayyum
    ('morning_25', 'blinking_eyes'),
    ('evening_25', 'blinking_eyes'),
    -- Sayyid al-Istighfar
    ('morning_26', 'doors'),
    ('evening_26', 'doors'),
    -- Freed from Hellfire
    ('morning_27', 'flame'),
    ('evening_27', 'flame'),
    -- Health body/hearing/sight
    ('morning_28', 'vessels'),
    ('evening_28', 'vessels'),
    -- Hasbiyallahu
    ('morning_29', 'pillars'),
    ('evening_29', 'pillars'),
    -- Morning blessings
    ('morning_30', 'blessings'),
    -- La ilaha illallah 100x
    ('morning_31', 'scales'),
    ('evening_30', 'scales'),
    -- SubhanAllah wa bihamdihi 100x
    ('morning_32', 'ocean'),
    ('evening_31', 'ocean'),
    -- Salawat Ibrahim
    ('evening_32', 'salawat_intercession'),
    ('morning_33', 'salawat_intercession'),

    -- ── Legacy "lwa" IDs (older imported set) ──
    ('morning_lwa_1', 'shield'),
    ('evening_lwa_1', 'shield'),
    ('morning_lwa_2', 'three_quls'),
    ('evening_lwa_2', 'three_quls'),
    ('morning_lwa_3', 'doors'),
    ('evening_lwa_3', 'doors'),
    ('morning_lwa_4', 'chains'),
    ('evening_lwa_4', 'chains'),
    ('morning_lwa_5', 'afiyah_guard'),
    ('evening_lwa_5', 'afiyah_guard')
  ) AS m(azkar_id, anim_key)
)

-- Insert the seed pairs, guarded by EXISTS so we don't create rows for
-- mapping entries whose azkar_id isn't in the DB.
INSERT INTO azkar_item_animations (azkar_id, animation_id, sort_order)
SELECT
  m.azkar_id,
  a.id,
  0
FROM mapping m
JOIN anim a ON a.key = m.anim_key
WHERE EXISTS (SELECT 1 FROM azkar_items ai WHERE ai.id = m.azkar_id)
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- ── Fallback: any azkar still missing a mapping gets the default Noor Tree
-- so the admin sees something instead of "none" for every leftover item.
INSERT INTO azkar_item_animations (azkar_id, animation_id, sort_order)
SELECT
  ai.id,
  (SELECT id FROM azkar_animations WHERE key = 'noor_tree'),
  0
FROM azkar_items ai
WHERE NOT EXISTS (
  SELECT 1 FROM azkar_item_animations aia WHERE aia.azkar_id = ai.id
)
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- ── Verify ─────────────────────────────────────────────────────────────────
SELECT 'azkar_item_animations rows total' AS object,
       (SELECT count(*) FROM azkar_item_animations) AS count;
SELECT 'azkar with at least one animation' AS object,
       (SELECT count(DISTINCT azkar_id) FROM azkar_item_animations) AS count;
SELECT 'azkar still missing animations'    AS object,
       (
         SELECT count(*) FROM azkar_items ai
         WHERE NOT EXISTS (
           SELECT 1 FROM azkar_item_animations aia WHERE aia.azkar_id = ai.id
         )
       ) AS count;
