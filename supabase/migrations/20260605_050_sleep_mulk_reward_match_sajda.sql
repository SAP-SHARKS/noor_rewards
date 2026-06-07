-- =============================================================================
-- 20260605_050_sleep_mulk_reward_match_sajda
--
-- Per user direction: the benefit text shown under sleep_before_020
-- (Surah Al-Mulk) should match the one used for sleep_before_019
-- (Surah As-Sajdah). Both surahs are sourced from the same Jabir (RA)
-- hadith (Tirmidhi 3404) — the Prophet ﷺ would not sleep until he had
-- recited both Tanzeel as-Sajdah AND Tabarak — so using the same reward
-- phrasing is also textually accurate.
--
-- Updates `azkar_items.reward` for sleep_before_020 to mirror 019, and
-- aligns the `reference` to cite Tirmidhi 3404 (the same hadith) while
-- keeping the surah identifier as Al-Mulk.
--
-- Idempotent: re-runnable.
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET
  reward    = 'Jabir (RA) said: The Prophet ﷺ would not sleep until he recited Tanzeel as-Sajdah (Surah As-Sajdah) and Tabarak (Surah Al-Mulk).',
  reference = 'Surah Al-Mulk (Qur''an 67) | Jami at-Tirmidhi 3404'
WHERE id = 'sleep_before_020';

-- Verify
SELECT id, title, reward, reference
FROM azkar_items
WHERE id IN ('sleep_before_019', 'sleep_before_020')
ORDER BY id;

COMMIT;
