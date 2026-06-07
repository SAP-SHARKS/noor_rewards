-- =============================================================================
-- 20260605_100_fix_quote_period_artifact
--
-- One last cleanup. The artifact `." . Word` (period + closing-quote +
-- orphan period + space + next word) was already handled in pass 080,
-- but a tighter variant `.". Word` (period + closing-quote + orphan
-- period with no whitespace between them) slipped through because the
-- regex required at least one whitespace char between the close-quote
-- and the orphan period.
--
-- Affected rows include `salah_after_009` (`death."". Also …`) and
-- multiple spots inside `salah_after_014` (a multi-hadith reward).
--
-- This pass uses `\s*` (zero or more whitespace) instead of `\s+`, so it
-- collapses both variants and leaves a single space between the
-- closing-quoted sentence and the next sentence. Idempotent.
-- =============================================================================

BEGIN;

-- Collapse `." . Word` / `.". Word` / `."  . Word` → `." Word`
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\."\s*\.\s+',
  '." ', 'g'
);

-- Same fix for the single-quote variant: .'. Word → .' Word
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\.''\s*\.\s+',
  '.'' ', 'g'
);

-- Whitespace cleanup
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');

-- Verify the two known-problem rows
SELECT id, title, reward, length(reward) AS len
FROM azkar_items
WHERE id IN ('salah_after_009', 'salah_after_014')
ORDER BY id;

COMMIT;
