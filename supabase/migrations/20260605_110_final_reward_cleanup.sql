-- =============================================================================
-- 20260605_110_final_reward_cleanup
--
-- Final sweep of `azkar_items.reward`. The thorough diagnostic surfaced
-- three categories of remaining issues:
--
--   1. Editor TODO / capture markers left in the imported data:
--        • ruquiya_001 starts with "INCOMPLETE-COMPILATION — "
--        • daily_dua_042 starts with "Note (visible bottom only — top
--          scrolled off):" (a screenshot-capture annotation)
--   2. A genuine mid-sentence truncation:
--        • ruquiya_003 ends with "...when affected by magic —."
--   3. Bare hadith-book references that pass 060 missed because they
--      lacked the "Sahih"/"Sunan" prefix:
--        • Al-Bukhari ###, Abu Dawud ###, At-Tirmidhi ###, Ahmad ###,
--          Ibn Majah ###, Sahih Al-Jaami ### (variants)
--        • Standalone book names with no number: Ad-Darimi,
--          Mustadrak Al-Hakim, Ibn al-Sunni
--      These appear mostly in the short morning_*/evening_* title-style
--      reward strings. Removing them leaves just the title (e.g.
--      "Ayatul Kursi Al-Bukhari 5010" → "Ayatul Kursi").
--
-- Idempotent — re-runnable.
-- =============================================================================

BEGIN;

-- 1. Editor TODO / capture markers ---------------------------------------
UPDATE azkar_items
SET reward = regexp_replace(reward, '^INCOMPLETE-COMPILATION\s*[—-]\s*', '', 'g')
WHERE reward LIKE 'INCOMPLETE-COMPILATION%';

UPDATE azkar_items
SET reward = regexp_replace(
  reward,
  '^Note\s*\(visible\s+bottom\s+only[^)]*\)\s*:\s*',
  '', 'g'
)
WHERE reward LIKE 'Note (visible bottom only%';

-- Also strip the trailing Albani grading note in daily_dua_042 that
-- survived because it used "no." instead of "no" before the number.
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*Classed\s+as\s+(?:Sahih|Hasan)\s+by\s+Shaykh\s+al-Albani[^.]*\.',
  '', 'g'
);


-- 2. Fix the mid-sentence em-dash truncation in ruquiya_003 ---------------
-- "...the three Quls (Al-Ikhlas, Al-Falaq, An-Naas) when affected by magic —."
-- → drop the trailing " —." (dash + period) so the sentence ends cleanly
-- after "magic".
UPDATE azkar_items
SET reward = regexp_replace(reward, '\s*[—–-]\s*\.\s*$', '.', '')
WHERE id = 'ruquiya_003';


-- 3. Bare hadith book references (no "Sahih"/"Sunan" prefix) -------------
-- Bukhari (handles "Al-Bukhari 5010" and "Al-Bukhari 6/530" and "& 5017")
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*Al-Bukhari\s+\d+(?:/\d+)?(?:\s*&\s*\d+(?:/\d+)?)*',
  '', 'g'
);
-- Abu Dawud
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*Abu\s+Dawud\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);
-- At-Tirmidhi
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*At-Tirmidhi\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);
-- Ahmad (just "Ahmad ####")
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\bAhmad\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);
-- Ibn Majah (standalone, no Sunan prefix)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\bIbn\s+Majah\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);
-- Sahih Al-Jaami (variant of Albani collection)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*Sahih\s+Al-Jaami\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

-- Standalone book names without numbers (appear as title suffix)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\bAd-Darimi\b',
  '', 'g'
);
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\bMustadrak\s+Al-Hakim\b',
  '', 'g'
);
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\bIbn\s+al-Sunni\b',
  '', 'g'
);


-- 4. Final cleanup -------------------------------------------------------
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '^[\s,.;]+', '', 'g');


-- 5. Verify --------------------------------------------------------------
-- The 3 specifically targeted rows:
SELECT id, title, reward, length(reward) AS len
FROM azkar_items
WHERE id IN ('ruquiya_001', 'ruquiya_003', 'daily_dua_042')
ORDER BY id;

-- Sample of M/E rows post-cleanup so you can spot-check the bare-ref strip
SELECT id, reward FROM azkar_items
WHERE id IN ('evening_3', 'evening_9', 'evening_10', 'evening_13',
             'morning_3', 'morning_9', 'morning_13', 'evening_26')
ORDER BY id;

-- Final scan for any rows still containing book-name + digit patterns
SELECT id, title, reward
FROM azkar_items
WHERE reward ~* '\b(Bukhari|Muslim|Dawud|Tirmidhi|Nasa''i|Ibn Majah|Hisn|Tabarani|Ahmad|Al-Jaami|Albani)\s+\d+'
ORDER BY id;

COMMIT;
