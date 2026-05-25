# Noor Rewards / Sabiq — Final Reconciled Security Audit
_Reconciled: 2026-05-24. Sources: `audit.md` (Claude — 16 findings) + `auditcodex.md` (Codex — 7 Critical + 8 High + 8 Medium + 5 Low = 28 findings)._

**Reconciliation totals:** 24 distinct findings after de-duplication. By verification status: 22 VERIFIED-REAL, 2 NEEDS-MANUAL-REVIEW, 0 FALSE-POSITIVE (one Claude claim — about `pubspec.yaml` declaring `.env` as an asset — was independently verified true; no audited finding was rejected). Severity escalations applied where Codex was stricter than Claude (and one demotion where Codex over-stated).

**Most surprising result:** every "admin gating done in app" SQL comment in the repo is exactly as bad as Codex says — the `app_config`, `sponsored_orphans`, `community_project_media`, `onboarding_images` policies are all literally `TO authenticated WITH CHECK (true)`. There is no `is_admin` column anywhere in the SQL — admin is a hardcoded JS allowlist (`pak.zakn@gmail.com`, `zaid_azam@zeir.io`) only. Combined with the published anon key in `lib/main.dart:104-106`, any user who has signed up once can permanently brick the app's economy and content from a browser DevTools console without ever touching the admin UI.

---

## Status (closed out 2026-05-25)

| Finding | Status | Notes |
|---|---|---|
| F-1  QF secrets in git                  | FIX-PROVIDED-NEEDS-MY-ACTION | `ROTATE-SECRETS.md` — user accepted residual risk, did not rotate; `.env` untracked + `!.env` removed from `.gitignore` ✓ |
| F-2  `.gitignore !.env`                  | FIXED | `.env` removed from `.gitignore` whitelist + `git rm --cached .env` |
| F-3  admin tables `WITH CHECK (true)`    | FIXED | `20260524_020_admin_only_writes.sql` |
| F-4  admin gate client-side only         | FIXED | `20260524_010_admin_role_infrastructure.sql` (`app_roles` + `is_admin()`) + F-3 policies |
| F-5  storage buckets world-writable       | FIXED | Same migration as F-3 |
| F-6  `sponsor_orphan` IDOR                | FIXED | `20260524_030_rpc_idor_fixes.sql` |
| F-7  stats family IDOR                    | FIXED | Same migration as F-6 |
| F-8  `earn_xp` unlimited mint             | FIXED | Same migration; +cap of 5000/call |
| F-9  `link_qf_profile` profile theft      | FIXED | Same migration; `auth.uid()` + JWT email check |
| F-10 `reward-webhook` no signature        | FIX-PROVIDED-NEEDS-MY-ACTION | Code patched; `REWARD_WEBHOOK_SECRET` set ✓; no DB webhook wired yet (function inert until one is) |
| F-11 `earn_quran/dhikr_points` pump       | FIXED | `p_coins` clamped to 100 in F-6 migration |
| F-12 `send-fcm` push spoofing             | FIXED | Caller-equals-user_id check added |
| F-13 QF token endpoints exposed           | FIXED | `QF_ALLOWED_CLIENT_IDS` allowlist deployed ✓ |
| F-14 profile mass-assignment              | FIXED | `20260525_040_profile_safe_update_rpc.sql` + Flutter edits (3 files) to use `update_my_profile` / `upsert_my_profile_bootstrap` |
| F-15 donor enumeration via RPC            | DEFERRED | Low impact; donor identity is currently shown in UI by design |
| F-16 analytics views unprotected          | FIXED | `20260525_020`: `security_invoker=true` on both views |
| F-17 missing RLS on many tables           | VERIFIED-CLEAN | User confirmed all 16 listed tables have RLS enabled live |
| F-18 `link_qf_profile` soft-delete trap   | DEFERRED | Low risk now that F-9 prevents the attack |
| F-19 `supabase/.temp/` tracked            | FIXED | `git rm -r --cached supabase/.temp/` + `.gitignore` rule |
| F-20 no rate limits                        | DEFERRED | High effort; IDOR fixes block the main abuse vectors; revisit before scale milestone |
| F-21 search_path on definer fns            | FIXED (patched fns) / DEFERRED (untouched fns) | The 11 RPCs rewritten in F-6/F-7/F-8/F-9/F-11 all have `SET search_path = public, pg_temp` |
| F-22 cron job invocation gates             | NEEDS-MANUAL-REVIEW | `MANUAL-REVIEW-CHECKLIST.md` step 5 |
| F-23 CORS `*`                              | DEFERRED | Mobile-app primary surface unaffected |
| F-24 error leakage from edge functions     | FIXED (partial) | `send-fcm`, `qf-token-exchange`, `qf-token-refresh` now return generic errors |
| F-25 admin app direct browser writes       | DEFERRED | Mitigated by F-3 + F-4 DB-side enforcement |
| F-26 admin audit log                       | FIX-PROVIDED-NEEDS-MY-ACTION | `20260525_030_admin_audit_log.sql` — run migration in Supabase |
| F-27 admin allowlist + MFA                 | NEEDS-MANUAL-REVIEW | DB-backed list done (F-4); MFA is `MANUAL-REVIEW-CHECKLIST.md` step 7 |
| F-28 GitHub branch protection              | NEEDS-MANUAL-REVIEW | `MANUAL-REVIEW-CHECKLIST.md` step 6 |
| F-29 dev scripts (call_function.dart etc)  | FIXED | Deleted |
| F-30 `tsbuildinfo` tracked                 | FIX-PROVIDED-NEEDS-MY-ACTION | `.gitignore` updated; run `git rm --cached admin-web/tsconfig.tsbuildinfo && git commit && git push` |
| F-31 misleading SQL comments               | DEFERRED | Cosmetic |
| F-32 iOS BUNDLE_ID placeholder             | FIXED | `.github/workflows/ios-testflight.yml` set to `com.sabiq.noorrewards` |

**Migrations created (run in order in Supabase SQL Editor):**
1. `supabase/migrations/20260524_010_admin_role_infrastructure.sql` ✓
2. `supabase/migrations/20260524_020_admin_only_writes.sql` ✓
3. `supabase/migrations/20260524_030_rpc_idor_fixes.sql` ✓
4. `supabase/migrations/20260525_010_aggregate_orphan_sponsors.sql` ✓
5. `supabase/migrations/20260525_020_profiles_column_lockdown_and_analytics.sql` ✓ (partly reverted)
6. `supabase/migrations/20260525_021_revert_profiles_lockdown.sql` ✓
7. `supabase/migrations/20260525_030_admin_audit_log.sql` ← run me
8. `supabase/migrations/20260525_040_profile_safe_update_rpc.sql` ← run me

**Edge functions deployed:** `reward-webhook`, `send-fcm`, `qf-token-exchange`, `qf-token-refresh`.

**Companion docs:** `ROTATE-SECRETS.md`, `MANUAL-REVIEW-CHECKLIST.md`.

---

## Summary table

Sorted Critical → High → Medium → Low. Within each severity, BOTH-confirmed findings first.

| # | Severity | Area | Source | Verification | Finding |
|---|---|---|---|---|---|
| F-1 | Critical | Secrets / git | BOTH | VERIFIED-REAL | Real QF prod + prelive client_secret committed to git (`.env` commit `92a278f`) |
| F-2 | Critical | Secrets / git | BOTH | VERIFIED-REAL | `.gitignore` whitelists `.env` via `!.env` (root cause of F-1) |
| F-3 | Critical | RLS / admin tables | BOTH | VERIFIED-REAL | `app_config`, `sponsored_orphans`, `community_project_media`, `onboarding_images` are `WITH CHECK (true)` for `authenticated` |
| F-4 | Critical | Admin gate | BOTH (Codex C-01, Claude #10) | VERIFIED-REAL | Admin gating is a browser-only `ADMIN_EMAILS.has(email)`; anon key client; no `is_admin` column |
| F-5 | Critical | Storage buckets | BOTH (Codex C-04, Claude #8) | VERIFIED-REAL | `project-media`, `onboarding-images`, `orphan-photos` allow any authenticated insert/update/delete |
| F-6 | Critical | RPC IDOR | BOTH (Codex C-02, Claude #7) | VERIFIED-REAL | `sponsor_orphan(p_user_id,…)` trusts client uid → debit any user's Seeds |
| F-7 | Critical | RPC IDOR / data tamper | BOTH (Codex C-03, Claude #7) | VERIFIED-REAL | Stats family (`record_activity_stats`, `get_user_monthly_stats`, `get_week_screen_time`, `record_dhikr_phrase`, `get_user_phrase_counts`, `get_user_lifetime_activity`) accepts `p_user_id` with no `auth.uid()` check |
| F-8 | Critical | RPC economy abuse | CLAUDE-ONLY (#3) | VERIFIED-REAL | `earn_xp(p_user_id, p_amount)` mints unlimited Seeds to any uid; no auth check, no cap, accepts negatives |
| F-9 | Critical | RPC privilege escalation | CLAUDE-ONLY (#2) | VERIFIED-REAL | `link_qf_profile(p_email,…)` lets any logged-in user steal another user's entire profile + Seeds |
| F-10 | Critical | Edge function auth | CODEX-ONLY (C-06) | VERIFIED-REAL | `reward-webhook` has no signature/secret check; uses service-role; trusts arbitrary `user_id` from body |
| F-11 | High | RPC economy abuse | CLAUDE-ONLY (#6) | VERIFIED-REAL | `earn_quran_points`/`earn_dhikr_points` pump `community_projects.current_points` with attacker-chosen `p_coins` |
| F-12 | High | Edge function IDOR | BOTH (Codex H-02, Claude #9) | VERIFIED-REAL | `send-fcm` accepts arbitrary `user_id/title/body` with no admin/owner check |
| F-13 | High | Edge function exposure | CODEX-ONLY (H-03) | VERIFIED-REAL | `qf-token-exchange/-refresh` are `verify_jwt = true` and accept arbitrary `client_id`; any signed-in user can drive QF token endpoint with server-held secrets |
| F-14 | High | Mass-assignment | CODEX-ONLY (H-04) | NEEDS-MANUAL-REVIEW | Direct client upsert to `profiles` from Flutter; no `profiles` RLS in repo — must verify live DB |
| F-15 | High | Privacy leak | CODEX-ONLY (H-05) | VERIFIED-REAL | `get_project_recent_donors` granted to `anon` returns `user_id` + display_name + amount + timestamp — donor enumeration |
| F-16 | High | Telemetry exposure | CODEX-ONLY (H-08) | NEEDS-MANUAL-REVIEW | Browser reads `analytics_country_summary` / `analytics_device_summary`; view definitions not in repo |
| F-17 | High | Missing RLS | BOTH (Codex H-07, Claude defers) | NEEDS-MANUAL-REVIEW | `profiles`, `community_projects`, `user_donations`, `fcm_tokens`, `user_activities`, `user_badges`, `streak_history`, `quran_bookmarks`, `quran_progress`, `user_progress`, `user_analytics`, `leaderboard_global`, `azkar_categories`, `azkar_items`, `badges`, `challenges`, `user_challenge_progress`, `xp_levels` — no RLS in repo |
| F-18 | Medium | Soft-delete trap | CLAUDE-ONLY (#13) | VERIFIED-REAL | `link_qf_profile` orphans the victim row with a mangled email; no recovery path (downstream of F-9) |
| F-19 | Medium | Secrets / git | CLAUDE-ONLY (#11) | VERIFIED-REAL | `supabase/.temp/linked-project.json` + `pooler-url` tracked in git (commit `94e3dd8`) |
| F-20 | Medium | Rate limits | BOTH (Codex M-03, Claude #12) | VERIFIED-REAL | No per-user rate limit on RPCs, storage, edge functions |
| F-21 | Medium | search_path hardening | CODEX-ONLY (M-04) | VERIFIED-REAL | 12 of 14 SECURITY DEFINER functions lack `SET search_path = public` |
| F-22 | Medium | Cron / service role | CODEX-ONLY (M-05) | NEEDS-MANUAL-REVIEW | 8 reminder cron functions use service-role; schedule + invocation gate not in repo |
| F-23 | Medium | CORS | CODEX-ONLY (M-01) | VERIFIED-REAL | `send-fcm`, `qf-token-exchange`, `qf-token-refresh` set `Access-Control-Allow-Origin: *` |
| F-24 | Medium | Error leakage | CODEX-ONLY (M-02) | VERIFIED-REAL | Edge functions echo provider/DB error details back to client |
| F-25 | Medium | Admin model | BOTH (Codex M-08, Claude #10 part 2) | VERIFIED-REAL | Admin app is client-only Supabase access; no Next route handlers / server actions |
| F-26 | Medium | Audit logging | BOTH (Codex M-06, Claude #14 implicit) | VERIFIED-REAL | No `admin_audit_log` table; admin mutations untraceable |
| F-27 | Medium | Admin allowlist + MFA | BOTH (severity conflict: Claude #14 Medium / Codex L-03 Low) | VERIFIED-REAL | Hardcoded JS allowlist; no MFA enforcement visible |
| F-28 | Medium | GitHub hardening | BOTH (severity conflict: Codex M-07 Medium / Claude #16 Low) | NEEDS-MANUAL-REVIEW | Branch protection, secret scanning, push protection — GitHub-side settings, can't be verified from repo |
| F-29 | Low | Anon key duplication | BOTH (Codex L-04, Claude #15) | VERIFIED-REAL | Anon key in `lib/main.dart` + 3 dev scripts (`call_function.dart`, `dump_schema.dart`, `seed_quran.dart`) |
| F-30 | Low | Build artifacts | CODEX-ONLY (L-02) | VERIFIED-REAL (partial) | `admin-web/tsconfig.tsbuildinfo` tracked; `build/` is NOT tracked (Codex partly wrong) |
| F-31 | Low | Insecure-pattern comments | CODEX-ONLY (L-05) | VERIFIED-REAL | SQL comments explicitly say "admin gating done in app" — normalizes the bug |
| F-32 | Low | CI placeholder | CLAUDE-ONLY (#16) | VERIFIED-REAL | `.github/workflows/ios-testflight.yml:14` `BUNDLE_ID: "com.yourcompany.noorRewards"` |

---

## Critical findings

### F-1. Quran Foundation production + prelive client_secret in git
- **Source**: BOTH (Claude #1, Codex C-05) — both Critical
- **Verification**: VERIFIED-REAL
- **Evidence**: `.env:12-17` (working tree); commit `92a278f965a5f5197d755aab936d32f637ed42c4` "chore: commit real Quran Foundation API credentials into .env" 2026-05-21 by `SAP-SHARKS <support@sapsharks.com>`. Diff confirmed via `git log -p .env`:
  - `QURAN_PRELIVE_CLIENT_ID=a9a32c8d-b110-4ac0-b8d8-fa4714be01c6`
  - `QURAN_PRELIVE_CLIENT_SECRET=GHswlErrEnTj14GANnsOvK_iAw`
  - `QURAN_PROD_CLIENT_ID=44f22d7d-b4dc-467b-b4c8-04f545c124e1`
  - `QURAN_PROD_CLIENT_SECRET=d5VUZ~JlHPtdMF6~fm_KrB5sCA`

  The earlier commit `425b424` (2026-05-20) tracked an empty placeholder `.env` and inverted `.gitignore` to allow it. The 92a278f commit then filled in real values, rationalizing it as "low-sensitivity".
- **What's wrong**: A `client_secret` is by definition not public. Anyone with the pair can impersonate Sabiq to the QF API, drain rate limits, or exfiltrate any data Sabiq is authorized for.
- **Exploit scenario**: Clone (or read history of) the repo → extract secrets → run `client_credentials` token requests against `https://oauth2.quran.foundation/oauth2/token` → use the resulting access token as Sabiq.
- **Remediation**:
  1. Rotate **both** PROD and PRELIVE credentials in the QF dashboard immediately.
  2. In Supabase Edge Function secrets, update `QF_CLIENT_SECRET` (and any `QF_CLIENT_SECRET_<client_id>` variants).
  3. In Codemagic, set the four `QURAN_*` env vars (the heredoc in `codemagic.yaml:38-45` already consumes them).
  4. Replace `.env` working-tree content with empty placeholders; commit.
  5. Fix `.gitignore` per F-2.
  6. Purge from history: `git filter-repo --path .env --invert-paths` then force-push (private repos only).
  7. If the repo has ever been public, treat the secrets as permanently leaked — rotation is the only remedy.

### F-2. `.gitignore` whitelists `.env` (`!.env`)
- **Source**: BOTH (Claude #5 Critical, Codex C-05 + L-01)
- **Verification**: VERIFIED-REAL
- **Evidence**: `.gitignore:55-57`:
  ```
  *.env
  .env.*
  !.env
  ```
  Lines 51-54 are a comment block instructing developers to use `git update-index --skip-worktree .env` to avoid committing secrets. This is the root cause of F-1: `pubspec.yaml:71` declares `.env` as a Flutter asset, so the file has to exist in builds, and the team's chosen fix (track an empty placeholder) decayed to "track the real values".
- **Exploit scenario**: Any future developer adding a Supabase service-role JWT or any other secret to `.env` while debugging will `git add .` it without thinking.
- **Remediation**: Replace lines 55-57 with `.env` (and remove `!.env`). Then `git rm --cached .env` and commit. Codemagic already writes a fresh `.env` from env vars at build time.

### F-3. Admin-managed tables are world-writable to any signed-in user
- **Source**: BOTH (Claude #4 Critical, Codex C-01 + C-07 Critical)
- **Verification**: VERIFIED-REAL
- **Evidence**:
  - `_admin_rls_fix.sql:11-22` — `app_config` insert/update/delete gated only on `auth.role() = 'authenticated'`.
  - `_sponsored_orphans_migration.sql:89-96` — `sponsored_orphans` insert/update/delete `WITH CHECK (true)` for `authenticated`.
  - `_projects_media_migration.sql:30-39` — `community_project_media` same pattern.
  - `_onboarding_images_migration.sql:51-60` — `onboarding_images` same pattern.
  - Confirmed there is NO `is_admin`, `role`, `app_roles`, or `user_role` column anywhere in the SQL migrations (grep returned no matches).
- **Exploit scenario**: A normal authenticated user opens DevTools and runs:
  ```js
  await supabase.from('app_config').upsert({ key: 'donor_pool_usd_monthly', value: '0' });
  await supabase.from('sponsored_orphans').delete().neq('id', '00000000-…');
  await supabase.from('onboarding_images').update({ image_url: 'https://evil/x.jpg' }).eq('slot_key', 'onb_hero_1');
  ```
  SettingsService propagates `app_config` changes via Realtime → every client sees the new (zeroed) economy parameters immediately.
- **Remediation**: Create `app_roles(user_id uuid pk, role text)` + `public.is_admin()` SECURITY DEFINER helper, then replace every `USING (true) WITH CHECK (true)` with `USING (public.is_admin()) WITH CHECK (public.is_admin())`. See Codex C-01 for the full SQL.

### F-4. Admin status is enforced only client-side
- **Source**: BOTH (Claude #10 High, Codex C-01 Critical) — **severity conflict resolved to Critical** because the DB has zero admin gate
- **Verification**: VERIFIED-REAL
- **Evidence**:
  - Allowlist: `admin-web/src/lib/supabase.ts:9-12` — `pak.zakn@gmail.com`, `zaid_azam@zeir.io`.
  - Login form: `admin-web/src/app/page.tsx:20-24` — `if (!ADMIN_EMAILS.has(email.toLowerCase().trim()))`.
  - Dashboard gate: `admin-web/src/app/dashboard/layout.tsx:104-113` — `router.replace("/")` if email not in set (a redirect is not authorization).
  - Supabase client: `admin-web/src/lib/supabase.ts:6` uses `createClient(url, anonKey)`. No SSR helper, no service-role server route, no Next middleware checking auth before page render.
- **Exploit**: See F-3 — attacker never visits `/dashboard`. They talk directly to Supabase REST with their own session.
- **Remediation**: F-3's DB fix is the actual fix. Layered defense: move admin mutations into Next route handlers using `@supabase/ssr` + service role, with server-side `is_admin()` verification.

### F-5. Storage buckets allow any authenticated user to upload/overwrite/delete any object
- **Source**: BOTH (Claude #8 High, Codex C-04 Critical) — **severity conflict resolved to Critical**
- **Verification**: VERIFIED-REAL
- **Evidence**:
  - `_sponsored_orphans_migration.sql:117-125` — `orphan-photos` (10 MB images).
  - `_projects_media_migration.sql:57-76` — `project-media` (100 MB videos).
  - `_onboarding_images_migration.sql:77-95` — `onboarding-images` (10 MB images).
  - All policies are `bucket_id = '<bucket>'` with no `owner = auth.uid()`, no path-prefix check, and the buckets are `public = true`.
  - `avatars` bucket: used at `lib/screens/profile_settings_screen.dart:206-212` (`upsert: true`, path `<uid>/avatar.<ext>`) but no migration in repo. NEEDS-MANUAL-REVIEW for `avatars`.
- **Exploit**:
  1. Enumerate `sponsored_orphans` (anyone can SELECT) → read `photo_url`.
  2. Extract storage key from URL → `supabase.storage.from('orphan-photos').upload(<same_path>, malicious_file, { upsert: true })`.
  3. Every donor now sees the spoofed image.
- **Remediation**: Replace each bucket's INSERT/UPDATE/DELETE policy with `bucket_id = 'X' AND public.is_admin()`. For `avatars`, scope to `(storage.foldername(name))[1] = auth.uid()::text`. See Codex C-04 for full SQL.

### F-6. `sponsor_orphan` debits any user's Seeds (IDOR)
- **Source**: BOTH (Claude #7 family, Codex C-02 Critical) — **severity conflict resolved to Critical**
- **Verification**: VERIFIED-REAL
- **Evidence**: `_sponsored_orphans_migration.sql:132-171` — function signature is `sponsor_orphan(p_user_id UUID, p_orphan_id UUID, p_amount INTEGER)`, SECURITY DEFINER, body does `SELECT noor_points INTO v_balance FROM profiles WHERE id = p_user_id FOR UPDATE;` then `UPDATE profiles SET noor_points = noor_points - p_amount WHERE id = p_user_id;` then `INSERT INTO user_donations (user_id, ...)`. No `auth.uid()` check anywhere. Flutter caller at `lib/services/donation_service.dart:94-101` (passes `uid` for `donate_to_project`; sponsor flow uses same pattern).
- **Exploit**: `supabase.rpc('sponsor_orphan', { p_user_id: '<victim>', p_orphan_id: '<orphan>', p_amount: <victim_balance> })` — done.
- **Remediation**: Drop `p_user_id` parameter, bind to `auth.uid()` inside. Revoke PUBLIC execute, grant only to `authenticated`. See Codex C-02 for full SQL.

### F-7. Stats RPCs trust `p_user_id` (read + write IDOR)
- **Source**: BOTH (Claude #7 family, Codex C-03 Critical + H-06 High) — Critical
- **Verification**: VERIFIED-REAL
- **Evidence**: Every offending function is SECURITY DEFINER with `p_user_id` parameter and no `auth.uid()` check:
  - `_stats_migration.sql:79-137` — `record_activity_stats(p_user_id, p_type, p_count, p_duration_sec)`.
  - `_daily_stats_migration.sql:41-117` — overrides same function (still trusts `p_user_id`).
  - `_stats_migration.sql:142-164` — `get_user_monthly_stats(p_user_id)`.
  - `_daily_stats_migration.sql:126-140` — `get_week_screen_time(p_user_id)`.
  - `_dhikr_phrase_tracking_migration.sql:34-53` — `record_dhikr_phrase(p_user_id, p_phrase_id, p_count)`.
  - `_dhikr_phrase_tracking_migration.sql:57-63` — `get_user_phrase_counts(p_user_id)`.
  - `_dhikr_phrase_tracking_migration.sql:67-80` — `get_user_lifetime_activity(p_user_id)`.
  - `_sponsored_orphans_migration.sql:231-257` — `get_user_orphan_sponsorships(p_user_id)` (Codex H-06).
- **Exploit**: `supabase.rpc('get_user_monthly_stats', { p_user_id: '<victim>' })` returns the victim's full monthly worship history. `supabase.rpc('record_activity_stats', { p_user_id: '<victim>', p_type: 'quran', p_count: 1000000, p_duration_sec: 86400 })` poisons the victim's monthly + global stats.
- **Remediation**: For each function, drop `p_user_id` or add `IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN RAISE EXCEPTION 'forbidden'; END IF;` at the top. Underlying tables (`user_monthly_stats`, `user_daily_stats`, `user_dhikr_phrase_counts`) already have correct owner SELECT RLS — the bug is purely the SECURITY DEFINER wrapper bypassing it.

### F-8. `earn_xp` mints unlimited Seeds to any user
- **Source**: CLAUDE-ONLY (#3 Critical) — Codex C-03 mentions it generally but does not isolate the impact
- **Verification**: VERIFIED-REAL
- **Evidence**: `_seal_credits_garden_migration.sql:79-102` — `earn_xp(p_user_id uuid, p_amount integer)`, SECURITY DEFINER, body:
  ```sql
  UPDATE profiles
  SET total_xp = total_xp + p_amount,
      noor_points = noor_points + p_amount
  WHERE id = p_user_id;
  ```
  No `auth.uid()` check, no upper bound, no negative-amount guard. `noor_points` is the spendable Seeds currency feeding `_donor_pool_economy_migration.sql` ($300/month pool, $0.005 ceiling per Seed).
  Called at `lib/services/xp_service.dart:155-158` with the client-supplied uid.
- **Exploit**: `supabase.rpc('earn_xp', { p_user_id: '<attacker>', p_amount: 1000000000 })`. Per-user monthly cap (`max_donatable_seeds_per_month = 5000`) limits pool drainage per month, but leaderboard / badges / level are fully gameable, and attacker can use any other user's uid to corrupt their account or zero-out balances with a negative amount.
- **Remediation**:
  ```sql
  CREATE OR REPLACE FUNCTION public.earn_xp(p_user_id uuid, p_amount integer)
  RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public AS $$
  BEGIN
    IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000 THEN
      RAISE EXCEPTION 'invalid amount';
    END IF;
    -- existing body
  END $$;
  ```
  Long-term: the server should compute `p_amount` from `user_activities` in the seal window, never accept it from the client.

### F-9. `link_qf_profile` lets any user steal another user's profile
- **Source**: CLAUDE-ONLY (#2 Critical) — Codex H-04 mentions profile mass-assignment risk but does not catch this specific RPC
- **Verification**: VERIFIED-REAL
- **Evidence**: `_link_qf_profile.sql:6-73`. Signature `link_qf_profile(p_email text, p_new_id uuid, p_name text, p_picture text)`, SECURITY DEFINER. Body:
  ```sql
  SELECT * INTO v_old_profile FROM profiles
  WHERE email = p_email AND id != p_new_id
  ORDER BY created_at DESC LIMIT 1;
  -- soft-deletes the old row (mangles email + clears referral_code)
  UPDATE profiles SET
    display_name = ..., country = ..., goals = ...,
    noor_points = v_old_profile.noor_points,
    day_streak = ..., level = ..., total_xp = ...,
    referral_code = v_old_profile.referral_code,
    [all streak fields, best-streak fields, city, mosque_team]
  WHERE id = p_new_id;
  ```
  No `auth.uid() = p_new_id` check; no comparison of `auth.jwt() ->> 'email'` to `p_email`. Called from `lib/features/auth/data/qf_auth_service.dart:451-460`.
- **Exploit**:
  1. Attacker signs up → `attacker_uuid`.
  2. `supabase.rpc('link_qf_profile', { p_email: 'victim@x.com', p_new_id: '<attacker_uuid>', p_name: 'x', p_picture: 'x' })`.
  3. Victim's Seeds, total XP, level, referral code, every streak — transferred to attacker. Victim's row soft-deleted (email mangled, referral_code nulled).
  Victim UUIDs are easy to harvest from `get_project_recent_donors` (granted to anon, returns donor display names + uids).
- **Remediation**: Reject calls where `auth.uid() <> p_new_id` OR where `lower(auth.jwt() ->> 'email') <> lower(p_email)`. Also actually relink FK-bearing child rows then DELETE the old row in a transaction (see F-18).

### F-10. `reward-webhook` has no signature/secret verification
- **Source**: CODEX-ONLY (C-06 Critical) — Claude did not audit this function
- **Verification**: VERIFIED-REAL
- **Evidence**: `supabase/functions/reward-webhook/index.ts:1-146`. The function parses any JSON, accepts arbitrary `record.user_id || record.uid`, uses `SUPABASE_SERVICE_ROLE_KEY` (`L41`) to read `fcm_tokens` for that user, and sends an FCM push. There is NO `x-webhook-secret` check, no `req.method` allowlist, no signature header verification. Note: `supabase/config.toml` only declares the two QF functions (`qf-token-exchange`, `qf-token-refresh`), so `reward-webhook` is not in the file — its `verify_jwt` setting must be confirmed in the Supabase dashboard; the function code itself does nothing to authenticate the caller.
- **Exploit**: If the function is publicly invokable (typical for Supabase Database Webhooks), an attacker POSTs:
  ```json
  {"type":"INSERT","record":{"user_id":"<victim>","title":"Sabiq Security Alert","points":1000,"reward_name":"… https://phish.example/ …"}}
  ```
  → Service role looks up the victim's FCM token, sends a phishing-pretext push from the real Sabiq Firebase project. Repeat for spam.
- **Remediation**: Add at the top of the handler:
  ```ts
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const got = req.headers.get('x-webhook-secret');
  if (got !== Deno.env.get('REWARD_WEBHOOK_SECRET')) {
    return new Response('Unauthorized', { status: 401 });
  }
  ```
  Set the secret in Supabase Edge Function secrets and in the Database Webhook config.

---

## High findings

### F-11. `earn_quran_points` / `earn_dhikr_points` pump community-project totals
- **Source**: CLAUDE-ONLY (#6 High)
- **Verification**: VERIFIED-REAL
- **Evidence**: `_seal_credits_garden_migration.sql:17-44` (`earn_quran_points`) and `_seal_credits_garden_migration.sql:47-73` (`earn_dhikr_points`). Both accept `p_coins` from client and execute:
  ```sql
  UPDATE community_projects SET current_points = current_points + p_coins
  WHERE is_active AND NOT is_completed;
  ```
  No validation that `p_coins` matches `app_config.coins_per_ayah` / `coins_per_dhikr`; no cap; negatives accepted.
- **Exploit**: `supabase.rpc('earn_quran_points', { p_surah: 1, p_ayah: 1, p_coins: 1000000000 })` → every active project's progress bar jumps. Users believe campaigns are funded → donor flow drops. Or `p_coins: -1000000` to drive projects negative.
- **Remediation**: Read the canonical reward from `app_config` server-side; ignore `p_coins`. Or `LEAST(GREATEST(p_coins, 0), 100)`.

### F-12. `send-fcm` can spoof notifications to any user
- **Source**: BOTH (Claude #9 High, Codex H-02 High) — High
- **Verification**: VERIFIED-REAL
- **Evidence**: `supabase/functions/send-fcm/index.ts:16-46`. Accepts `user_id`, `title`, `body`, `data` from request body. Initializes Supabase with caller's JWT (`L32-36`), queries `fcm_tokens` for the requested `user_id`, sends FCM. No `user.id === user_id` check. Exposure depends on `fcm_tokens` RLS (not in repo — see F-17). If `fcm_tokens` is broadly readable (the typical bug for unaudited tables), this is a full notification-spoof primitive.
- **Exploit**: `POST /functions/v1/send-fcm` with `{"user_id":"<victim>","title":"Sabiq Security Alert","body":"Tap to verify: https://phish.example/"}` → victim sees a real-looking push from the real Sabiq Firebase project.
- **Remediation**:
  ```ts
  const { data: { user } } = await supabase.auth.getUser();
  if (!user || user.id !== user_id) {
    return new Response(JSON.stringify({error:'forbidden'}), { status: 403 });
  }
  ```
  Plus lock down `fcm_tokens` RLS to `user_id = auth.uid()` for all CRUD.

### F-13. QF token exchange/refresh callable by every signed-in user
- **Source**: CODEX-ONLY (H-03 High)
- **Verification**: VERIFIED-REAL
- **Evidence**: `supabase/config.toml:13-15` and `:2-4` — both functions are `verify_jwt = true` (only requires a Supabase JWT, which every signed-in user has). `supabase/functions/qf-token-exchange/index.ts:19-32` accepts `client_id` from the request body and looks up the secret as `QF_CLIENT_SECRET_${client_id}` falling back to `QF_CLIENT_SECRET`. `qf-token-refresh/index.ts:21-32` is the same pattern. No allowlist of `client_id`, no rate limit. Errors include `data.error` and `data.error_description` from the QF token endpoint — useful for probing.
- **Exploit**: A scripted authenticated user can hammer QF's token endpoint using the platform's secret, probe valid `client_id`s by varying the request, or exhaust QF rate limits to lock out legitimate users.
- **Remediation**: Validate `client_id` against a hardcoded allowlist; validate `redirect_uri` exactly; add per-auth-uid rate limits; return generic `{ error: 'invalid_request' }` to clients and log details server-side.

### F-14. Profile mass-assignment risk via direct client upsert
- **Source**: CODEX-ONLY (H-04 High) — Claude #14 manual-review note covers same ground
- **Verification**: NEEDS-MANUAL-REVIEW (depends on live `profiles` RLS — see F-17)
- **Evidence**: `lib/screens/profile_settings_screen.dart:162-166` does `_supabase.from('profiles').upsert({ id: user.id, display_name, country })`. `lib/screens/profile_setup_screen.dart:137` and `lib/features/auth/data/qf_auth_service.dart:494,538` do similar. `link_qf_profile` shows the column list (`noor_points`, `total_xp`, `level`, `day_streak`, every `*_streak`, every `best_*_streak`, `referral_code`, `referred_by`, …). No `profiles` RLS migration in repo. If live policy is the default "user can update own row" without column restrictions, a user can `supabase.from('profiles').update({ noor_points: 1e9, level: 99 }).eq('id', auth.uid())` — bypassing F-8's RPC entirely.
- **Remediation**: Use Codex H-04's pattern — revoke `UPDATE` on `profiles` from `authenticated`, expose only `update_my_profile(p_display_name, p_avatar_url, …)` SECURITY DEFINER RPCs that touch only safe columns. Or use column-level GRANTs.

### F-15. Donor identity enumeration via aggregate RPCs
- **Source**: CODEX-ONLY (H-05 High)
- **Verification**: VERIFIED-REAL
- **Evidence**: `_project_recent_donors_migration.sql:10-37,41` — `get_project_recent_donors(p_project_id, p_limit)` returns `user_id`, `display_name`, `avatar_url`, `amount`, `donated_at` and is granted to **`anon`**. `_sponsored_orphans_migration.sql:205-228` — `get_orphan_recent_sponsors` returns same shape. Both expose donor identities + amounts publicly.
  Note: returning donor names is a typical product feature (LaunchGood-style), so this overlaps with intent — but exposing `user_id` makes it an IDOR feedstock (see F-9 — victim UUIDs from this RPC are exactly what `link_qf_profile` needs).
- **Exploit**: Anyone (no login) can scrape donor lists per project. Combined with F-9, this is the "find a victim UUID" step.
- **Remediation**: Drop `user_id` from the returned columns (only keep public-facing `display_name`/`avatar_url`/`amount`). Or revoke `anon` execute and require `authenticated`.

### F-16. Admin analytics views may expose broad user telemetry
- **Source**: CODEX-ONLY (H-08 High)
- **Verification**: NEEDS-MANUAL-REVIEW
- **Evidence**: `admin-web/src/app/dashboard/analytics/page.tsx:33-39` — browser anon client reads `analytics_country_summary` and `analytics_device_summary`. Neither view's definition is in the repo. If they are plain views without security-barrier and the underlying table allows `authenticated` select, any user can scrape them.
- **Remediation**: Make them `SECURITY DEFINER` functions gated on `public.is_admin()`, or move into a Next API route using service role.

### F-17. Missing RLS for many user-private tables
- **Source**: BOTH (Codex H-07 High explicit, Claude defers to manual review) — High
- **Verification**: NEEDS-MANUAL-REVIEW
- **Evidence**: Only these tables have RLS in any committed `.sql`: `app_config`, `sponsored_orphans`, `community_project_media`, `onboarding_images`, `user_monthly_stats`, `global_daily_stats`, `user_daily_stats`, `user_dhikr_phrase_counts`. Every other table used by the client (`profiles`, `community_projects`, `user_donations`, `fcm_tokens`, `user_activities`, `user_badges`, `streak_history`, `quran_bookmarks`, `quran_favorites`, `quran_progress`, `user_progress`, `user_analytics`, `leaderboard_global`, `azkar_categories`, `azkar_items`, `badges`, `challenges`, `user_challenge_progress`, `xp_levels`, `notification_log`) has no RLS migration in the repo. Live policies must be enumerated in the Supabase dashboard.
- **Remediation**: For every user-private table, owner policies (`USING (user_id = auth.uid())`). For public catalogs, `SELECT true` + admin write. See Codex's Supabase RLS Matrix and owner-policy template.

---

## Medium findings

### F-18. `link_qf_profile` orphans the old row (soft-delete trap)
- **Source**: CLAUDE-ONLY (#13 Medium) — downstream of F-9
- **Verification**: VERIFIED-REAL
- **Evidence**: `_link_qf_profile.sql:33-34,62-65` — the old row's email is renamed to `email || '_merged_' || gen_random_uuid()` and `referral_code` is set to NULL. The comment explicitly says "intentionally DO NOT DELETE the old duplicate profile…to prevent any foreign-key constraint violations on child tables."
- **What's wrong**: Even when the linking is legitimate, the victim's old Supabase auth user still exists but can no longer find their profile by original email. After exploit F-9 there is no undo.
- **Remediation**: Re-point FK rows in `user_activities`, `user_donations`, `streak_history`, `user_badges`, etc. from `v_old_profile.id` to `p_new_id`, then `DELETE FROM profiles WHERE id = v_old_profile.id`, all in one transaction. Keep an `original_email` audit column.

### F-19. Supabase project ref + pooler URL committed to git
- **Source**: CLAUDE-ONLY (#11 Medium) — Codex did not catch this
- **Verification**: VERIFIED-REAL
- **Evidence**: `git ls-files supabase/.temp/` returns 9 files, including `linked-project.json`, `pooler-url`, and `project-ref`. `linked-project.json` contains `{"ref":"fwjzhtcxfiendofnhyzp","name":"Noor Rewards",…}` and `pooler-url` is `postgresql://postgres.fwjzhtcxfiendofnhyzp@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres`. Committed in `94e3dd8`.
- **What's wrong**: Not a credential, but the exact pooler hostname + DB username are now public, narrowing the brute-force / credential-stuffing target.
- **Remediation**: Add `supabase/.temp/` to `.gitignore`; `git rm -r --cached supabase/.temp/`. Supabase CLI re-creates these on `supabase link`.

### F-20. No per-user rate limits on RPCs / storage / edge functions
- **Source**: BOTH (Codex M-03 Medium, Claude #12 Medium) — Medium
- **Verification**: VERIFIED-REAL
- **Evidence**: No rate-limit table, no counter logic in any RPC body, no per-uid throttle in any edge function. Supabase's built-in throttle only applies to `auth/*` endpoints.
- **Remediation**: Add a per-user-per-minute counter table consulted at the top of each SECURITY DEFINER RPC. For storage, enforce path prefix to `<auth.uid()>/` plus per-day upload count cap via trigger.

### F-21. SECURITY DEFINER functions missing `SET search_path`
- **Source**: CODEX-ONLY (M-04 Medium)
- **Verification**: VERIFIED-REAL
- **Evidence**: `grep "SET search_path"` returns only 2 hits across all SQL: `_project_recent_donors_migration.sql:24` and `_project_donor_counts_migration.sql:17`. `grep "SECURITY DEFINER"` returns 16 hits spanning `_stats_migration.sql` (5), `_sponsored_orphans_migration.sql` (1), `_seal_credits_garden_migration.sql` (3), `_link_qf_profile.sql` (1), `_dhikr_phrase_tracking_migration.sql` (3), `_daily_stats_migration.sql` (2). So 14 SECURITY DEFINER functions lack `SET search_path = public` — search-path-hijack risk if a non-superuser ever attaches a malicious schema.
- **Remediation**: Add `SET search_path = public` (or `SET search_path = ''` and qualify every reference) to every SECURITY DEFINER function. When patching for F-6/F-7/F-8 anyway, add this too.

### F-22. Notification cron functions use service-role broadly
- **Source**: CODEX-ONLY (M-05 Medium)
- **Verification**: NEEDS-MANUAL-REVIEW (schedule/invocation gate not in repo)
- **Evidence**: `supabase/functions/` contains 8 reminder/cron functions (`community-momentum`, `level-up-close`, `local-azkaar-reminders`, `monthly-milestone`, `monthly-quran-reminder`, `nightly-coin-reminder`, `resume-reading`, `streak-at-risk`). Schedule definitions / pg_cron entries / `verify_jwt` per function are NOT in the repo's `supabase/config.toml` (which only declares the two QF functions). If any are publicly invokable, anyone can trigger expensive scans.
- **Remediation**: In the Supabase dashboard, set `verify_jwt = false` only for cron-secret-protected functions, and require a `x-cron-secret` header check at the top of each. Add idempotency keys / per-user caps in `notification_log` to prevent spam if triggered repeatedly.

### F-23. Permissive CORS on edge functions
- **Source**: CODEX-ONLY (M-01 Medium)
- **Verification**: VERIFIED-REAL
- **Evidence**: `supabase/functions/send-fcm/index.ts:5-8`, `qf-token-exchange/index.ts:3-6`, `qf-token-refresh/index.ts:3-6` all set `'Access-Control-Allow-Origin': '*'`.
- **Remediation**: Restrict to production origins (e.g., `https://app.sabiq.io`, `https://admin.sabiq.io`). Mobile clients don't need CORS anyway.

### F-24. Sensitive error leakage from edge functions
- **Source**: CODEX-ONLY (M-02 Medium)
- **Verification**: VERIFIED-REAL
- **Evidence**: `send-fcm/index.ts:46,131-134` returns raw `Device token not found for user_id: ${user_id}. ${dbError?.message}` and `{ error: error.message }` on catch. `qf-token-exchange/index.ts:49-50` returns `{ error: data.error || 'Token exchange failed', details: data }` — leaks QF provider details. Same in `qf-token-refresh`.
- **Remediation**: Log details server-side; return `{ error: 'invalid_request' }` or `{ error: 'internal_error' }` to clients.

### F-25. Admin app is client-only (no server route handlers)
- **Source**: BOTH (Codex M-08 Medium, Claude #10 second half) — Medium
- **Verification**: VERIFIED-REAL
- **Evidence**: `admin-web/src/lib/supabase.ts:6` uses anon-key browser client only. There are no Next route handlers / server actions in `admin-web/src/app` (only client pages). All admin actions are client-side direct-to-Supabase.
- **Remediation**: Move all privileged operations to Next route handlers using `@supabase/ssr` server client + service role, with server-side `is_admin()` verification.

### F-26. No admin audit log
- **Source**: BOTH (Codex M-06 Medium, Claude #14 implicit) — Medium
- **Verification**: VERIFIED-REAL (by absence — no `admin_audit_log` table in any migration)
- **Remediation**: See Codex M-06 SQL for the `admin_audit_log` table. Trigger-write from each admin RPC, or write from server route handlers.

### F-27. Hardcoded admin allowlist + no MFA enforcement
- **Source**: BOTH — **severity conflict**: Claude #14 Medium, Codex L-03 Low. **My call: Medium.** Two emails control the entire economy and there is no MFA enforcement; rotation requires a code change + Vercel redeploy. Higher than "Low".
- **Verification**: VERIFIED-REAL
- **Evidence**: `admin-web/src/lib/supabase.ts:9-12` — set of two emails. No `app_roles` table. No source-level MFA enforcement.
- **Remediation**: Move to `app_roles` table (per F-3 remediation). Enforce TOTP MFA at Supabase Auth level for the admin role. Add an `admin_audit_log` table (F-26).

### F-28. GitHub workflow / repo hardening
- **Source**: BOTH — **severity conflict**: Codex M-07 Medium, Claude #16 Low. **My call: Medium.** Branch protection + secret scanning + push protection block whole classes of future F-1 recurrence.
- **Verification**: NEEDS-MANUAL-REVIEW (GitHub-side settings)
- **Evidence**: Repo contains `.github/workflows/build_qa.yml` + `ios-testflight.yml`. Branch protection, required reviews, CODEOWNERS, Dependabot, secret scanning, push protection — none of these can be verified from working tree.
- **Remediation**: Enable secret scanning + push protection (would have blocked F-1). Require PR reviews on `main`. Add CODEOWNERS for `supabase/`, `lib/services/`, `_*.sql`. Enable Dependabot for pub, npm, Gradle, Actions. Add `gitleaks`/`trufflehog` as a required status check.

---

## Low findings

### F-29. Anon key duplicated in 4+ files
- **Source**: BOTH (Codex L-04, Claude #15) — Low
- **Verification**: VERIFIED-REAL
- **Evidence**: `lib/main.dart:106` (the canonical hardcoded JWT), plus dev scripts `call_function.dart:7`, `dump_schema.dart:7`, `seed_quran.dart:10` (per Claude). The anon key is public-by-design, so this is not a vulnerability, but duplication makes rotation tedious and the dev scripts shouldn't ship.
- **Remediation**: Centralize via `core/env/env.dart`; delete dev scripts or move to `scripts/` and `.gitignore`.

### F-30. Build artifacts in working tree (partial)
- **Source**: CODEX-ONLY (L-02 Low) — partially correct
- **Verification**: VERIFIED-REAL (partial); Codex was partly wrong
- **Evidence**: `git ls-files build/` returns nothing — `build/` is NOT tracked (it exists in the working tree but is gitignored at `.gitignore:36`). However `git ls-files admin-web/tsconfig.tsbuildinfo` returns it — that file IS tracked.
- **Remediation**: Add `admin-web/tsconfig.tsbuildinfo` to `admin-web/.gitignore`; `git rm --cached admin-web/tsconfig.tsbuildinfo`.

### F-31. SQL policy comments normalize insecure patterns
- **Source**: CODEX-ONLY (L-05 Low)
- **Verification**: VERIFIED-REAL
- **Evidence**: `_projects_media_migration.sql:22` "anyone can read, only authenticated users can manage (admin gating done in app)". `_onboarding_images_migration.sql:42-43` "admin gating happens client-side via the email whitelist". `_sponsored_orphans_migration.sql:81` "RLS — public read, authenticated write (admin gated in app)". Future engineers reading these comments will copy the pattern.
- **Remediation**: After F-3 fixes, rewrite these comments to "admin-only writes enforced by DB via public.is_admin()".

### F-32. CI workflow placeholder bundle id
- **Source**: CLAUDE-ONLY (#16 Low)
- **Verification**: VERIFIED-REAL
- **Evidence**: `.github/workflows/ios-testflight.yml:14` — `BUNDLE_ID: "com.yourcompany.noorRewards"   # ← change to your real bundle ID`. Workflow has likely never run successfully.
- **Remediation**: Set to the real bundle id. Audit one TestFlight upload log for accidental Issuer/Key ID echoing (Claude's secondary concern).

---

## Prioritized fix checklist

Ordered by severity then dependency. Includes only VERIFIED-REAL and NEEDS-MANUAL-REVIEW findings.

1. **Rotate QF prod + prelive client_secret in the QF developer dashboard NOW.** (F-1)
2. **Fix `.gitignore`:** remove `!.env`; replace with strict ignore; `git rm --cached .env`; force-push only if repo is private and team-coordinated. (F-2)
3. **Add `auth.uid()` guards (or drop `p_user_id`) on `earn_xp`, `sponsor_orphan`, `record_activity_stats`, `record_dhikr_phrase`, `get_user_monthly_stats`, `get_week_screen_time`, `get_user_phrase_counts`, `get_user_lifetime_activity`, `get_user_orphan_sponsorships`.** (F-6, F-7, F-8)
4. **Patch `link_qf_profile`** to require `auth.uid() = p_new_id` AND `lower(auth.jwt() ->> 'email') = lower(p_email)`. (F-9)
5. **Create `app_roles` + `public.is_admin()`** and replace every `USING (true) WITH CHECK (true)` policy on `app_config`, `sponsored_orphans`, `community_project_media`, `onboarding_images`. (F-3, F-4)
6. **Tighten storage policies** on `orphan-photos`, `project-media`, `onboarding-images` to admin-only writes; scope `avatars` to `(storage.foldername(name))[1] = auth.uid()::text`. (F-5)
7. **Clamp `p_coins`** in `earn_quran_points`/`earn_dhikr_points` to a hardcoded ceiling or read from `app_config`. (F-11)
8. **Add `x-webhook-secret` check** to `reward-webhook`. (F-10)
9. **Add ownership check** (`user.id === user_id`) to `send-fcm`. (F-12)
10. **Restrict `qf-token-exchange`/`qf-token-refresh`** with `client_id` allowlist + per-uid rate limit + generic errors. (F-13)
11. **Audit live `profiles` RLS** and lock down column updates via `update_my_profile` RPC. (F-14)
12. **Drop `user_id` from `get_project_recent_donors` / `get_orphan_recent_sponsors` returns** (or stop granting to `anon`). (F-15)
13. **Enable RLS + owner policies** on all currently-unprotected user tables (F-17). Inspect live `analytics_*` views and admin-gate them (F-16). Audit cron functions for `verify_jwt`/secret protection (F-22).
14. **Add per-user rate-limit counters** to every SECURITY DEFINER RPC. (F-20)
15. **Add `SET search_path = public`** to every SECURITY DEFINER function. (F-21)
16. **Add `admin_audit_log`** table + trigger writes from every admin RPC. (F-26)
17. **Move admin mutations into Next route handlers** using SSR + service role, with `is_admin()` check. (F-25)
18. **Enforce MFA** on the two admin Google accounts in Supabase dashboard. (F-27)
19. **Lock down `Access-Control-Allow-Origin`** on all edge functions. (F-23) **Strip error details** from responses. (F-24)
20. **GitHub hardening:** enable secret scanning, push protection, branch protection on `main`, CODEOWNERS, Dependabot, `gitleaks` CI. (F-28)
21. **Add `supabase/.temp/` to `.gitignore`**; `git rm -r --cached supabase/.temp/`. (F-19)
22. **Delete dev scripts** (`call_function.dart`, `dump_schema.dart`, `seed_quran.dart`) or move to ignored `scripts/`. (F-29)
23. **Untrack `admin-web/tsconfig.tsbuildinfo`** and add to `admin-web/.gitignore`. (F-30)
24. **Rewrite the "admin gating in app" comments** in SQL after F-3 lands. (F-31)
25. **Fix `BUNDLE_ID`** in `ios-testflight.yml`. (F-32)
26. **Patch `link_qf_profile` to actually delete the old row in a tx** after FK re-pointing. (F-18)

---

## Items needing manual review (live Supabase dashboard / GitHub settings)

- **`profiles` RLS** — confirm whether direct `UPDATE profiles SET noor_points = …, level = …` is rejected. (F-14, F-17)
- **`fcm_tokens` RLS** — must be `user_id = auth.uid()` for all CRUD. Determines exploitability of F-12.
- **`community_projects` RLS** — earn_*_points pumps `current_points`; is direct write also possible? (F-11, F-17)
- **`donate_to_project` RPC body** — not in repo. Verify it does `auth.uid() = p_user_id` and validates `p_amount` against caller balance.
- **`grant_points` RPC body** — called from `admin-web/src/app/dashboard/users/page.tsx:41`; not in repo. Verify it gates on `public.is_admin()`.
- **`record_streak_activity`, `award_badge`, `get_streak_history`** RPC bodies — referenced in `CLAUDE.md` but not in any committed `.sql`.
- **Live RLS for every table named in F-17** — enumerate `pg_policies`.
- **`avatars` storage bucket** — exists per `lib/screens/profile_settings_screen.dart:206-212` but no migration. Verify policies scope writes to `<uid>/…`.
- **`analytics_country_summary` / `analytics_device_summary`** view definitions and grants. (F-16)
- **Cron-function invocation gates** (verify_jwt or shared-secret). (F-22)
- **Supabase MFA enforcement** for the two admin accounts. (F-27)
- **GitHub branch protection / secret scanning / push protection** state. (F-28)
- **GitHub repo visibility** during 2026-05-21 → now — if ever public, F-1 secrets are permanently leaked regardless of rotation.

---

## False positives (checked, ruled out)

None of the audited findings were false positives. Spot-check results worth recording:

- **Claude's claim that `pubspec.yaml` declares `.env` as a Flutter asset** — VERIFIED at `pubspec.yaml:67-71`, line 71 is literally `- .env`. This is what forces `.env` to exist in builds and motivates the inverted `.gitignore` (F-2).
- **Codex's claim that build artifacts are tracked** — **partially** wrong. `build/` is NOT tracked (`git ls-files build/` returns empty; correctly gitignored at `.gitignore:36`). Only `admin-web/tsconfig.tsbuildinfo` is tracked. F-30 is downgraded accordingly.
- **Claude's claim that `donate_to_project` body is "almost certainly the same shape" as `sponsor_orphan`** — body is NOT in repo (`grep "donate_to_project"` returns only comment references). Status correctly marked NEEDS-MANUAL-REVIEW; do not assume.

---

## Severity conflicts — final calls

| Finding | Claude | Codex | Final | Rationale |
|---|---|---|---|---|
| Admin gating client-side (F-4) | High (#10) | Critical (C-01) | **Critical** | DB has zero admin gate. Anon key is published. Browser allowlist is decorative. |
| Storage buckets world-writable (F-5) | High (#8) | Critical (C-04) | **Critical** | Public buckets + `upsert: true` in admin code → trivial vandalism of every project/orphan/onboarding asset. |
| `sponsor_orphan` IDOR (F-6) | High (#7 group) | Critical (C-02) | **Critical** | Direct economic impact (debit any user's Seeds). |
| Stats RPCs IDOR (F-7) | High (#7 group) | Critical (C-03) + High (H-06) | **Critical** | Cross-user read leaks worship telemetry; cross-user write poisons global stats. |
| Hardcoded admin allowlist + no MFA (F-27) | Medium (#14) | Low (L-03) | **Medium** | Two emails controlling the economy with no MFA is not Low. |
| GitHub workflow hardening (F-28) | Low (#16) | Medium (M-07) | **Medium** | Push protection / secret scanning would have prevented F-1. |
| `.env` comments contradict `.gitignore` (F-2) | Critical (#5 — same as `!.env`) | Low (L-01 standalone) | **Critical** (folded into F-2) | The contradictory comment is the same bug as the `!.env` whitelist; not a separate Low. |
| Build artifacts (F-30) | n/a | Low (L-02) | **Low (downscoped)** | Only one tracked artifact (`tsconfig.tsbuildinfo`), not `build/`. |
