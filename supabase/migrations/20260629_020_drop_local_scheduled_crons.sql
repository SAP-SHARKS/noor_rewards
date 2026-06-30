-- ─────────────────────────────────────────────────────────────────────────────
-- 20260629_020_drop_local_scheduled_crons.sql
--
-- Retire the server-side FCM crons for fixed-time reminders that are now
-- scheduled LOCALLY on the device (via flutter_local_notifications +
-- AndroidScheduleMode.exactAllowWhileIdle). Local alarms fire reliably
-- even under Android Doze + OEM battery-killers — FCM does not.
--
-- Migrated to local scheduling (handled by Flutter
-- `LocalReminderScheduler`):
--   • morning_azkaar      08:00 local
--   • evening_azkaar      17:00 local
--   • sleep_azkar         21:00 local
--   • surah_kahf_friday   Friday 07:00 + 16:00 local
--
-- Event-driven types stay on FCM (the device can't predict when a
-- streak will be at risk, etc.):
--   • streak-at-risk, level-up-close, resume-reading,
--     community-momentum, nightly-coin-reminder, monthly-*,
--     check-disengaged-users.
-- ─────────────────────────────────────────────────────────────────────────────

SELECT cron.unschedule('push-local-azkaar-reminders')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'push-local-azkaar-reminders'
);

SELECT cron.unschedule('push-friday-kahf-reminder')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'push-friday-kahf-reminder'
);

-- Sanity — these should be GONE.
SELECT jobname, schedule
FROM cron.job
WHERE jobname IN ('push-local-azkaar-reminders', 'push-friday-kahf-reminder');
