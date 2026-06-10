-- =============================================================================
-- 20260608_030_ruquiya_001_cleanup
--
-- Strips the editor prefix "COMPILATION — multiple duas." and the inline
-- "(Sahih al-Bukhari 3371)" / "(Sunan Abi Dawud 3898)" / similar English
-- reference markers from ruquiya_001's arabic field. Keeps the six
-- numbered Arabic duas so the card reads as a clean list.
--
-- The translation field is already clean (English translations separated
-- by " — ") and the reference field stays as-is.
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET arabic = '(1) اُعِيْذُكُمَا بِكَلِمَاتِ اللهِ التَّآمَّةِ، مِنْ كُلِّ شَيْطَانٍ وَّهَامَّةٍ، وَمِنْ كُلِّ عَيْنٍ لَّآمَّةٍ
(2) اُعِيْذُ بِكَلِمَاتِ اللهِ التَّآمَّاتِ مِنْ شَرِّ مَا خَلَقَ
(3) بِسْمِ اللهِ الَّذِىْ لَا يَضُرُّ مَعَ اسْمِهٖ شَىْءٌ فِى الْاَرْضِ وَلَا فِى السَّمَآءِ، وَهُوَ السَّمِيْعُ الْعَلِيْمُ
(4) رَبَّنَا هَبْ لَنَا مِنْ اَزْوَاجِنَا وَذُرِّيّٰتِنَا قُرَّةَ اَعْيُنٍ وَّاجْعَلْنَا لِلْمُتَّقِيْنَ اِمَامًا
(5) بِسْمِ اللهِ، بِسْمِ اللهِ، بِسْمِ اللهِ
(6) بِسْمِ اللهِ تَوَكَّلْتُ عَلَى اللهِ، وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللهِ'
WHERE id = 'ruquiya_001';

-- Verify
SELECT id, title, arabic, translation FROM azkar_items WHERE id = 'ruquiya_001';

COMMIT;
