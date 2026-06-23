-- Schedules the 8 push-notification Edge Functions via pg_cron.
--
-- All cron times are in UTC. Picked to land in a useful local window for the
-- major Muslim populations the app targets (Pakistan UTC+5, India UTC+5:30,
-- Indonesia UTC+7, Saudi/Turkey UTC+3, Egypt UTC+2). A single UTC time can't
-- be ideal for every timezone — the windows below favour South Asia + Gulf
-- evening hours (where most of the user base sits) without spamming anyone.
--
-- Schedule summary (UTC → ~Pakistan local):
--   02:00 → 07:00 PK   azkar morning reminder
--   03:00 → 08:00 PK   community-momentum (morning motivation)
--   06:00 → 11:00 PK   resume-reading (mid-morning nudge)
--   11:00 → 16:00 PK   azkar evening reminder
--   15:00 → 20:00 PK   level-up-close (Tue/Fri only)
--   16:00 → 21:00 PK   nightly-coin-reminder (bedtime claim)
--   17:00 → 22:00 PK   streak-at-risk (last-chance save)
--   02:00 1st of mo    monthly-quran-reminder (start of month)
--   17:00 1st of mo    monthly-milestone (last-month summary)
--
-- Requires: pg_cron extension + service_role_key in Vault (already set up by
-- migration 20260623_010_community_projects_auto_translate_trigger.sql).

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ─── Helper ────────────────────────────────────────────────────────────────
-- Invokes a named Edge Function with the service-role bearer. Returns the
-- pg_net request id so cron logs reflect the queued HTTP call.
CREATE OR REPLACE FUNCTION public.invoke_push_function(fn_name text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault
AS $$
DECLARE
  functions_url constant text :=
    'https://fwjzhtcxfiendofnhyzp.supabase.co/functions/v1';
  service_key text;
  request_id  bigint;
BEGIN
  SELECT decrypted_secret INTO service_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  IF service_key IS NULL THEN
    RAISE WARNING 'service_role_key not in Vault, skipping push %', fn_name;
    RETURN NULL;
  END IF;

  SELECT net.http_post(
    url     := functions_url || '/' || fn_name,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body    := '{}'::jsonb
  ) INTO request_id;

  RETURN request_id;
END;
$$;

COMMENT ON FUNCTION public.invoke_push_function(text) IS
  'pg_cron helper. POSTs an empty body to the named Edge Function with the service-role bearer pulled from Vault.';

-- ─── Idempotent cleanup ────────────────────────────────────────────────────
-- Drop any previous push-* cron jobs so re-running this migration replaces
-- them instead of stacking duplicates.
DO $$
DECLARE
  jn text;
BEGIN
  FOR jn IN
    SELECT jobname FROM cron.job WHERE jobname LIKE 'push-%'
  LOOP
    PERFORM cron.unschedule(jn);
  END LOOP;
END $$;

-- ─── Schedules ─────────────────────────────────────────────────────────────
-- Daily: streak save, bedtime claim, morning nudges
SELECT cron.schedule('push-streak-at-risk', '0 17 * * *',
  $$ SELECT public.invoke_push_function('streak-at-risk'); $$);

SELECT cron.schedule('push-nightly-coin-reminder', '0 16 * * *',
  $$ SELECT public.invoke_push_function('nightly-coin-reminder'); $$);

SELECT cron.schedule('push-community-momentum', '0 3 * * *',
  $$ SELECT public.invoke_push_function('community-momentum'); $$);

SELECT cron.schedule('push-resume-reading', '0 6 * * *',
  $$ SELECT public.invoke_push_function('resume-reading'); $$);

-- Twice daily: azkar morning + evening
SELECT cron.schedule('push-local-azkaar-morning', '0 2 * * *',
  $$ SELECT public.invoke_push_function('local-azkaar-reminders'); $$);

SELECT cron.schedule('push-local-azkaar-evening', '0 11 * * *',
  $$ SELECT public.invoke_push_function('local-azkaar-reminders'); $$);

-- Twice a week: level-up teaser (Tuesday + Friday)
SELECT cron.schedule('push-level-up-close', '0 15 * * 2,5',
  $$ SELECT public.invoke_push_function('level-up-close'); $$);

-- Monthly: start-of-month Quran nudge + last-month milestone summary
SELECT cron.schedule('push-monthly-quran-reminder', '0 2 1 * *',
  $$ SELECT public.invoke_push_function('monthly-quran-reminder'); $$);

SELECT cron.schedule('push-monthly-milestone', '0 17 1 * *',
  $$ SELECT public.invoke_push_function('monthly-milestone'); $$);

-- ─── Verification ──────────────────────────────────────────────────────────
-- After running, confirm the 9 jobs are scheduled:
--   SELECT jobname, schedule, active FROM cron.job WHERE jobname LIKE 'push-%';
--
-- To trigger one manually for testing (without waiting for the cron):
--   SELECT public.invoke_push_function('streak-at-risk');
