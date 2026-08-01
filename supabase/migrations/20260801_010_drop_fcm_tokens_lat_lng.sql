-- ─────────────────────────────────────────────────────────────────────────────
-- 20260801_010_drop_fcm_tokens_lat_lng.sql
--
-- Removes the persisted raw GPS coordinates from `fcm_tokens`. The app now
-- consumes lat/lng in memory only to derive the IANA timezone, and stores
-- solely the derived `timezone` string. This aligns the stored data with
-- what's declared on the Play Data Safety form ("Location used for
-- timezone detection, not persisted").
--
-- No Edge Function or migration references these columns (verified via
-- grep on 2026-08-01), so dropping is safe.
--
-- Rollback: re-add nullable DOUBLE columns; app will silently keep sending
-- them as omitted (since the client no longer writes lat/lng, they'll be
-- NULL for all new rows).
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Null out any existing values first (privacy hygiene — remove the
--    historical GPS records before dropping the columns).
UPDATE fcm_tokens
   SET latitude  = NULL,
       longitude = NULL
 WHERE latitude IS NOT NULL
    OR longitude IS NOT NULL;

-- 2. Drop the columns. IF EXISTS so re-runs on a partially-migrated DB
--    don't error out.
ALTER TABLE fcm_tokens
  DROP COLUMN IF EXISTS latitude,
  DROP COLUMN IF EXISTS longitude;

-- 3. Sanity check — should return zero rows.
SELECT column_name
  FROM information_schema.columns
 WHERE table_name  = 'fcm_tokens'
   AND column_name IN ('latitude', 'longitude');
