-- =============================================================================
-- 20260604_050_azkar_animation_pool
--
-- Maps each new screenshot-imported azkar to one or more existing morning/
-- evening animations that thematically match its content. The Flutter app's
-- daily-rotation picker (day_of_year % pool_size) then surfaces a varied
-- but topical illustration.
--
-- For azkar with no obvious thematic match in the existing animation
-- catalog (e.g. "Forgetting to recite Bismillah", many Rabbana duas), we
-- leave the pool empty. The card's hasIllustration gate (added earlier)
-- will skip rendering the 260px illustration block until fresh artwork
-- is added later.
--
-- Re-runnable: uses ON CONFLICT DO NOTHING on the (azkar_id, animation_id)
-- composite primary key.
-- =============================================================================

BEGIN;

-- Helper: lookup table-style INSERT pattern. Each row resolves the
-- animation_id from azkar_animations.key. ON CONFLICT keeps existing
-- mappings if this migration is re-run.

INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, m.sort_order
FROM (VALUES
  -- ── Duas before Sleep ──────────────────────────────────────────────────
  ('sleep_before_001', 'heavy_scales',     0),  -- Tasbih Fatima (33+33+34)
  ('sleep_before_002', 'three_quls',       0),  -- Blowing into palms 1 (Ikhlas)
  ('sleep_before_002', 'quran_complete',   1),
  ('sleep_before_003', 'three_quls',       0),  -- Blowing into palms 2 (Falaq)
  ('sleep_before_003', 'falaq_shield',     1),
  ('sleep_before_004', 'three_quls',       0),  -- Blowing into palms 3 (Nas)
  ('sleep_before_005', 'shield',           0),  -- Ayatul Kursi
  ('sleep_before_006', 'baqarah_shield',   0),  -- Al-Baqarah 285
  ('sleep_before_007', 'baqarah_burden',   0),  -- Al-Baqarah 286
  ('sleep_before_008', 'quran_complete',   0),  -- Surah al-Kafirun
  ('sleep_before_009', 'night_peace',      0),  -- Prior to Sleeping 1
  ('sleep_before_009', 'noor_tree',        1),
  ('sleep_before_010', 'night_peace',      0),
  ('sleep_before_011', 'night_peace',      0),
  ('sleep_before_012', 'night_peace',      0),
  ('sleep_before_013', 'night_peace',      0),
  ('sleep_before_014', 'night_peace',      0),
  ('sleep_before_015', 'night_peace',      0),
  ('sleep_before_016', 'night_peace',      0),
  ('sleep_before_017', 'night_peace',      0),
  ('sleep_before_018', 'night_peace',      0),
  ('sleep_before_019', 'quran_complete',   0),  -- Surah As-Sajda
  ('sleep_before_019', 'night_peace',      1),
  ('sleep_before_020', 'quran_complete',   0),  -- Surah Al-Mulk
  ('sleep_before_020', 'night_peace',      1),

  -- ── Duas after Salah ──────────────────────────────────────────────────
  ('salah_after_002', 'doors',             0),  -- Astaghfirullah 3x
  ('salah_after_003', 'dua_hands',         0),  -- Allahumma antas-salaam
  ('salah_after_004', 'dua_hands',         0),  -- Allahumma a'inni 'ala dhikrika
  ('salah_after_005', 'scales',            0),  -- La ilaha illallah... (ONCE long version)
  ('salah_after_006', 'heavy_scales',      0),  -- Tasbih 33+33+33+1
  ('salah_after_006', 'scales',            1),
  ('salah_after_007', 'scales',            0),  -- Tahlil 10x (Fajr/Maghrib)
  ('salah_after_008', 'flame',             0),  -- After Fajr only (likely Allahumma ajirni)
  ('salah_after_009', 'dua_hands',         0),
  ('salah_after_010', 'three_quls',        0),  -- 3 Quls 3x
  ('salah_after_010', 'quran_complete',    1),
  ('salah_after_011', 'three_quls',        0),
  ('salah_after_011', 'quran_complete',    1),
  ('salah_after_012', 'three_quls',        0),
  ('salah_after_012', 'quran_complete',    1),
  ('salah_after_013', 'dua_hands',         0),
  ('salah_after_014', 'dua_hands',         0),  -- Before personal du'a

  -- ── Daily Duas ─────────────────────────────────────────────────────────
  ('daily_dua_001', 'night_peace',         0),  -- Upon Going to Sleep
  ('daily_dua_002', 'dawn',                0),  -- Wake up from Sleep
  ('daily_dua_003', 'invincible',          0),  -- When Leaving Home (Bismillah tawakkaltu)
  ('daily_dua_004', 'noor_tree',           0),  -- When Entering Home
  ('daily_dua_015', 'salawat_intercession',0),  -- Dua after Adhaan (Wasilah)
  ('daily_dua_018', 'dua_hands',           0),  -- Visiting the Graves
  ('daily_dua_021', 'ocean',               0),  -- When Sneezing (Alhamdulillah)
  ('daily_dua_024', 'vessels',             0),  -- For Good Health (7x)
  ('daily_dua_025', 'vessels',             0),  -- Cure of any Illness
  ('daily_dua_026', 'afiyah_guard',        0),  -- Placing Children under Allah's Protection
  ('daily_dua_026', 'invincible',          1),
  ('daily_dua_033', 'shield',              0),  -- Seek Refuge (from grave/hell/dajjal)
  ('daily_dua_034', 'pillars',             0),  -- Hasbunallah wa ni'mal wakeel
  ('daily_dua_037', 'flame',               0),  -- Protection from Hellfire
  ('daily_dua_039', 'chains',              0),  -- Any Difficult Affairs
  ('daily_dua_040', 'chains',              0),  -- Anxiety and Sorrow
  ('daily_dua_043', 'vessels',             0),  -- When Visiting Sick

  -- ── Remembrance of Allah ──────────────────────────────────────────────
  ('dhikr_028', 'ocean',                   0),  -- SubhanAllah wa bihamdihi
  ('dhikr_029', 'gates',                   0),  -- Allahumma innaka 'afuwwun (Laylatul Qadr)
  ('dhikr_030', 'pillars',                 0),  -- La hawla wa la quwwata illa billah
  ('dhikr_031', 'heavy_scales',            0),  -- SubhanAllah Alhamdulillah La ilaha illallah Allahu Akbar
  ('dhikr_032', 'chains',                  0),  -- Dua of Yunus (in distress)

  -- ── Ruquiya ──────────────────────────────────────────────────────────
  ('ruquiya_001', 'afiyah_guard',          0),  -- Protect Children From Harm
  ('ruquiya_001', 'invincible',            1),
  ('ruquiya_002', 'vessels',               0),  -- Healing & protection from sickness
  ('ruquiya_003', 'shield',                0),  -- Guard against black magic
  ('ruquiya_004', 'shield',                0)   -- Shield yourself from all evil forces

) AS m(azkar_id, anim_key, sort_order)
JOIN azkar_animations a ON a.key = m.anim_key
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- Verify: count of azkar that now have at least one animation in their pool
SELECT
  ai.category_id,
  COUNT(DISTINCT ai.id) FILTER (WHERE aia.azkar_id IS NOT NULL) AS with_animation,
  COUNT(DISTINCT ai.id) FILTER (WHERE aia.azkar_id IS NULL)     AS without_animation
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
WHERE ai.category_id IN (
  'duas_before_sleep', 'duas_after_salah', 'daily_duas',
  'remembrance_of_allah', 'rabbana_40', 'ruquiya'
)
GROUP BY ai.category_id
ORDER BY ai.category_id;

COMMIT;
