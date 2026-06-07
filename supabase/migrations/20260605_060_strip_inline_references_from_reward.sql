-- =============================================================================
-- 20260605_060_strip_inline_references_from_reward
--
-- The Benefit text shown under each azkar comes from `azkar_items.reward`.
-- The Reference heading directly below it comes from `azkar_items.reference`.
-- Many imported rewards repeat the hadith citation (e.g. "Sahih al-Bukhari
-- 5017") inline at the end — duplicating what the Reference section
-- already shows.
--
-- This migration strips those inline hadith citations out of `reward`,
-- then normalizes the resulting whitespace and punctuation. The
-- `reference` field is untouched. Common citation patterns covered:
--
--   • Sahih al-Bukhari / Sahih Bukhari ###
--   • Sahih Muslim ###  (incl. variants like 597a)
--   • Sunan Abi Dawud / Sunan Abu Dawud ###
--   • Sunan Ibn Majah ###
--   • Sunan an-Nasa'i  / Sunan an-Nasa'i al-Kubra (with optional "no.") ###
--   • Jami` at-Tirmidhi / Jami at-Tirmidhi ###
--   • Hisn al-Muslim ###
--   • Musnad Ahmad ###
--   • (al-)Tabarani (with optional "no.") ###
--
-- Trailing dangling punctuation / orphan "&" + number continuations
-- ("5015 & 5017") are also cleaned. Idempotent — re-runnable.
-- =============================================================================

BEGIN;

-- 1. Strip each citation pattern in turn. Each is global (`g` flag) so
-- inline references mid-paragraph are also removed, not just trailing.

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Sahih\s+(?:al-)?Bukhari\s+(?:no\.\s*)?\d+[a-z]?(?:\s*&\s*\d+[a-z]?)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Sahih\s+Muslim\s+(?:no\.\s*)?\d+[a-z]?(?:\s*&\s*\d+[a-z]?)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Sunan\s+Ab[iu]\s+Dawud\s+(?:no\.\s*)?\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Sunan\s+Ibn\s+Majah\s+(?:no\.\s*)?\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Sunan\s+an-Nasa''i(?:\s+al-Kubra)?(?:,?\s+no\.?)?\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Jami`?\s+at-Tirmidhi\s+(?:no\.\s*)?\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Hisn\s+al-Muslim\s+(?:no\.\s*)?\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  'Musnad\s+Ahmad\s+(?:no\.\s*)?\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:al-)?Tabarani(?:,?\s+no\.?)?\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);

-- 2. Cleanup: collapse the punctuation left behind by the removals.
-- E.g. "they will suffice you against everything.' Jami` at-Tirmidhi 3575."
-- after step 1 becomes "they will suffice you against everything.' ." —
-- this pass collapses the dangling ". ." and stray ", and" leftovers.

-- ", and ." → "."
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*and\s*\.', '.', 'g');
-- ", and ," → ","
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*and\s*,', ',', 'g');
-- Orphan ", ," → ","
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*,', ',', 'g');
-- " ." (space before period) → "."
UPDATE azkar_items SET reward = regexp_replace(reward, '\s+\.', '.', 'g');
-- ".." → "."
UPDATE azkar_items SET reward = regexp_replace(reward, '\.\s*\.', '.', 'g');
-- ", ." → "."
UPDATE azkar_items SET reward = regexp_replace(reward, ',\s*\.', '.', 'g');
-- Pipe-separator artifacts " | " → " "
UPDATE azkar_items SET reward = regexp_replace(reward, '\s*\|\s*', ' ', 'g');
-- Collapse runs of 2+ whitespace to single space
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
-- Trim leading/trailing whitespace + dangling punctuation
UPDATE azkar_items SET reward = regexp_replace(reward, '^[\s,.;]+', '', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');

-- 3. Verify: counts before/after; sample rows that still contain a
-- citation-looking token so we can spot regex gaps.
SELECT 'rows scanned' AS metric, COUNT(*) AS value FROM azkar_items;
SELECT 'rows still containing book name + digit' AS metric,
       COUNT(*) AS value
FROM azkar_items
WHERE reward ~* '(Bukhari|Muslim|Dawud|Tirmidhi|Nasa''i|Ibn Majah|Hisn|Tabarani|Ahmad)\s+(?:no\.\s*)?\d+';

-- Show any still-dirty rows so we can patch the regex in a follow-up
-- migration if needed.
SELECT id, title, reward
FROM azkar_items
WHERE reward ~* '(Bukhari|Muslim|Dawud|Tirmidhi|Nasa''i|Ibn Majah|Hisn|Tabarani|Ahmad)\s+(?:no\.\s*)?\d+'
ORDER BY id
LIMIT 30;

COMMIT;
