-- =============================================================================
-- 20260607_040_strip_grading_continuation
--
-- Follow-up to 030. The "Classed as sahih …" strip in 030 used
-- `[^.]*\.` which stops at the FIRST period inside the grading note.
-- For sleep_before_016 the source text was:
--
--   "Classed as sahih by an-Nawawi in al-Adhkar P. 111 and by Ibn
--    Hajar in Nataij al-Afkar 2/384."
--
-- so the `P.` page-abbreviation period halted the match, stripping only
-- the first half ("Classed as … al-Adhkar P.") and leaving the orphan
-- continuation " 111 and by Ibn Hajar in Nataij al-Afkar 2/384." behind.
--
-- This pass:
--   1. Strips any remaining "<digits> and by <scholar>…" tails.
--   2. Re-strips full "Classed as / Graded as / Authenticated by"
--      sentences using `.*$` (everything to end of string) so the
--      embedded `P. ###` page-numbers no longer break the match.
-- =============================================================================

BEGIN;

-- 1. Strip orphan continuation: " <digits> and by <scholar> in <book> #/###."
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+\d+\s+and\s+by\s+(?:Ibn|an-|al-|Shaykh|Imam)[^.]*\.',
  '', 'gi'
);

-- 2. Re-strip full classification sentences from any rows that still
-- contain them, this time greedy-to-end so embedded "P. ###" doesn't
-- prematurely close the match.
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Classed\s+as\s+(?:sahih|hasan|da[''i]?f|weak).*$',
  '', 'gi'
);
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Graded\s+as\s+(?:sahih|hasan|da[''i]?f|weak).*$',
  '', 'gi'
);
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Authenticated\s+by.*$',
  '', 'gi'
);

-- Whitespace + trailing-punctuation cleanup
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');

-- Verify the trigger row + scan for anything still classification-flavored
SELECT id, title, reward FROM azkar_items WHERE id = 'sleep_before_016';

SELECT id, title, reward
FROM azkar_items
WHERE reward ~* '(Classed\s+as|Graded\s+as|Authenticated\s+by|in\s+al-Adhkar|Nataij\s+al-Afkar|Silsilat\s+al-Ahadith)';

COMMIT;
