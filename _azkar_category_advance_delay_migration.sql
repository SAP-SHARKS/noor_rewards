-- ════════════════════════════════════════════════════════════════════════════
-- Azkar category — per-category auto-advance delay toggle
--
-- The auto-advance delay (app_config.dhikr_advance_delay_seconds) holds a
-- completed dhikr on screen before sliding to the next one. Single-read
-- azkar (marked done once) feel better advancing instantly, while
-- repeated-count azkar can benefit from the dwell. This flag lets the
-- admin enable/disable the delay per category.
--
--   auto_advance_delay = true  → the global delay applies to this category
--   auto_advance_delay = false → this category always advances instantly
--
-- Run this in the Supabase SQL Editor.
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE azkar_categories
  ADD COLUMN IF NOT EXISTS auto_advance_delay BOOLEAN DEFAULT true;

-- Existing categories keep current behavior (the global delay applies).
UPDATE azkar_categories
SET auto_advance_delay = true
WHERE auto_advance_delay IS NULL;

-- Verify
SELECT id, label, sort_order, is_visible, auto_advance_delay
FROM azkar_categories
ORDER BY sort_order;
