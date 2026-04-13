-- Add is_visible column to azkar_categories
-- Run in Supabase SQL Editor

ALTER TABLE azkar_categories ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT true;

-- Set all existing categories to visible
UPDATE azkar_categories SET is_visible = true WHERE is_visible IS NULL;

-- Verify
SELECT id, label, sort_order, is_visible FROM azkar_categories ORDER BY sort_order;
