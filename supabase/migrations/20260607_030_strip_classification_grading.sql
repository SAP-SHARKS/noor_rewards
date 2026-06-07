-- =============================================================================
-- 20260607_030_strip_classification_grading
--
-- Strips hadith-classification / grading sentences from reward text.
-- These are scholarly authentication notes (e.g. "Classed as sahih by
-- an-Nawawi in al-Adhkar P. 111") — they belong in a reference / sanad
-- section, not in the Benefit displayed to the user.
--
-- Item that prompted this: sleep_before_016 ended with
--   "…lay down this dua. Classed as sahih by an-Nawawi in al-Adhkar
--    P. 111 and by Ibn Hajar in Nataij al-Afkar 2/384."
--
-- Pass 070 already handled the "by Shaykh al-Albani" variant. This pass
-- broadens the regex to catch:
--   • "Classed as sahih / hasan / da'if by …"  (anyone, not just Albani)
--   • "Graded as sahih by …"
--   • "Authenticated by …"
--   • The trailing book references inside those notes
--     (al-Adhkar, Nataij al-Afkar, Silsilat al-Ahadith, etc.)
-- =============================================================================

BEGIN;

-- "Classed as <grade> by …" — strip from "Classed" through the next period
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Classed\s+as\s+(?:sahih|hasan|da[''i]?f|weak)[^.]*\.',
  '', 'gi'
);

-- "Graded as <grade> by …"
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Graded\s+as\s+(?:sahih|hasan|da[''i]?f|weak)[^.]*\.',
  '', 'gi'
);

-- "Authenticated by …"
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Authenticated\s+by[^.]*\.',
  '', 'gi'
);

-- "Sahih according to …"
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '(?:^|\s)Sahih\s+according\s+to[^.]*\.',
  '', 'gi'
);

-- Final whitespace + trailing-punctuation cleanup
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '^[\s,.;]+', '', 'g');


-- Verify the trigger row + show any other rows that still contain
-- classification language we may need to clean in a follow-up.
SELECT id, title, reward
FROM azkar_items
WHERE id = 'sleep_before_016';

SELECT id, title, reward
FROM azkar_items
WHERE reward ~* '(Classed\s+as|Graded\s+as|Authenticated\s+by|Sahih\s+according\s+to)';

COMMIT;
