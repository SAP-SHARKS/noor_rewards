-- ─────────────────────────────────────────────────────────────────────────────
-- 20260629_010_sleep_and_kahf_notifications.sql
--
-- Adds two new notification types:
--
--   1. sleep_azkar          fires at ~21:00 local for every user
--                           (piggy-backs on the existing hourly
--                           `push-local-azkaar-reminders` cron — the
--                           function is extended to handle a third
--                           batch alongside morning/evening).
--
--   2. surah_kahf_friday    fires twice on Fridays in the user's
--                           timezone: ~07:00 local (encourage starting)
--                           and ~16:00 local (last chance before Maghrib).
--
-- Both have 5 different variant phrasings so the same user doesn't see
-- identical copy on consecutive nights / Fridays.
--
-- Additive — safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.notification_variants
  (notification_type, locale, title, body, route, image_url)
VALUES
  -- ── Sleep azkar (5) ──────────────────────────────────────────────────────
  ('sleep_azkar', 'en',
   'Time to wind down',
   'End the day with sleep adhkar — Ayatul Kursi, the 3 Quls, and the bedtime du''as. Sleep under Allah''s protection.',
   'dhikr', NULL),
  ('sleep_azkar', 'en',
   'Seal the night',
   'Before you sleep, recite Surah Al-Mulk — the protector of the grave. A few minutes for a lifetime of barakah.',
   'dhikr', NULL),
  ('sleep_azkar', 'en',
   'A peaceful close',
   'Recite the bedtime adhkar tonight — Ayatul Kursi guards the believer''s soul until morning.',
   'dhikr', NULL),
  ('sleep_azkar', 'en',
   '3 Quls before bed',
   'Falaq, Naas, Ikhlas — three times each, then wipe over yourself. A Sunnah of the Prophet ﷺ.',
   'dhikr', NULL),
  ('sleep_azkar', 'en',
   'Last call before bed',
   'Your night-time adhkar are waiting. End the day the way the Prophet ﷺ did.',
   'dhikr', NULL),

  -- ── Surah Al-Kahf — Friday (5) ──────────────────────────────────────────
  ('surah_kahf_friday', 'en',
   'It''s Friday — read Surah Al-Kahf',
   'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.',
   'quran', NULL),
  ('surah_kahf_friday', 'en',
   'Al-Kahf today',
   'The Sunnah of Friday: recite Surah Al-Kahf. Let your week be lit by its noor.',
   'quran', NULL),
  ('surah_kahf_friday', 'en',
   'Friday blessing',
   'Don''t let this Friday pass without Al-Kahf — 110 verses of immense reward.',
   'quran', NULL),
  ('surah_kahf_friday', 'en',
   'Brighten your Friday',
   'Surah Al-Kahf protects from the trials of Dajjal. Recite it today before Maghrib.',
   'quran', NULL),
  ('surah_kahf_friday', 'en',
   'A Friday treasure',
   'An hour to Maghrib — finish Surah Al-Kahf if you haven''t yet. Don''t let the blessing slip away.',
   'quran', NULL)
ON CONFLICT DO NOTHING;

-- Hourly cron for Friday-Kahf. The function self-gates on user-local day-of-
-- week === Friday AND hour ∈ {7, 16}, so a UTC firing only acts on users
-- whose timezone puts them in one of those slots on a Friday.
SELECT cron.schedule(
  'push-friday-kahf-reminder',
  '0 * * * *',
  $$ SELECT public.invoke_push_function('friday-kahf-reminder'); $$
);

SELECT jobname, schedule FROM cron.job
WHERE jobname = 'push-friday-kahf-reminder';
