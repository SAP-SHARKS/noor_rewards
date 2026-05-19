-- ════════════════════════════════════════════════════════════════════════════
-- Auto-advance delay — per azkar TYPE (not per category)
--
-- The auto-advance delay (app_config.dhikr_advance_delay_seconds) holds a
-- completed dhikr before sliding to the next. There are two azkar types:
--   • single-read  — counter target of 1, read once and done
--   • multi-count  — a dhikr counter, e.g. SubhanAllah x33
--
-- These two boolean flags turn the delay on/off independently per type.
-- They appear as toggles on the admin Feature Flags page.
--   true  = the global delay applies to that type
--   false = that type always advances instantly
--
-- Defaults are 'true' so behavior is unchanged until an admin flips a toggle.
--
-- Run this in the Supabase SQL Editor.
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO app_config (key, value, description) VALUES
  ('dhikr_delay_single_read', 'true',
   'Apply the auto-advance delay to single-read azkar (counter target of 1). false = advance instantly.'),
  ('dhikr_delay_multi_count', 'true',
   'Apply the auto-advance delay to multi-count azkar (a dhikr counter). false = advance instantly.')
ON CONFLICT (key) DO NOTHING;

-- ── Cleanup ──────────────────────────────────────────────────────────────────
-- Drops the abandoned per-category column from the earlier (incorrect)
-- approach. Safe to run whether or not that migration was ever applied.
ALTER TABLE azkar_categories DROP COLUMN IF EXISTS auto_advance_delay;

-- Verify
SELECT key, value, description FROM app_config
WHERE key IN ('dhikr_delay_single_read', 'dhikr_delay_multi_count');
