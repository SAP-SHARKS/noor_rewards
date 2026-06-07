-- =============================================================================
-- 20260605_010_azkar_animation_pool_audit
--
-- Corrective audit of `azkar_item_animations` for non-Morning/Evening
-- categories. The original pool migration (20260604_050) over-eagerly
-- borrowed illustrations whose meaning did not match the azkar's
-- recitation or hadith benefit. This migration fixes the clear mismatches
-- and removes illustrations entirely for azkar with no thematic match in
-- the Morning/Evening artwork catalog. The card's `hasIllustration` gate
-- (in Dart) skips the 260px block when no animation is mapped.
--
-- Selection rule (per user direction): Morning/Evening illustrations are
-- the only valid source pool. An illustration may be assigned to a
-- non-M/E azkar only if EITHER (a) the Arabic recitation is the same OR
-- (b) the hadith benefit text in the reward section describes the same
-- outcome. Anything outside that — leave empty (no illustration).
--
-- Idempotent: each azkar's existing mappings are wiped first, then the
-- corrected set is inserted. Safe to re-run.
-- =============================================================================

BEGIN;

-- 1. Wipe existing mappings for every azkar we touch in this audit ---------
DELETE FROM azkar_item_animations
WHERE azkar_id IN (
  -- Duas before Sleep
  'sleep_before_001', 'sleep_before_004', 'sleep_before_006',
  'sleep_before_007', 'sleep_before_008', 'sleep_before_019',
  'sleep_before_020',
  -- Duas after Salah
  'salah_after_006', 'salah_after_008', 'salah_after_009',
  'salah_after_011', 'salah_after_012', 'salah_after_013',
  'salah_after_014',
  -- Daily Duas
  'daily_dua_021',
  -- Remembrance of Allah
  'dhikr_030', 'dhikr_031'
);

-- 2. Re-insert ONLY the corrected mappings --------------------------------
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, m.sort_order
FROM (VALUES
  -- ── Duas before Sleep ───────────────────────────────────────────────────

  -- sleep_before_001: Tasbih Fatima (Subhanallah x33, Alhamdulillah x33,
  -- Allahu Akbar x34). The three phrases are exactly what `glory` (the
  -- subhanallah/alhamdulillah/allahu akbar tasbih illustration) was built
  -- to depict. Previous mapping (`heavy_scales` = cosmic weight) was
  -- about a different phrase ("adada khalqih"), not this tasbih.
  ('sleep_before_001', 'glory', 0),

  -- sleep_before_004: Surah An-Nas (the 3rd blowing-into-palms recitation).
  -- `three_quls` covers it as part of the three-Quls group; `falaq_shield`
  -- also fits because that illustration depicts the Mu'awwidhatayn
  -- (Falaq+Nas) protection. Pool size 2 → daily rotation.
  ('sleep_before_004', 'three_quls',   0),
  ('sleep_before_004', 'falaq_shield', 1),

  -- sleep_before_006: Al-Baqarah 2:285. The "last two verses of Baqarah"
  -- hadith (Bukhari 5040 = same hadith referenced by morning_7/evening_7
  -- via Bukhari 4008) — both 285 and 286 share the "they will suffice
  -- him" benefit. `benefit_text_7` is the dedicated text illustration
  -- for that hadith. Previous `baqarah_shield` was for the OPENING
  -- verses of Baqarah, not the closing two — meaning mismatch.
  ('sleep_before_006', 'benefit_text_7', 0),

  -- sleep_before_007: Al-Baqarah 2:286 (companion verse to 285, same
  -- hadith). `baqarah_burden` is the dedicated illustration for 2:286
  -- ("Allah burdens no soul beyond its capacity"). Also add
  -- `benefit_text_7` because of the shared "they will suffice him"
  -- hadith — gives a rotation pool of two thematically correct options.
  ('sleep_before_007', 'baqarah_burden', 0),
  ('sleep_before_007', 'benefit_text_7', 1),

  -- sleep_before_008 (Surah Al-Kafirun): NO mapping. The Kafirun-before-
  -- sleep hadith (Abu Dawud 5055 — "declaration of freedom from
  -- polytheism") has no thematic counterpart in the Morning/Evening
  -- artwork catalog. The previous `quran_complete` was the "Ikhlas 3× =
  -- whole Quran reward" illustration, which has no relation to Kafirun
  -- whatsoever. Leave empty per the audit rule.

  -- sleep_before_019 (Surah As-Sajda before sleep): keep `night_peace`
  -- (general sleep theme). Remove `quran_complete` — As-Sajda is not
  -- one of the three Quls, and the "= whole Quran" reward only applies
  -- to Ikhlas. The mapping was a false thematic borrow.
  ('sleep_before_019', 'night_peace', 0),

  -- sleep_before_020 (Surah Al-Mulk before sleep): keep `night_peace`.
  -- Same rationale as 019 — Al-Mulk has its own merit (intercession),
  -- which is not what `quran_complete` depicts.
  ('sleep_before_020', 'night_peace', 0),

  -- ── Duas after Salah ──────────────────────────────────────────────────

  -- salah_after_006 (Tasbih 33+33+33 + 1× tahlil): keep `scales`
  -- (matches the closing "La ilaha illallahu wahdahu..." kalimah which
  -- is the unparalleled-reward phrase). Drop `heavy_scales` — that's
  -- specifically for "adada khalqih", not this tasbih.
  ('salah_after_006', 'scales', 0),

  -- salah_after_008 (After Fajr only — "knowledge / sustenance / deeds"
  -- dua, Ibn Majah 925): NO mapping. `flame` (freed-from-Hellfire) was
  -- unrelated. No M/E illustration matches "beneficial knowledge +
  -- goodly provision + acceptable deeds" — leave empty.

  -- salah_after_009 (Ayatul Kursi after every Fard): the recitation IS
  -- Ayat al-Kursi → use `shield` (the dedicated Ayat al-Kursi
  -- illustration). Previous `dua_hands` was a generic placeholder.
  ('salah_after_009', 'shield', 0),

  -- salah_after_011 (Surah Al-Falaq 3× after Fajr/Maghrib): `three_quls`
  -- and `falaq_shield` both match (recitation IS Falaq, and falaq_shield
  -- depicts Falaq+Nas protection). Drop `quran_complete` — the "whole
  -- Quran reward" only applies when Ikhlas+Falaq+Nas are recited
  -- together, not Falaq alone.
  ('salah_after_011', 'three_quls',   0),
  ('salah_after_011', 'falaq_shield', 1),

  -- salah_after_012 (Surah An-Nas 3× after Fajr/Maghrib): same as 011.
  ('salah_after_012', 'three_quls',   0),
  ('salah_after_012', 'falaq_shield', 1),

  -- salah_after_013 ("La ilaha illallahu wahdahu la sharika lahu..."
  -- after Fard, Bukhari 6330): this is the unparalleled-kalimah phrase
  -- depicted by `scales` (morning_31 / evening_30). Previous `dua_hands`
  -- was generic.
  ('salah_after_013', 'scales', 0),

  -- salah_after_014 (Durood Ibrahim before personal du'a): `salawat_intercession`
  -- is the dedicated Durood illustration (morning_33 / evening_32).
  ('salah_after_014', 'salawat_intercession', 0),

  -- ── Daily Duas ────────────────────────────────────────────────────────

  -- daily_dua_021 (When Sneezing — "Alhamdulillah"): NO mapping. `ocean`
  -- is specifically for "Subhanallahi wa bihamdihi" (morning_32 /
  -- evening_31). "Alhamdulillah" alone after a sneeze doesn't match the
  -- ocean-of-forgiveness hadith. Leave empty.

  -- ── Remembrance of Allah ──────────────────────────────────────────────

  -- dhikr_030 ("La hawla wa la quwwata illa billah"): NO mapping. The
  -- "Treasure of Paradise" hadith (Bukhari 4205) for La hawla has no
  -- M/E illustration. Previous `pillars` was for Hasbiyallahu (a
  -- different phrase). Leave empty.

  -- dhikr_031 ("Subhanallah, Alhamdulillah, La ilaha illallah, Allahu
  -- Akbar" — the four most beloved words / tree-planting phrases):
  -- map to `glory` since glory depicts the SubhanAllah/Alhamdulillah/
  -- AllahuAkbar tasbih. Previous `heavy_scales` was for "adada khalqih".
  ('dhikr_031', 'glory', 0)
) AS m(azkar_id, anim_key, sort_order)
JOIN azkar_animations a ON a.key = m.anim_key
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- 3. Verify ----------------------------------------------------------------
-- For each azkar touched, show how many animations it now has. Items with
-- zero rows are intentionally without an illustration.
SELECT
  ai.id            AS azkar_id,
  ai.title,
  ai.category_id,
  COUNT(aia.animation_id) AS animation_count
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
WHERE ai.id IN (
  'sleep_before_001', 'sleep_before_004', 'sleep_before_006',
  'sleep_before_007', 'sleep_before_008', 'sleep_before_019',
  'sleep_before_020',
  'salah_after_006', 'salah_after_008', 'salah_after_009',
  'salah_after_011', 'salah_after_012', 'salah_after_013',
  'salah_after_014',
  'daily_dua_021',
  'dhikr_030', 'dhikr_031'
)
GROUP BY ai.id, ai.title, ai.category_id
ORDER BY ai.category_id, ai.id;

COMMIT;
