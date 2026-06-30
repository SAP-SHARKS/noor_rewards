-- ─────────────────────────────────────────────────────────────────────────────
-- 20260628_020_disengagement_pause.sql
--
-- Disengagement-pause system: if a user has received many notifications they
-- never opened AND hasn't returned to the app in a while, send one final
-- "we're pausing your reminders" push and stop nudging them until they come
-- back. When they open the app, resume automatically.
--
-- Additive — safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Schema additions ─────────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_seen_at        TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notifications_paused BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notifications_paused_at TIMESTAMPTZ;

ALTER TABLE public.notification_log
  ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ;

-- Index for the disengagement query (count unopened per user in window).
CREATE INDEX IF NOT EXISTS notification_log_user_sent_opened_idx
  ON public.notification_log (user_id, sent_at)
  WHERE opened_at IS NULL;


-- ── 2. RPC: mark a notification as opened (tap from Flutter) ───────────────
CREATE OR REPLACE FUNCTION public.mark_notification_opened(p_nid TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.notification_log
  SET opened_at = COALESCE(opened_at, now())
  WHERE notification_id = p_nid
    AND user_id = auth.uid();
END $$;

REVOKE ALL ON FUNCTION public.mark_notification_opened(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_notification_opened(text) TO authenticated;


-- ── 3. RPC: mark user active (called on app foreground) ────────────────────
-- Bumps last_seen_at AND auto-resumes notifications if they were paused.
CREATE OR REPLACE FUNCTION public.mark_user_active()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.profiles
  SET last_seen_at = now(),
      notifications_paused = false,
      notifications_paused_at = CASE
        WHEN notifications_paused THEN NULL
        ELSE notifications_paused_at
      END
  WHERE id = auth.uid();
END $$;

REVOKE ALL ON FUNCTION public.mark_user_active() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_user_active() TO authenticated;


-- ── 4. Disengagement-pause notification variants ───────────────────────────
-- 5 different phrasings; the edge function picks one at random per user via
-- the existing pickVariant() helper so no two users see the same message
-- back-to-back. English-only — translator backfills via locale rows later.
INSERT INTO public.notification_variants
  (notification_type, locale, title, body, route, image_url)
VALUES
  ('disengagement_pause', 'en',
   'Reminders paused',
   'It looks like our nudges aren''t reaching you. We''ll quiet them for now — open Sabiq whenever your heart calls and they''ll come back on their own.',
   'home', NULL),
  ('disengagement_pause', 'en',
   'We''ll wait for you',
   'Your daily reminders will rest for a while. Open the app anytime to bring them back — your Seeds and streak are saved.',
   'home', NULL),
  ('disengagement_pause', 'en',
   'Taking a gentle break',
   'We''ve paused your reminders so they don''t crowd you. Return whenever you''re ready, and they''ll quietly resume.',
   'home', NULL),
  ('disengagement_pause', 'en',
   'Stepping aside, with du''a',
   'We won''t keep nudging — your time with the Quran is yours. Open Sabiq anytime to switch reminders back on.',
   'home', NULL),
  ('disengagement_pause', 'en',
   'Pausing reminders for now',
   'No more daily pings until you come back. The journey waits patiently; reopen Sabiq when the moment feels right.',
   'home', NULL)
ON CONFLICT DO NOTHING;


-- ── 5. Schedule the disengagement check — daily at 10:00 UTC ───────────────
-- Picked so it fires once per day during typical mid-day for most users.
SELECT cron.schedule(
  'push-check-disengaged-users',
  '0 10 * * *',
  $$ SELECT public.invoke_push_function('check-disengaged-users'); $$
);


-- ── 6. Sanity check ────────────────────────────────────────────────────────
SELECT jobname, schedule
FROM cron.job
WHERE jobname = 'push-check-disengaged-users';
