-- Adds per-locale `story` columns to sponsored_orphans + a trigger that
-- calls the `auto-translate-orphan` Edge Function whenever the English
-- `story` changes (mirrors the community_projects translation pipeline).
--
-- The existing English `story` stays the canonical fallback. The 7 sibling
-- columns are nullable — client code falls back to English when NULL.

ALTER TABLE public.sponsored_orphans
  ADD COLUMN IF NOT EXISTS story_ar TEXT,
  ADD COLUMN IF NOT EXISTS story_ur TEXT,
  ADD COLUMN IF NOT EXISTS story_fr TEXT,
  ADD COLUMN IF NOT EXISTS story_id TEXT,
  ADD COLUMN IF NOT EXISTS story_ms TEXT,
  ADD COLUMN IF NOT EXISTS story_ru TEXT,
  ADD COLUMN IF NOT EXISTS story_tr TEXT;

COMMENT ON COLUMN public.sponsored_orphans.story_ar IS
  'Arabic translation of story. NULL = fall back to English `story`.';

-- ─── Trigger that enqueues translation via pg_net ─────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Reads the service_role_key from Vault (same pattern as
-- invoke_push_function in 20260623_020_schedule_push_notifications.sql).
-- ALTER DATABASE SET app.settings.* is permission-denied on Supabase, so
-- the older current_setting() approach silently fails — Vault is the
-- working production pattern.
CREATE OR REPLACE FUNCTION public.sponsored_orphans_enqueue_translation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault
AS $$
DECLARE
  functions_url constant text :=
    'https://fwjzhtcxfiendofnhyzp.supabase.co/functions/v1';
  service_key text;
BEGIN
  SELECT decrypted_secret INTO service_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  IF service_key IS NULL THEN
    RAISE WARNING 'sponsored_orphans_enqueue_translation: service_role_key not in Vault, skipping';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := functions_url || '/auto-translate-orphan',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body    := jsonb_build_object('orphan_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sponsored_orphans_auto_translate
  ON public.sponsored_orphans;

CREATE TRIGGER trg_sponsored_orphans_auto_translate
AFTER INSERT OR UPDATE OF story
ON public.sponsored_orphans
FOR EACH ROW
WHEN (NEW.story IS NOT NULL)
EXECUTE FUNCTION public.sponsored_orphans_enqueue_translation();

COMMENT ON TRIGGER trg_sponsored_orphans_auto_translate
  ON public.sponsored_orphans IS
  'Fires auto-translate-orphan Edge Function when English story changes. Scoped to story column so the function''s own writes to story_<lang> do not re-fire.';

-- ─── ONE-TIME BACKFILL (run once after deploy) ────────────────────────────
-- UPDATE public.sponsored_orphans SET story = story;
