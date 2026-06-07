-- =============================================================================
-- 20260605_040_azkar_after_salah_audit
--
-- Audits illustration mappings for the "Duas after Salah" category, same
-- rule as the 20260605_010/020 sleep audits: a Morning/Evening
-- illustration may be reused only if the recitation OR hadith benefit
-- matches; otherwise create a dedicated text-based card from the
-- azkar's reward text.
--
-- Changes per azkar:
--   • salah_after_003 (Allahumma antas-salaam): drop `dua_hands`
--     (generic), use new text card `benefit_salah_peace`.
--   • salah_after_004 (Allahumma a'inni 'ala dhikrika): drop `dua_hands`,
--     use new text card `benefit_salah_help`.
--   • salah_after_006 (Tasbih 33+33+33+1): add `glory` (the tasbih
--     beads) alongside `scales` for a two-key rotation pool.
--   • salah_after_008 (After-Fajr "knowledge / sustenance / deeds"):
--     was empty after the previous audit; add new text card
--     `benefit_salah_knowledge`.
--   • salah_after_010 (Surah Al-Ikhlas 3× after Fajr/Maghrib): drop
--     `three_quls` (it depicts the triplet, not Ikhlas alone). Keep
--     `quran_complete` (Ikhlas 3× = whole Quran reward).
--   • salah_after_011 (Surah Al-Falaq 3×): drop `three_quls`, keep
--     `falaq_shield` (Falaq+Nas illustration covers Falaq alone).
--   • salah_after_012 (Surah An-Nas 3×): drop `three_quls`, keep
--     `falaq_shield`.
--
-- Other items in the category already pass the audit and are not touched:
--   • salah_after_002 (Astaghfirullah 3×) → `doors` (istighfar match)
--   • salah_after_005 (long La ilaha illallah) → `scales`
--   • salah_after_007 (Tahlil 10× after Fajr/Maghrib) → `scales`
--   • salah_after_009 (Ayatul Kursi) → `shield`
--   • salah_after_013 (La ilaha illallahu wahdahu) → `scales`
--   • salah_after_014 (Durood Ibrahim) → `salawat_intercession`
--
-- Idempotent: re-runnable.
-- =============================================================================

BEGIN;

-- 1. Register new text-illustration keys ----------------------------------
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_salah_peace',
   'Salah · As-Salam',
   'Text card: "You are As-Salam, and from You is As-Salam"',
   '🕊️', 320),
  ('benefit_salah_help',
   'Salah · Help in Worship',
   'Text card: "Help me remember You, thank You, worship You well"',
   '🤲', 321),
  ('benefit_salah_knowledge',
   'Salah · Knowledge / Sustenance / Deeds',
   'Text card: post-Fajr "beneficial knowledge, good sustenance, accepted deeds"',
   '✨', 322)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;


-- 2. Wipe existing mappings for the azkar we are re-mapping ---------------
DELETE FROM azkar_item_animations
WHERE azkar_id IN (
  'salah_after_003', 'salah_after_004', 'salah_after_006',
  'salah_after_008', 'salah_after_010', 'salah_after_011',
  'salah_after_012'
);


-- 3. Re-insert corrected mappings ----------------------------------------
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, m.sort_order
FROM (VALUES
  -- salah_after_003: Allahumma antas-salaam. No M/E recitation/benefit
  -- match → dedicated text card.
  ('salah_after_003', 'benefit_salah_peace', 0),

  -- salah_after_004: Allahumma a'inni 'ala dhikrika. → text card.
  ('salah_after_004', 'benefit_salah_help', 0),

  -- salah_after_006: Tasbih 33+33+33+1 (Subhanallah/Alhamdulillah/Allahu
  -- Akbar followed by the unparalleled Tahlil to round to 100). Pool of
  -- two: `glory` for the tasbih beads, `scales` for the closing kalimah.
  ('salah_after_006', 'glory',  0),
  ('salah_after_006', 'scales', 1),

  -- salah_after_008: post-Fajr "knowledge / sustenance / deeds" dua.
  -- No M/E match (the previously-borrowed `flame` was about Hellfire,
  -- not knowledge) → dedicated text card.
  ('salah_after_008', 'benefit_salah_knowledge', 0),

  -- salah_after_010: Surah Al-Ikhlas 3× after Fajr/Maghrib. SOLE
  -- mapping is `quran_complete` (the "Ikhlas 3× = whole Quran"
  -- reward illustration). `three_quls` was removed — it depicts the
  -- entire triplet, not Ikhlas individually.
  ('salah_after_010', 'quran_complete', 0),

  -- salah_after_011: Surah Al-Falaq 3×. SOLE mapping `falaq_shield`.
  ('salah_after_011', 'falaq_shield', 0),

  -- salah_after_012: Surah An-Nas 3×. SOLE mapping `falaq_shield`
  -- (it depicts the Mu'awwidhatayn Falaq+Nas pair).
  ('salah_after_012', 'falaq_shield', 0)
) AS m(azkar_id, anim_key, sort_order)
JOIN azkar_animations a ON a.key = m.anim_key
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- 4. Verify ---------------------------------------------------------------
SELECT
  ai.id      AS azkar_id,
  ai.title,
  a.key      AS animation_key,
  aia.sort_order
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.category_id = 'duas_after_salah'
ORDER BY ai.sort_order, aia.sort_order;

COMMIT;
