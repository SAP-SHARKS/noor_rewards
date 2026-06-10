-- =============================================================================
-- 20260607_120_fix_daily_042_translation
--
-- The previous "Visible end:" strip on daily_dua_042 consumed the
-- annotation AND the elided text marker AND swallowed the first half of
-- the actual translation, leaving it starting mid-sentence with
-- "death, He is Living...". Restore the complete translation matching
-- the Arabic, and clean up the reward to be a single benefit sentence.
--
-- Arabic for daily_dua_042 (Entering the Market):
--   "لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ
--    وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ حَيٌّ لَا يَمُوتُ،
--    بِيَدِهِ الْخَيْرُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ"
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET translation = 'There is no god but Allah, alone with no partner. To Him belongs all dominion and to Him belongs all praise. He gives life and causes death. He is Living and does not die. In His Hand is all good, and He is over all things able.'
WHERE id = 'daily_dua_042';

-- Verify
SELECT id, title, arabic, translation, transliteration, reward
FROM azkar_items
WHERE id = 'daily_dua_042';

COMMIT;
