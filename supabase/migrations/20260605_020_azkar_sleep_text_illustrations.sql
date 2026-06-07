-- =============================================================================
-- 20260605_020_azkar_sleep_text_illustrations
--
-- Continues the 20260605_010 audit, focused on the "Duas before Sleep"
-- category. Three changes per user direction:
--
--   1. Restore `heavy_scales` (the meezan / scales illustration) for the
--      tasbih-Fatima sleep dua (sleep_before_001). The previous audit
--      replaced it with `glory`; the meezan fits better because the
--      benefit centers on the weighed reward of SubhanAllah +
--      Alhamdulillah + Allahu Akbar.
--
--   2. Make `quran_complete` the SOLE illustration for sleep_before_002
--      (Surah Al-Ikhlas — blowing into palms). The `three_quls` book
--      visualization was confusing because this azkar is one specific
--      surah, not all three. sleep_before_003 (Falaq) and sleep_before_004
--      (Nas) similarly get ONLY `falaq_shield`.
--
--   3. Most before-sleep duas were defaulting to `night_peace`. Repeated
--      across 10 items the sleeping illustration felt monotonous. Keep
--      `night_peace` on ONE item (sleep_before_009 — the literal "in Your
--      name I die and I live" sleep prayer) and switch all others to a
--      dedicated text-based illustration showcasing the unique hadith
--      benefit of that recitation. Also covers sleep_before_008
--      (Surah Al-Kafirun), which previously had no illustration.
--
-- Idempotent: each azkar's existing mappings are wiped first, then the
-- corrected set is inserted. Safe to re-run.
-- =============================================================================

BEGIN;

-- 1. Register new text-illustration keys in azkar_animations --------------
-- Each key corresponds to a switch case in Dart `_buildIllustration`
-- inside lib/screens/dhikr_screen.dart. Adding a key here without a
-- matching Dart case will fall through to the default tree painter.
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_sleep_kafirun',
   'Sleep · Freedom from Shirk',
   'Text card: Surah Al-Kafirun before sleep — declaration of tawhid',
   '🌙', 300),
  ('benefit_sleep_submit',
   'Sleep · Die upon Islam',
   'Text card: surrender prayer — if you die before waking you die on Islam',
   '🤲', 301),
  ('benefit_sleep_soul',
   'Sleep · Soul Guarded',
   'Text card: soul guarded as Allah guards His righteous servants',
   '🛡️', 302),
  ('benefit_sleep_refuge',
   'Sleep · Refuge from Punishment',
   'Text card: refuge from punishment on the Day of Resurrection',
   '🌑', 303),
  ('benefit_sleep_provision',
   'Sleep · Provision Sufficient',
   'Text card: gratitude to the One who feeds, gives drink, shelters',
   '🥛', 304),
  ('benefit_sleep_entrust',
   'Sleep · Soul Entrusted',
   'Text card: soul entrusted to its Creator, safety asked of Him',
   '✨', 305),
  ('benefit_sleep_debt',
   'Sleep · Debt Settled',
   'Text card: debt settled and poverty repelled by the First and Last',
   '⚖️', 306),
  ('benefit_sleep_sins',
   'Sleep · Sins Lifted',
   'Text card: debt and sin lifted by His perfect words',
   '🕊️', 307),
  ('benefit_sleep_assembly',
   'Sleep · Highest Assembly',
   'Text card: sins forgiven, shaytan suppressed, raised to highest assembly',
   '🌟', 308),
  ('benefit_sleep_shelter',
   'Sleep · Refuge from the Fire',
   'Text card: sufficed, sheltered, refuge granted from the Fire',
   '🔥', 309),
  ('benefit_sleep_sajda',
   'Sleep · Surah As-Sajda',
   'Text card: Surah As-Sajda — nightly sunnah of the Messenger ﷺ',
   '📖', 310),
  ('benefit_sleep_mulk',
   'Sleep · Surah Al-Mulk',
   'Text card: Surah Al-Mulk intercedes for its reciter until forgiven',
   '👑', 311)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;


-- 2. Wipe existing mappings for every Duas-before-Sleep azkar we touch ----
DELETE FROM azkar_item_animations
WHERE azkar_id IN (
  'sleep_before_001', 'sleep_before_002', 'sleep_before_003',
  'sleep_before_004', 'sleep_before_008',
  'sleep_before_010', 'sleep_before_011', 'sleep_before_012',
  'sleep_before_013', 'sleep_before_014', 'sleep_before_015',
  'sleep_before_016', 'sleep_before_017', 'sleep_before_018',
  'sleep_before_019', 'sleep_before_020'
);


-- 3. Re-insert corrected mappings ----------------------------------------
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, m.sort_order
FROM (VALUES
  -- sleep_before_001: Tasbih Fatima (Subhanallah x33, Alhamdulillah x33,
  -- Allahu Akbar x34). Restore `heavy_scales` (the meezan visualization)
  -- alongside `glory` (the tasbih beads). Two-key pool so the daily
  -- rotation picks one of the two.
  ('sleep_before_001', 'heavy_scales', 0),
  ('sleep_before_001', 'glory',        1),

  -- sleep_before_002 (Surah Al-Ikhlas — blowing into palms #1): SOLE
  -- mapping is `quran_complete` — the "Ikhlas 3× = whole Quran reward"
  -- visualization. `three_quls` (the book-of-three) was removed because
  -- it depicted the whole triplet, not Ikhlas individually.
  ('sleep_before_002', 'quran_complete', 0),

  -- sleep_before_003 (Surah Al-Falaq): SOLE mapping `falaq_shield`.
  ('sleep_before_003', 'falaq_shield', 0),

  -- sleep_before_004 (Surah An-Nas): SOLE mapping `falaq_shield` —
  -- Falaq+Nas are the Mu'awwidhatayn pair this illustration depicts.
  ('sleep_before_004', 'falaq_shield', 0),

  -- sleep_before_008 (Surah Al-Kafirun): new text illustration for the
  -- Abu Dawud 5055 hadith — "declaration of freedom from polytheism".
  ('sleep_before_008', 'benefit_sleep_kafirun', 0),

  -- (sleep_before_009 is intentionally NOT touched — `night_peace` stays
  -- on it as the single representative sleep illustration. It is the
  -- literal "in Your name I die and I live" sleep prayer.)

  -- sleep_before_010 through sleep_before_020: dedicated text cards,
  -- one per hadith benefit. Each azkar gets exactly one illustration.
  ('sleep_before_010', 'benefit_sleep_submit',    0),
  ('sleep_before_011', 'benefit_sleep_soul',      0),
  ('sleep_before_012', 'benefit_sleep_refuge',    0),
  ('sleep_before_013', 'benefit_sleep_provision', 0),
  ('sleep_before_014', 'benefit_sleep_entrust',   0),
  ('sleep_before_015', 'benefit_sleep_debt',      0),
  ('sleep_before_016', 'benefit_sleep_sins',      0),
  ('sleep_before_017', 'benefit_sleep_assembly',  0),
  ('sleep_before_018', 'benefit_sleep_shelter',   0),
  ('sleep_before_019', 'benefit_sleep_sajda',     0),
  ('sleep_before_020', 'benefit_sleep_mulk',      0)
) AS m(azkar_id, anim_key, sort_order)
JOIN azkar_animations a ON a.key = m.anim_key
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- 4. Verify ---------------------------------------------------------------
-- Show the resulting animation pool for every sleep-before azkar. Each
-- row should map to the expected illustration; sleep_before_009 will
-- still show `night_peace` from a previous migration.
SELECT
  ai.id      AS azkar_id,
  ai.title,
  a.key      AS animation_key,
  aia.sort_order
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.category_id = 'duas_before_sleep'
ORDER BY ai.sort_order, aia.sort_order;

COMMIT;
