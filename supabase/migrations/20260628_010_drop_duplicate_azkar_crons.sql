-- ─────────────────────────────────────────────────────────────────────────────
-- 20260628_010_drop_duplicate_azkar_crons.sql
--
-- Fix duplicate morning + evening azkar notifications.
--
-- History:
--   • 20260623_020 scheduled two fixed-UTC-hour jobs (`push-local-azkaar-
--     morning` at 02:00 UTC, `push-local-azkaar-evening` at 11:00 UTC).
--   • 20260624_010 introduced `push-local-azkaar-reminders` as an hourly job
--     so the function (which self-gates by user local hour 8 / 17) covers
--     every timezone. The two old jobs were never unscheduled.
--
-- Result: at 02:00 / 11:00 UTC, both the hourly cron and the fixed cron fire
-- the same Edge Function with the same user-hour filter — every UTC+6 / +6
-- user got TWO morning notifications and TWO evening notifications.
--
-- This migration unschedules the duplicates. Hourly cron continues alone.
-- Safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

SELECT cron.unschedule('push-local-azkaar-morning')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'push-local-azkaar-morning'
);

SELECT cron.unschedule('push-local-azkaar-evening')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'push-local-azkaar-evening'
);

-- Sanity check — only `push-local-azkaar-reminders` should remain.
SELECT jobname, schedule
FROM cron.job
WHERE jobname LIKE 'push-local-azkaar%';
