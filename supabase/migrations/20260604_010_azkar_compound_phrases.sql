-- =============================================================================
-- 20260604_010_azkar_compound_phrases
--
-- Adds support for compound dhikr (multi-phrase tasbih) where each phrase
-- has its own count. Affects 3 rows imported from screenshots that had
-- count markers like (x33) (x34) embedded inline in the Arabic field:
--
--   sleep_before_001  Tasbih Fatima        (33 + 33 + 34)
--   salah_after_006   33-Tahlil pattern    (33 + 33 + 33 + 1)
--   daily_dua_020     Return From Journey  (3 + 1)
--
-- After this migration:
--   - Arabic field of those rows contains ONLY pure Arabic (no count marks).
--   - New JSONB `phrases` column holds the structured segment list.
--   - All other azkar rows are untouched.
--
-- Flutter counter UI should branch on phrases IS NOT NULL: render segmented
-- counter with phrase transitions; otherwise render the existing single-count
-- counter.
-- =============================================================================

BEGIN;

-- 1. Schema -----------------------------------------------------------------
ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS phrases JSONB;

COMMENT ON COLUMN azkar_items.phrases IS
  'Optional segmented-counter structure for compound dhikr. NULL = single-count azkar (use recommended_count). Non-null = array of {arabic, transliteration, translation, count} objects rendered as a segmented counter with phrase transitions.';

-- 2. Tasbih Fatima (Sleep #1) -----------------------------------------------
UPDATE azkar_items
SET
  arabic = E'سُبْحَانَ اللهِ اَلْحَمْدُ لِلهِ اَللهُ اَكْبَرُ',
  phrases = '[
    {"arabic": "سُبْحَانَ اللهِ", "transliteration": "Subhan Allah",    "translation": "Glory be to Allah",       "count": 33},
    {"arabic": "اَلْحَمْدُ لِلهِ", "transliteration": "Alhamdulillah",   "translation": "All praise is for Allah", "count": 33},
    {"arabic": "اَللهُ اَكْبَرُ",   "transliteration": "Allahu Akbar",   "translation": "Allah is the Greatest",   "count": 34}
  ]'::jsonb
WHERE id = 'sleep_before_001';

-- 3. Salah #6 — 33-tahlil pattern -------------------------------------------
UPDATE azkar_items
SET
  arabic = 'سُبْحَانَ اللهِ اَلْحَمْدُ لِلّٰهِ اَللّٰهُ اَكْبَرُ لَا اِلٰهَ اِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَىْءٍ قَدِيْرٌ',
  phrases = '[
    {"arabic": "سُبْحَانَ اللهِ", "transliteration": "Subhan Allah",    "translation": "Glory be to Allah",       "count": 33},
    {"arabic": "اَلْحَمْدُ لِلّٰهِ", "transliteration": "Alhamdulillah",  "translation": "All praise is for Allah", "count": 33},
    {"arabic": "اَللّٰهُ اَكْبَرُ",  "transliteration": "Allahu Akbar",   "translation": "Allah is the Greatest",   "count": 33},
    {"arabic": "لَا اِلٰهَ اِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَىْءٍ قَدِيْرٌ", "transliteration": "La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa huwa ''ala kulli shay''in qadeer", "translation": "There is no god but Allah, alone, without partner; to Him belongs all sovereignty and praise, and He is over all things omnipotent.", "count": 1}
  ]'::jsonb
WHERE id = 'salah_after_006';

-- 4. Return From Journey (Daily #20) ----------------------------------------
-- Total count = 4 (3 takbirs + 1 long dua). Originally imported as 1.
UPDATE azkar_items
SET
  recommended_count = 4,
  recommended_count_label = '3+1',
  arabic = 'اَللهُ اَكْبَرُ سُبْحَانَ الَّذِىْ سَخَّرَ لَنَا هٰذَا وَمَا كُنَّا لَهٗ مُقْرِنِيْنَ، وَاِنَّاۤ اِلٰى رَبِّنَا لَمُنْقَلِبُوْنَ. اَللّٰهُمَّ اِنَّا نَسْاَلُكَ فِىْ سَفَرِنَا هٰذَا الْبِرَّ وَالتَّقْوٰى، وَمِنَ الْعَمَلِ مَا تَرْضٰى، اَللّٰهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هٰذَا وَاطْوِ عَنَّا بُعْدَهٗ، اَللّٰهُمَّ اَنْتَ الصَّاحِبُ فِى السَّفَرِ، وَالْخَلِيْفَةُ فِى الْاَهْلِ، اَللّٰهُمَّ اِنِّيْۤ اَعُوْذُ بِكَ مِنْ وَّعْثَآءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوْٓءِ الْمُنْقَلَبِ فِى الْمَالِ وَالْاَهْلِ. اٰئِبُوْنَ، تَآئِبُوْنَ، عَابِدُوْنَ، لِرَبِّنَا حَامِدُوْنَ',
  phrases = '[
    {"arabic": "اَللهُ اَكْبَرُ", "transliteration": "Allahu Akbar", "translation": "Allah is the Greatest", "count": 3},
    {"arabic": "سُبْحَانَ الَّذِىْ سَخَّرَ لَنَا هٰذَا وَمَا كُنَّا لَهٗ مُقْرِنِيْنَ، وَاِنَّاۤ اِلٰى رَبِّنَا لَمُنْقَلِبُوْنَ. اَللّٰهُمَّ اِنَّا نَسْاَلُكَ فِىْ سَفَرِنَا هٰذَا الْبِرَّ وَالتَّقْوٰى، وَمِنَ الْعَمَلِ مَا تَرْضٰى، اَللّٰهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هٰذَا وَاطْوِ عَنَّا بُعْدَهٗ، اَللّٰهُمَّ اَنْتَ الصَّاحِبُ فِى السَّفَرِ، وَالْخَلِيْفَةُ فِى الْاَهْلِ، اَللّٰهُمَّ اِنِّيْۤ اَعُوْذُ بِكَ مِنْ وَّعْثَآءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوْٓءِ الْمُنْقَلَبِ فِى الْمَالِ وَالْاَهْلِ. اٰئِبُوْنَ، تَآئِبُوْنَ، عَابِدُوْنَ، لِرَبِّنَا حَامِدُوْنَ",
     "transliteration": "Subhana lladhi sakhkhara lana hadha... Allahumma inna nasaluka fee safarina hadha... Aayiboon taaiboon aabidoon li-Rabbina haamidoon",
     "translation": "Glory is to Him Who has provided this for us... O Allah, we ask You on this journey for goodness and piety... We return repentant to our Lord, worshipping our Lord, and praising our Lord.",
     "count": 1}
  ]'::jsonb
WHERE id = 'daily_dua_020';

-- 5. Verify -----------------------------------------------------------------
SELECT id, title, recommended_count, recommended_count_label,
       jsonb_array_length(phrases) AS phrase_count
FROM azkar_items
WHERE phrases IS NOT NULL
ORDER BY id;

COMMIT;
