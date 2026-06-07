-- =============================================================================
-- 20260605_080_cleanup_reward_artifacts_pass3
--
-- Third-pass cleanup of `azkar_items.reward`. Handles the remaining
-- artifacts surfaced by the diagnostic after pass 1 (060) and pass 2
-- (070):
--
--   1. Trailing Quran citations like "(2:152)", "(8:9)", or
--      "(Sura Al-Imran 3.173)" at the end of a reward. The Quran
--      identifier belongs in the Reference section, not the Benefit.
--      Affects: daily_dua_034, rabbana_003, rabbana_004, rabbana_010.
--
--   2. Orphan period after a closing-quote: `." . Word` → `." Word`.
--      This artifact appeared where a hadith citation between two
--      sentences was stripped by 060 but left its trailing period.
--      Affects: salah_after_010, salah_after_011.
--
--   3. Trailing unmatched double-quote at very end of string (only
--      when total `"` count is odd, so we never strip a valid close).
--      Affects: daily_dua_012, daily_dua_013, sleep_before_010.
--
-- Idempotent.
-- =============================================================================

BEGIN;

-- 1. Strip trailing Quran verse citation -----------------------------------
-- Matches "(2:152)", "(2.255)", "(Sura Al-Imran 3.173)", "(Surah 67:1)"
-- at the very end of the reward.
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\(\s*(?:Sura[h]?\s+[^)]*?|\d+[:\.]\d+)\s*\)\s*$',
  ''
);

-- 2. Collapse orphan period after closing-quote artifact -------------------
-- ." . Word  →  ." Word
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(\.")\s+\.\s+',
  '\1 ', 'g'
);

-- 3. Strip trailing UNMATCHED double-quote ---------------------------------
-- Only when the total " count is odd (so we never strip from a valid
-- balanced pair) AND the very last char is ". Removes just one " char.
UPDATE azkar_items
SET reward = substring(reward FROM 1 FOR length(reward) - 1)
WHERE reward IS NOT NULL
  AND right(reward, 1) = '"'
  AND (length(reward) - length(replace(reward, '"', ''))) % 2 = 1;

-- 4. Final whitespace + dangling-punctuation cleanup -----------------------
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '^[\s,.;]+', '', 'g');

-- 5. Verify each previously-flagged row ------------------------------------
SELECT id, title, reward, length(reward) AS len
FROM azkar_items
WHERE id IN (
  'daily_dua_012', 'daily_dua_013', 'daily_dua_034',
  'salah_after_010', 'salah_after_011', 'sleep_before_010',
  'rabbana_003', 'rabbana_004', 'rabbana_010'
)
ORDER BY id;

-- 6. Re-scan for anything else still looking incomplete --------------------
SELECT
  ai.id, ai.category_id, ai.title, ai.reward, length(ai.reward) AS len
FROM azkar_items ai
WHERE ai.category_id NOT IN ('morning', 'evening')
  AND ai.reward IS NOT NULL
  AND ai.reward != ''
  AND length(ai.reward) >= 80
  AND (
    ai.reward !~ '[.!?"'']\s*$'
    OR ai.reward LIKE '%()%'
    OR ai.reward LIKE '%...%'
  )
ORDER BY ai.category_id, ai.sort_order;

COMMIT;
