-- ─────────────────────────────────────────────────────────────────────────────
-- 20260630_020_more_notifications_v2.sql
--
-- Four more notification types:
--
--   • featured_dua          Hourly cron; fires at 13:00 local. Picks a random
--                           azkar with a non-empty `hadith_full` / `reward`
--                           and shows the benefit text as the body — turns
--                           the library into discoverable, motivating
--                           reminders.
--
--   • project_funded        Daily cron; finds community_projects that
--                           completed in the last 24h and notifies every
--                           donor that their Seeds funded a real outcome.
--
--   • akhirah_milestone     Daily cron; celebrates users whose total_xp
--                           just crossed a threshold (1k, 5k, 10k, 25k,
--                           50k, 100k, 250k, 500k, 1M).
--
--   • streak_milestone      Daily cron; celebrates users who hit day
--                           3 / 7 / 14 / 30 / 60 / 100 on any of the 3
--                           streaks (login / dhikr / quran).
--
-- All 4 functions honour the daily-cap and disengagement-pause helpers.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.notification_variants
  (notification_type, locale, title, body, route, image_url)
VALUES
  -- ── Featured du'a — only the TITLE is rotated. Body comes from the
  -- selected azkar's hadith_full / reward in the Edge Function so the
  -- benefit text is literal. ─────────────────────────────────────────────
  ('featured_dua', 'en',
   'Did you know?',
   'A timeless du''a from the Quran and Sunnah — tap to read.',
   'dhikr', NULL),
  ('featured_dua', 'en',
   'A hidden gem',
   'A short adhkar with a remarkable promise. Tap to read its benefit.',
   'dhikr', NULL),
  ('featured_dua', 'en',
   'From the bottom of the ocean',
   'A du''a so powerful it was answered from inside a whale. Worth one minute of your day.',
   'dhikr', NULL),
  ('featured_dua', 'en',
   'For when worry weighs you down',
   'The Prophet ﷺ taught this. It has lifted hearts for fourteen centuries.',
   'dhikr', NULL),
  ('featured_dua', 'en',
   'The promise behind these words',
   'Whoever recites this is promised reward most can only dream of. Read and reflect.',
   'dhikr', NULL),

  -- ── Project funded ─────────────────────────────────────────────────────
  ('project_funded', 'en',
   'Your Seeds bore fruit',
   'A project you supported just hit its goal — your contribution is now real-world barakah. Tap to see the impact.',
   'cause', NULL),
  ('project_funded', 'en',
   'A project you funded is complete',
   'Alhamdulillah — your Seeds helped finish "{projectName}". May Allah accept it from you.',
   'cause', NULL),
  ('project_funded', 'en',
   'Sadaqah delivered',
   'The cause you donated to has been fully funded. Real lives changed because of your worship.',
   'cause', NULL),
  ('project_funded', 'en',
   'Goal reached, MashaAllah',
   '"{projectName}" reached its target. Every Seed you gave is now flowing as sadaqah jariyah.',
   'cause', NULL),
  ('project_funded', 'en',
   'Your share of the reward',
   'A community project you backed is funded. Your name is among those who made it happen.',
   'cause', NULL),

  -- ── Akhirah milestone — uses {milestone} placeholder ───────────────────
  ('akhirah_milestone', 'en',
   'A milestone, alhamdulillah',
   'You''ve crossed {milestone} Sabiq Seeds. Keep planting — the harvest grows in the Akhirah.',
   'home', NULL),
  ('akhirah_milestone', 'en',
   'Your scale grows heavier',
   '{milestone} Seeds in your record. Every one of them is a witness for you on Yawm al-Qiyamah.',
   'home', NULL),
  ('akhirah_milestone', 'en',
   '{milestone} Seeds and counting',
   'A beautiful milestone — but the best is yet to come. May Allah accept and multiply.',
   'home', NULL),
  ('akhirah_milestone', 'en',
   'A garden in the making',
   '{milestone} Seeds planted. Each one a tree in Jannah, in shaa Allah.',
   'home', NULL),
  ('akhirah_milestone', 'en',
   'Quietly, you''re growing',
   'You''ve quietly crossed {milestone} Seeds. The angels write what people don''t see.',
   'home', NULL),

  -- ── Streak milestone — uses {streak} and {streakType} placeholders ─────
  ('streak_milestone', 'en',
   '{streak}-day streak, MashaAllah',
   'You''ve kept your {streakType} streak going for {streak} days. The Prophet ﷺ loved the deeds done consistently, even if small.',
   'home', NULL),
  ('streak_milestone', 'en',
   'A {streak}-day habit',
   'Your {streakType} streak is now {streak} days. This is what spiritual discipline looks like.',
   'home', NULL),
  ('streak_milestone', 'en',
   'Day {streak} — keep going',
   '{streak} days of consistent {streakType}. The next milestone is closer than you think.',
   'home', NULL),
  ('streak_milestone', 'en',
   '{streak} days strong',
   'Your {streakType} streak hit {streak} days today. A habit is becoming a part of who you are.',
   'home', NULL),
  ('streak_milestone', 'en',
   'Consistency is heavier than effort',
   '{streak} days of {streakType}. Quietly, deliberately, you are changing.',
   'home', NULL)
ON CONFLICT DO NOTHING;


-- Crons
SELECT cron.schedule(
  'push-featured-dua',
  '0 * * * *',
  $$ SELECT public.invoke_push_function('featured-dua-reminder'); $$
);

SELECT cron.schedule(
  'push-project-funded',
  '0 9 * * *',
  $$ SELECT public.invoke_push_function('project-funded-notifier'); $$
);

SELECT cron.schedule(
  'push-akhirah-milestone',
  '15 9 * * *',
  $$ SELECT public.invoke_push_function('akhirah-milestone-celebration'); $$
);

SELECT cron.schedule(
  'push-streak-milestone',
  '30 9 * * *',
  $$ SELECT public.invoke_push_function('streak-milestone-celebration'); $$
);

SELECT jobname, schedule
FROM cron.job
WHERE jobname IN (
  'push-featured-dua',
  'push-project-funded',
  'push-akhirah-milestone',
  'push-streak-milestone'
);
