-- Rewrite pre-seeded akhirah_milestone push copy: "XP" → "Seeds".
--
-- The app doesn't expose "XP" anywhere in the UI (the currency is called
-- Sabiq Seeds). The seed data in 20260708_050 predates that convention and
-- was showing users notifications like "25,000 XP for your akhirah", which
-- looks like a bug in a Seeds-only app.
--
-- Swap is a literal token replacement so surrounding translations stay
-- intact. If a locale row was hand-edited post-seed with a different XP
-- variant, add it below. "Seeds" is left as a Latin-script brand token in
-- every locale — matches how the app renders Sabiq Seeds elsewhere.

UPDATE public.notification_variants
SET
  title = regexp_replace(title, 'XP', 'Seeds', 'g'),
  body  = regexp_replace(body,  'XP', 'Seeds', 'g')
WHERE notification_type = 'akhirah_milestone'
  AND (title LIKE '%XP%' OR body LIKE '%XP%');
