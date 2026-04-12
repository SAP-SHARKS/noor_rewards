-- Add description column to community_projects if it doesn't exist
-- Run this in Supabase SQL Editor

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'community_projects' AND column_name = 'description'
  ) THEN
    ALTER TABLE community_projects ADD COLUMN description TEXT DEFAULT '';
  END IF;
END $$;

-- Verify
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'community_projects' ORDER BY ordinal_position;
