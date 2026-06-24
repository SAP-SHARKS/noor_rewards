-- Re-schedules the push-notification Edge Functions to fire HOURLY so each
-- function's built-in per-user-timezone hour filter can match its target
-- local hour for every user, wherever they are.
--
-- Each push function (streak-at-risk, community-momentum, etc.) already
-- contains code like:
--
--   for (const row of fcmTokens) {
--     const hour = localHourInUserTimezone(row.timezone);
--     if (hour === 19) targets.push(row.user_id); // streak-at-risk
--   }
--
-- So firing the function HOURLY means it runs 24 times a day, but each run
-- only sends to users whose local time matches the target hour. A Pakistan
-- user at 7 PM PK gets the push when the function fires at 14:00 UTC; a
-- Saudi user at 7 PM SA gets it when the function fires at 16:00 UTC.
--
-- Target local hours (per the hardcoded checks inside each function):
--   streak-at-risk           → 19:00 local
--   nightly-coin-reminder    → 21:00 local
--   community-momentum       →  9:00 local
--   resume-reading           → 14:00 local
--   level-up-close           → 12:00 local
--   local-azkaar-reminders   →  8:00 + 17:00 local (one function, two hours)
--
-- Monthly functions stay on fixed UTC schedules — the once-a-month cadence
-- makes precise local timing low-value, and the hourly approach would mean
-- 24 runs/day looking for a single matching day.
--
-- This migration supersedes 20260623_020. Re-running it drops the prior
-- push-* jobs first, so no duplicates.

-- ─── Idempotent cleanup ────────────────────────────────────────────────────
DO $$
DECLARE
  jn text;
BEGIN
  FOR jn IN SELECT jobname FROM cron.job WHERE jobname LIKE 'push-%'
  LOOP
    PERFORM cron.unschedule(jn);
  END LOOP;
END $$;

-- ─── Hourly fan-out for the 6 timezone-aware functions ───────────────────
-- Each fires every hour on the minute (00 past). The function itself
-- only sends to users whose local time matches its target hour, so the
-- 23 hours where no users match are cheap no-ops.

SELECT cron.schedule('push-streak-at-risk', '0 * * * *',
  $$ SELECT public.invoke_push_function('streak-at-risk'); $$);

SELECT cron.schedule('push-nightly-coin-reminder', '0 * * * *',
  $$ SELECT public.invoke_push_function('nightly-coin-reminder'); $$);

SELECT cron.schedule('push-community-momentum', '0 * * * *',
  $$ SELECT public.invoke_push_function('community-momentum'); $$);

SELECT cron.schedule('push-resume-reading', '0 * * * *',
  $$ SELECT public.invoke_push_function('resume-reading'); $$);

SELECT cron.schedule('push-level-up-close', '0 * * * *',
  $$ SELECT public.invoke_push_function('level-up-close'); $$);

SELECT cron.schedule('push-local-azkaar-reminders', '0 * * * *',
  $$ SELECT public.invoke_push_function('local-azkaar-reminders'); $$);

-- ─── Monthly: fixed UTC dates ─────────────────────────────────────────────
SELECT cron.schedule('push-monthly-quran-reminder', '0 9 1 * *',
  $$ SELECT public.invoke_push_function('monthly-quran-reminder'); $$);

SELECT cron.schedule('push-monthly-milestone', '0 17 1 * *',
  $$ SELECT public.invoke_push_function('monthly-milestone'); $$);

-- ─── Verification ────────────────────────────────────────────────────────
-- Confirm the 8 jobs are scheduled:
--   SELECT jobname, schedule, active FROM cron.job WHERE jobname LIKE 'push-%';
--
-- Inspect recent runs:
--   SELECT runid, jobid, status, start_time, end_time, return_message
--   FROM cron.job_run_details
--   WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname LIKE 'push-%')
--   ORDER BY start_time DESC LIMIT 20;
--
-- Manual fire of a single job (without waiting for cron):
--   SELECT public.invoke_push_function('streak-at-risk');
