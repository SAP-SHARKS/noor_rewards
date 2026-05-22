-- ════════════════════════════════════════════════════════════════════════════
-- Donor Pool economy — admin-tunable parameters
--
-- These four values drive the monthly Seeds→USD distribution:
--   Funding[project] = (Seeds donated to project / Total Seeds donated)
--                    × Monthly donor pool
--
-- All values live in the shared app_config table so the Flutter app, future
-- settle_month() RPC, and the admin Donor Pool simulator all read from one
-- source of truth.
--
-- Run this in the Supabase SQL Editor (idempotent — re-running won't
-- overwrite values you've tuned).
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO app_config (key, value, description) VALUES
  ('donor_pool_usd_monthly', '300',
   'Total monthly sponsor / donor pool in USD. Distributed to charity projects proportional to the Seeds each project receives from users.'),
  ('min_seed_value_usd', '0.0005',
   'Floor for the per-Seed USD value. If the raw value (pool / total seeds) falls below this, the floor is used and the platform tops up the difference from reserve.'),
  ('max_seed_value_usd', '0.005',
   'Ceiling for the per-Seed USD value. If the raw value exceeds this, the ceiling is used and the excess rolls into the reserve fund.'),
  ('max_donatable_seeds_per_month', '5000',
   'Per-user monthly cap on Seeds that count toward the donor pool. Seeds earned above this still count for level / badges / leaderboard but do not tap the pool.')
ON CONFLICT (key) DO NOTHING;

-- Verify
SELECT key, value, description
FROM app_config
WHERE key IN (
  'donor_pool_usd_monthly',
  'min_seed_value_usd',
  'max_seed_value_usd',
  'max_donatable_seeds_per_month'
)
ORDER BY key;
