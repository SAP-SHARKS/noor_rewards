-- =============================================================================
-- 20260605_070_cleanup_reward_artifacts
--
-- Second-pass cleanup of `azkar_items.reward` after the inline-reference
-- strip in 20260605_060. The first pass left a few visible artifacts:
--
--   1. Empty parens "()" where a parenthesised reference token was
--      removed (e.g. salah_after_007, daily_dua_027, daily_dua_033,
--      ruquiya_004, sleep_before_010).
--   2. Orphan trailing-quote sequences and stray periods between
--      sentences (salah_after_010, salah_after_011, daily_dua_012,
--      daily_dua_013).
--   3. Parenthesised sanad / grading notes that are reference info
--      duplicating the Reference section (daily_dua_039 — Shaykh
--      al-Albani / Shaikh Muqbil grading).
--   4. Editor meta-comments like "Same hadith chain as Al-Ikhlas."
--      (salah_after_011).
--
-- No content is rewritten — only reference / grading metadata is
-- removed, and dangling punctuation is collapsed. Idempotent.
-- =============================================================================

BEGIN;

-- 1. Strip the parenthesised grading / sanad notes that survived pass 1 ----
-- Albani grading
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\(\s*Shaykh\s+Al-Albani[^)]*\)',
  '', 'g'
);
-- Muqbil grading (sometimes appears together with the Albani note)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\(\s*Shaikh\s+Muqbil[^)]*\)',
  '', 'g'
);
-- Generic "(Classed as sahih …)" style notes
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\(\s*Classed\s+as\s+sahih[^)]*\)',
  '', 'g'
);
-- "Graded as sahih by …" sentences (no parens, sometimes mid-text)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Graded\s+as\s+sahih[^.]*\.',
  '', 'g'
);

-- 2. Strip editor meta-comments -----------------------------------------
-- "Same hadith chain as Al-Ikhlas." / "Same hadith chain as Al-Ikhlas /
-- Al-Falaq." — pure cross-reference, no benefit content.
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Same\s+hadith\s+chain\s+as[^.]*\.',
  '', 'g'
);

-- 3. Strip "Note: There is no specific virtue mentioned in the hadith for
-- reciting the 40 Rabbana Du''as." — duplicated across every rabbana_*
-- and not benefit content for any one of them.
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Note:\s*There\s+is\s+no\s+specific\s+virtue[^.]*\.',
  '', 'g'
);

-- 4. Remove empty parens "()" left by the previous reference strip ------
UPDATE azkar_items SET reward = regexp_replace(reward, '\s*\(\s*\)\s*', ' ', 'g');

-- 5. Collapse run-on / orphan punctuation ------------------------------
-- Triple+ double-quotes (CSV doubling artifact) → single quote
UPDATE azkar_items SET reward = regexp_replace(reward, '"{2,}', '"', 'g');
-- Stray ".  ." (period whitespace period) → "."
UPDATE azkar_items SET reward = regexp_replace(reward, '\.\s+\.', '.', 'g');
-- Space-period → period
UPDATE azkar_items SET reward = regexp_replace(reward, '\s+\.', '.', 'g');
-- Comma-period → period
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*\.', '.', 'g');
-- ", and ." / ", and ," cleanups
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*and\s*\.', '.', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*and\s*,', ',', 'g');
-- Double comma
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*,', ',', 'g');
-- Pipe artifacts left over
UPDATE azkar_items SET reward = regexp_replace(reward, '\s*\|\s*', ' ', 'g');
-- Collapse whitespace runs
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
-- Strip leading + trailing whitespace + dangling punctuation
UPDATE azkar_items SET reward = regexp_replace(reward, '^[\s,.;]+', '', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');

-- 6. Verify the previously-flagged rows are now clean ------------------
SELECT id, title, reward, length(reward) AS len
FROM azkar_items
WHERE id IN (
  'daily_dua_012', 'daily_dua_013', 'daily_dua_027', 'daily_dua_033',
  'daily_dua_034', 'daily_dua_039',
  'salah_after_007', 'salah_after_010', 'salah_after_011',
  'sleep_before_010', 'ruquiya_004'
)
ORDER BY id;

-- 7. Re-scan for any rows STILL looking incomplete (same heuristics as
-- the diagnostic). Anything that shows up here needs manual review with
-- the source screenshot.
SELECT
  ai.id, ai.category_id, ai.title, ai.reward, length(ai.reward) AS len
FROM azkar_items ai
WHERE ai.category_id NOT IN ('morning', 'evening')
  AND ai.reward IS NOT NULL
  AND ai.reward != ''
  AND length(ai.reward) >= 80  -- ignore short one-liners
  AND (
    ai.reward !~ '[.!?"'']\s*$'
    OR ai.reward LIKE '%()%'
    OR ai.reward LIKE '%...%'
    OR (length(ai.reward) - length(replace(ai.reward, '"', ''))) % 2 = 1
  )
ORDER BY ai.category_id, ai.sort_order;

COMMIT;
