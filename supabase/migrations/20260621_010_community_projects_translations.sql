-- Adds per-locale title / description columns to community_projects so the
-- Cause tab can display project content in the user's active app locale.
--
-- Strategy: keep the existing English `title` / `description` columns as the
-- canonical (fallback) text. Add 7 sibling columns for each non-English locale
-- the app ships (ar, ur, fr, id, ms, ru, tr). All new columns are nullable —
-- client code falls back to the English `title` / `description` when the
-- locale-specific column is NULL or empty, so existing rows keep working
-- with zero data backfill required.
--
-- Backfill: admins translate via the admin panel (or direct DB edits) — this
-- migration does NOT translate existing rows automatically.

ALTER TABLE public.community_projects
  ADD COLUMN IF NOT EXISTS title_ar TEXT,
  ADD COLUMN IF NOT EXISTS title_ur TEXT,
  ADD COLUMN IF NOT EXISTS title_fr TEXT,
  ADD COLUMN IF NOT EXISTS title_id TEXT,
  ADD COLUMN IF NOT EXISTS title_ms TEXT,
  ADD COLUMN IF NOT EXISTS title_ru TEXT,
  ADD COLUMN IF NOT EXISTS title_tr TEXT,
  ADD COLUMN IF NOT EXISTS description_ar TEXT,
  ADD COLUMN IF NOT EXISTS description_ur TEXT,
  ADD COLUMN IF NOT EXISTS description_fr TEXT,
  ADD COLUMN IF NOT EXISTS description_id TEXT,
  ADD COLUMN IF NOT EXISTS description_ms TEXT,
  ADD COLUMN IF NOT EXISTS description_ru TEXT,
  ADD COLUMN IF NOT EXISTS description_tr TEXT;

COMMENT ON COLUMN public.community_projects.title_ar IS 'Arabic translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.title_ur IS 'Urdu translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.title_fr IS 'French translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.title_id IS 'Indonesian translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.title_ms IS 'Malay translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.title_ru IS 'Russian translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.title_tr IS 'Turkish translation of title. NULL = fall back to English `title`.';
COMMENT ON COLUMN public.community_projects.description_ar IS 'Arabic translation of description. NULL = fall back to English `description`.';
COMMENT ON COLUMN public.community_projects.description_ur IS 'Urdu translation of description. NULL = fall back to English `description`.';
COMMENT ON COLUMN public.community_projects.description_fr IS 'French translation of description. NULL = fall back to English `description`.';
COMMENT ON COLUMN public.community_projects.description_id IS 'Indonesian translation of description. NULL = fall back to English `description`.';
COMMENT ON COLUMN public.community_projects.description_ms IS 'Malay translation of description. NULL = fall back to English `description`.';
COMMENT ON COLUMN public.community_projects.description_ru IS 'Russian translation of description. NULL = fall back to English `description`.';
COMMENT ON COLUMN public.community_projects.description_tr IS 'Turkish translation of description. NULL = fall back to English `description`.';
