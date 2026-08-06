-- Reword validate_seeds + project_funded notifications
--
-- Prior wording used "donate", "fund", "contribution", "real projects",
-- "real lives changed" — which read like the app was asking users for
-- real money. Sabiq's Seeds are an in-app reward earned through worship
-- and "donating" them to a Cause is virtual (they move within the app).
-- This migration replaces the money-adjacent language with sowing /
-- planting metaphors that stay consistent with the Seeds theme.
--
-- Uses UPDATE (not DELETE+INSERT) because notification_log.variant_id
-- has a foreign key on notification_variants.id. Rows are matched by
-- their prior title.
--
-- English-only rewrite. Non-English translations for project_funded
-- (ur, ar, fr, id, ms, ru, tr in 20260708_050) still use "sadaqah",
-- "fund", "contribute" in their respective languages — revisit if the
-- user reports the same confusion in those locales.

BEGIN;

-- ── validate_seeds (EN) ────────────────────────────────────────────────
UPDATE public.notification_variants
   SET body = 'Direct your Sabiq Seeds toward a Cause — orphans, masjids, free meals. Every Seed you sow becomes a good deed in shaa Allah.'
 WHERE notification_type = 'validate_seeds' AND locale = 'en'
   AND title = 'Your Seeds are growing';

UPDATE public.notification_variants
   SET body = 'You''ve earned good Seeds. Sow them into a Cause and multiply your rewards in shaa Allah.'
 WHERE notification_type = 'validate_seeds' AND locale = 'en'
   AND title = 'Plant your harvest';

UPDATE public.notification_variants
   SET body = 'Your Seeds are waiting to grow. Pick a Cause and sow them — small deeds add up quickly.'
 WHERE notification_type = 'validate_seeds' AND locale = 'en'
   AND title = 'Don''t let them sit';

UPDATE public.notification_variants
   SET body = 'Your worship earned these Seeds. Sow them into a Cause and water what you planted.'
 WHERE notification_type = 'validate_seeds' AND locale = 'en'
   AND title = 'Make them count';

UPDATE public.notification_variants
   SET title = 'A Cause awaits',
       body  = 'A Sabiq Cause is open for your Seeds. Every Seed you sow keeps growing on Yawm al-Qiyamah.'
 WHERE notification_type = 'validate_seeds' AND locale = 'en'
   AND title = 'A Cause needs you';

-- ── project_funded (EN) ────────────────────────────────────────────────
UPDATE public.notification_variants
   SET body = 'A Cause you supported just reached its goal — your Seeds are written for you as barakah. Tap to see the impact.'
 WHERE notification_type = 'project_funded' AND locale = 'en'
   AND title = 'Your Seeds bore fruit';

UPDATE public.notification_variants
   SET title = 'A Cause you supported is complete'
 WHERE notification_type = 'project_funded' AND locale = 'en'
   AND title = 'A project you funded is complete';

UPDATE public.notification_variants
   SET title = 'Cause completed',
       body  = 'A Cause you sowed into has fully bloomed. Your worship helped make it happen.'
 WHERE notification_type = 'project_funded' AND locale = 'en'
   AND title = 'Sadaqah delivered';

UPDATE public.notification_variants
   SET body = '"{projectName}" reached its target. Every Seed you sowed is now flowing as continuous reward in shaa Allah.'
 WHERE notification_type = 'project_funded' AND locale = 'en'
   AND title = 'Goal reached, MashaAllah';

UPDATE public.notification_variants
   SET body = 'A community Cause you supported has bloomed. Your name is among those who made it happen.'
 WHERE notification_type = 'project_funded' AND locale = 'en'
   AND title = 'Your share of the reward';

COMMIT;
