-- ─────────────────────────────────────────────────────────────────────────────
-- 20260630_010_more_notifications.sql
--
-- Expands the notification system with:
--
--   • salawat_friday      LOCAL (Friday 12:00 local) — Sunnah of sending
--                         salawat upon the Prophet ﷺ on Yawm al-Jumu'ah.
--   • daily_astaghfir     LOCAL (every day 11:00 local) — gentle istighfar
--                         reminder.
--   • validate_seeds      FCM (daily ~18:00 local) — nudges users with
--                         unspent Seeds to donate to a Cause.
--   • habit_gap_quran     FCM (daily ~14:00 local) — for users active in
--                         dhikr but not Quran in the last 7 days.
--   • habit_gap_dhikr     FCM — for users active in Quran but not dhikr.
--
-- Plus extra benefit-style variants for the existing morning_azkaar and
-- evening_azkaar rotations so the same user doesn't see repeating copy.
--
-- Two new server crons fire hourly; each function self-gates on user local
-- hour and day-of-week so a UTC firing only acts on matching users.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.notification_variants
  (notification_type, locale, title, body, route, image_url)
VALUES
  -- ── Friday Salawat (5) — local schedule ─────────────────────────────────
  ('salawat_friday', 'en',
   'Salawat on Friday',
   'Recite salawat upon the Prophet ﷺ generously today — the deeds of Friday are shown to him.',
   'dhikr', NULL),
  ('salawat_friday', 'en',
   'A Sunnah of Friday',
   'Send blessings upon the Messenger ﷺ. The more you say, the closer he draws to you on the Day of Judgement.',
   'dhikr', NULL),
  ('salawat_friday', 'en',
   'Allahumma salli ʿala Muhammad',
   'Today is Friday — recite salawat in abundance. Each one returns ten blessings to you.',
   'dhikr', NULL),
  ('salawat_friday', 'en',
   'Light up your Friday',
   'Saying salawat on the Prophet ﷺ today is among the most loved acts. Don''t let this hour pass.',
   'dhikr', NULL),
  ('salawat_friday', 'en',
   'For every salawat, ten',
   '"Whoever sends one salawat upon me, Allah sends ten upon him." Recite generously today.',
   'dhikr', NULL),

  -- ── Daily Astaghfir (5) — local schedule ────────────────────────────────
  ('daily_astaghfir', 'en',
   'A moment for istighfar',
   '"Astaghfirullah" polishes the heart and opens doors of provision. Pause for one minute and recite.',
   'dhikr', NULL),
  ('daily_astaghfir', 'en',
   'Seek forgiveness',
   'The Prophet ﷺ sought forgiveness over seventy times a day. Just a few moments of istighfar can lift your day.',
   'dhikr', NULL),
  ('daily_astaghfir', 'en',
   'The believer''s shield',
   'Istighfar lifts worry, brings rain, multiplies wealth. Make some now.',
   'dhikr', NULL),
  ('daily_astaghfir', 'en',
   'Polish the heart',
   'Every sin leaves a mark — istighfar wipes it. Recite "Astaghfirullah wa atubu ilayh" gently.',
   'dhikr', NULL),
  ('daily_astaghfir', 'en',
   'A small habit, immense reward',
   'Pause and say "Astaghfirullah". Repeat it with your breath. Your Lord loves it.',
   'dhikr', NULL),

  -- ── Validate Seeds (5) — donate unused Seeds to a Cause ─────────────────
  ('validate_seeds', 'en',
   'Your Seeds are growing',
   'Donate your Sabiq Seeds to fund real projects — orphans, masjids, free meals. Every Seed plants a deed.',
   'cause', NULL),
  ('validate_seeds', 'en',
   'Plant your harvest',
   'You''ve earned good Seeds. Turn them into real-world barakah by supporting a Cause.',
   'cause', NULL),
  ('validate_seeds', 'en',
   'Don''t let them sit',
   'Your Seeds are waiting to do good. Choose a project and donate — Sadaqah extinguishes sin like water extinguishes fire.',
   'cause', NULL),
  ('validate_seeds', 'en',
   'Make them count',
   'Your worship earned you Seeds. Now multiply the reward — donate to a Cause and water what you planted.',
   'cause', NULL),
  ('validate_seeds', 'en',
   'A Cause needs you',
   'Real projects are funded by your Seeds. Tap to donate — every contribution counts on Yawm al-Qiyamah.',
   'cause', NULL),

  -- ── Habit gap: Quran-active, missing dhikr (3) ──────────────────────────
  ('habit_gap_dhikr', 'en',
   'Pair the Quran with dhikr',
   'You''ve been reading the Quran consistently, MashaAllah! Crown your day with morning or evening adhkar.',
   'dhikr', NULL),
  ('habit_gap_dhikr', 'en',
   'Don''t forget remembrance',
   'A reader who skips dhikr is like a tree without water. Tap to recite your adhkar now.',
   'dhikr', NULL),
  ('habit_gap_dhikr', 'en',
   'Two wings of worship',
   'Quran and dhikr lift the heart together. You have one wing — add the other.',
   'dhikr', NULL),

  -- ── Habit gap: dhikr-active, missing Quran (3) ──────────────────────────
  ('habit_gap_quran', 'en',
   'Open the Mushaf today',
   'Your dhikr is steady, alhamdulillah. Take a few minutes for the Quran too — even one ayah counts.',
   'quran', NULL),
  ('habit_gap_quran', 'en',
   'The Quran is calling',
   'You haven''t read in a few days. Just one page, one ayah — start where you left off.',
   'quran', NULL),
  ('habit_gap_quran', 'en',
   'Pair them together',
   'Dhikr is your daily companion. Make the Quran one too — open your Mushaf now.',
   'quran', NULL),

  -- ── Benefit-style morning_azkaar additions ─────────────────────────────
  ('morning_azkaar', 'en',
   'Guarded until Maghrib',
   'Reciting Ayatul Kursi after Fajr guards you until Maghrib. Take a moment for your morning adhkar now.',
   'morning', NULL),
  ('morning_azkaar', 'en',
   'A hundred hasanat',
   'Whoever says "Subhanallahi wa bihamdihi" 100 times in the morning — their sins are wiped, even if as much as the foam of the sea. Start your adhkar.',
   'morning', NULL),
  ('morning_azkaar', 'en',
   'Allah''s morning provision',
   '"O Allah, by You we have entered the morning..." — the words of the Prophet ﷺ to begin the day. Open your morning adhkar.',
   'morning', NULL),

  -- ── Benefit-style evening_azkaar additions ─────────────────────────────
  ('evening_azkaar', 'en',
   'Protection till morning',
   'Reciting the last two verses of Al-Baqarah after Maghrib protects you all night. Open your evening adhkar.',
   'evening', NULL),
  ('evening_azkaar', 'en',
   'Three times each',
   'Surah al-Ikhlas, al-Falaq, al-Nas — three times each in the evening grants Allah''s protection from every harm.',
   'evening', NULL),
  ('evening_azkaar', 'en',
   'Seven, no harm',
   '"Whoever says ‘Hasbiyallahu la ilaha illa Hu, ʿalayhi tawakkaltu’ seven times — Allah will suffice him." Recite your evening adhkar now.',
   'evening', NULL)
ON CONFLICT DO NOTHING;


-- ── Hourly crons for the two new server-driven types ─────────────────────
-- Both functions self-gate on user local hour, so a UTC firing only acts
-- on users whose timezone puts them in the target slot.

SELECT cron.schedule(
  'push-validate-seeds-reminder',
  '0 * * * *',
  $$ SELECT public.invoke_push_function('validate-seeds-reminder'); $$
);

SELECT cron.schedule(
  'push-habit-gap-reminder',
  '0 * * * *',
  $$ SELECT public.invoke_push_function('habit-gap-reminder'); $$
);


-- Sanity
SELECT jobname, schedule
FROM cron.job
WHERE jobname IN (
  'push-validate-seeds-reminder',
  'push-habit-gap-reminder'
);
