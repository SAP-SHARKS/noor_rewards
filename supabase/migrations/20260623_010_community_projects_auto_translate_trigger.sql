-- Postgres trigger that calls the `auto-translate-project` Edge Function
-- whenever a community_projects row's English `title` or `description`
-- changes (insert or update). The Edge Function fills in title_<lang>
-- and description_<lang> for the 7 non-English locales via Google
-- Translate, so admins only ever edit the English source columns.
--
-- Why `OF title, description`: scopes the trigger to changes in the source
-- English columns only. The function's own UPDATE of `title_<lang>` /
-- `description_<lang>` won't re-fire the trigger, so no recursion loop.
--
-- Why pg_net (async http_post): the trigger returns immediately; the
-- Edge Function runs in the background and PATCHes the row when ready.
-- Admins don't wait on Google Translate during inserts.
--
-- Requires the `pg_net` extension (preinstalled on Supabase).
-- Requires `app.settings.functions_url` and `app.settings.service_role_key`
-- to be set as DB settings — see the comments below for the one-line
-- setup commands.

CREATE EXTENSION IF NOT EXISTS pg_net;

-- ─── Helper function ───────────────────────────────────────────────────────
-- Reads the functions URL and service role key from DB settings and POSTs
-- the project_id to the Edge Function. SECURITY DEFINER lets it run with
-- elevated privileges (it can call pg_net even when the original UPDATE
-- was made by a low-privilege role).
CREATE OR REPLACE FUNCTION public.community_projects_enqueue_translation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  functions_url text;
  service_key   text;
BEGIN
  functions_url := current_setting('app.settings.functions_url', true);
  service_key   := current_setting('app.settings.service_role_key', true);

  IF functions_url IS NULL OR service_key IS NULL THEN
    RAISE WARNING 'community_projects_enqueue_translation: missing settings, skipping (set app.settings.functions_url and app.settings.service_role_key)';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := functions_url || '/auto-translate-project',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body    := jsonb_build_object('project_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

-- ─── Trigger ───────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_community_projects_auto_translate
  ON public.community_projects;

CREATE TRIGGER trg_community_projects_auto_translate
AFTER INSERT OR UPDATE OF title, description
ON public.community_projects
FOR EACH ROW
WHEN (NEW.title IS NOT NULL OR NEW.description IS NOT NULL)
EXECUTE FUNCTION public.community_projects_enqueue_translation();

COMMENT ON TRIGGER trg_community_projects_auto_translate
  ON public.community_projects IS
  'Fires auto-translate-project Edge Function when English title/description changes. Scoped to those columns so the function''s own writes to title_<lang>/description_<lang> do not re-fire it.';

-- ─── ONE-TIME SETUP (run by admin) ─────────────────────────────────────────
-- Replace <PROJECT_REF> and paste your service role key, then run as the
-- `postgres` role in the Supabase SQL Editor:
--
--   ALTER DATABASE postgres SET app.settings.functions_url =
--     'https://<PROJECT_REF>.supabase.co/functions/v1';
--   ALTER DATABASE postgres SET app.settings.service_role_key =
--     '<YOUR_SERVICE_ROLE_KEY>';
--
-- Then reconnect (the new settings only apply to fresh sessions).

-- ─── ONE-TIME BACKFILL (run once after deploy) ────────────────────────────
-- Fires the trigger for every existing row so each gets translated. The
-- no-op SET title = title triggers the AFTER UPDATE OF title hook.
--
--   UPDATE public.community_projects SET title = title;
