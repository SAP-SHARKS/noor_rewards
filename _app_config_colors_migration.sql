-- Add screen-specific color keys to app_config
-- Run this in Supabase SQL Editor
-- These use ARGB hex format (e.g., FF0D9488 = fully opaque teal)

INSERT INTO app_config (key, value) VALUES
  ('azkar_accent',        'FF0D9488'),
  ('azkar_morning_grad1', 'FF0C4A3E'),
  ('azkar_morning_grad2', 'FF0D9488'),
  ('azkar_evening_grad1', 'FF1E1B4B'),
  ('azkar_evening_grad2', 'FF4338CA'),
  ('azkar_bottom_grad1',  'FF0A6B52'),
  ('azkar_bottom_grad2',  'FF0C4A3E'),
  ('azkar_highlight',     'FF1A7A5C'),
  ('quran_bg',            'FFEDF7F4'),
  ('quran_accent',        'FF2BAE99'),
  ('quran_gold',          'FFFFAA00'),
  ('quran_text',          'FF1C1C1E'),
  ('dash_bg',             'FFF7F3EE'),
  ('dash_text',           'FF1C1C1E'),
  ('dash_teal',           'FF2BAE99')
ON CONFLICT (key) DO NOTHING;

-- Verify
SELECT key, value FROM app_config WHERE key LIKE 'azkar_%' OR key LIKE 'quran_%' OR key LIKE 'dash_%' ORDER BY key;
