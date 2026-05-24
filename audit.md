# Noor Rewards / Sabiq — Security Audit
_Performed: 2026-05-24. Auditor: Claude Code._

Scope: `D:\noor_rewards-main\noor_rewards-main` working tree + 238-commit git history. Flutter client (`lib/`), admin web (`admin-web/`), Supabase SQL migrations (root `*.sql`), and Supabase edge functions (`supabase/functions/`). No `supabase/migrations/` directory exists — every database migration in the repo is a loose `_*.sql` file at the project root, applied by hand via the Supabase SQL Editor (verified). RLS for several core tables (`profiles`, `community_projects`, `user_donations`, `app_config`, `fcm_tokens`, `azkar_categories`, `azkar_items`, `community_projects`, `xp_levels`, `badges`, `user_badges`, `user_activities`, `streak_history`, `challenges`, `user_challenge_progress`, `leaderboard_global`, `user_analytics`, `quran_bookmarks`, `quran_favorites`) is **not represented in this repo** — only the `app_config` policy is here (`_admin_rls_fix.sql`). Those tables' RLS state is therefore unknown from source and is called out as NEEDS MANUAL REVIEW.

---

## Summary

| # | Severity | Area | Finding |
|---|---|---|---|
| 1 | Critical | Secrets / git | Real Quran Foundation **production** OAuth2 `client_id` + `client_secret` committed to git (commit `92a278f`) and live in working-tree `.env`. |
| 2 | Critical | RPC / privilege escalation | `link_qf_profile(p_email, p_new_id, …)` is `SECURITY DEFINER` and trusts client-supplied `p_email` — any logged-in user can claim **any other user's profile** (Seeds, streaks, levels, referral code, donations). |
| 3 | Critical | RPC / economy abuse | `earn_xp(p_user_id, p_amount)` is `SECURITY DEFINER` with no `auth.uid()` check and no cap — any user can mint unlimited Seeds (`noor_points`) to themselves or any other user via a single REST call. |
| 4 | Critical | RLS / admin-only data | `sponsored_orphans` RLS lets ANY authenticated user `INSERT`, `UPDATE`, `DELETE` orphan records. Same for `community_project_media`, `onboarding_images`, and `app_config`. Admin-only is enforced only by a client-side email allowlist that an attacker bypasses by calling the REST API directly. |
| 5 | Critical | Secrets / git | `.gitignore` is explicitly inverted to **track** `.env` (`!.env`). Any future secret written into that file is auto-published to the repo. |
| 6 | High | RPC / economy abuse | `earn_quran_points` / `earn_dhikr_points` accept a client-controlled `p_coins` arg AND directly increment `community_projects.current_points` — any signed-in user can pump any project's progress bar by arbitrary millions. |
| 7 | High | RPC / IDOR | `sponsor_orphan`, `donate_to_project` (per call sites), and `get_user_orphan_sponsorships`, `get_user_monthly_stats`, `get_week_screen_time`, `get_user_phrase_counts`, `record_dhikr_phrase`, `record_activity_stats` all take `p_user_id` from the client without comparing to `auth.uid()` — a user can sponsor / donate / write stats / read stats **as another user**. |
| 8 | High | Storage buckets | `project-media` and `orphan-photos` and `onboarding-images` policies let any authenticated user upload, overwrite (`upsert: true`), and delete any file in the bucket — vandalism / brand-spoofing trivially possible. `project-media` allows up to 100 MB video uploads with no per-user quota. |
| 9 | High | Edge function / IDOR | `supabase/functions/send-fcm/index.ts` accepts arbitrary `user_id`, `title`, `body` from the caller and sends an FCM push to that user. Whether it's exploitable hinges on `fcm_tokens` RLS — RLS for `fcm_tokens` is not in the repo (NEEDS MANUAL REVIEW). If the table is readable cross-user, any signed-in user can push spoofed notifications to every other user. |
| 10 | High | Admin gate | Admin status is ONLY enforced client-side (`admin-web/src/lib/supabase.ts:9-12` + `admin-web/src/app/dashboard/layout.tsx:106-109` + `admin-web/src/app/page.tsx:20-24`). The admin web uses the anon key. There is no DB-side `auth.email() = …` guard on `app_config`, `sponsored_orphans`, `community_projects`, `onboarding_images`, etc. |
| 11 | Medium | Secrets / git | Supabase project ref + production pooler URL committed to git (`supabase/.temp/linked-project.json`, `supabase/.temp/pooler-url`). Project ref is not a credential but reveals the target for credential-stuffing / DB brute force. |
| 12 | Medium | Rate limiting | `record_activity_stats`, `earn_xp`, `record_dhikr_phrase` and the storage upload endpoints have no per-user rate limit. A bot can drive `user_daily_stats`, `user_monthly_stats`, `global_daily_stats`, and storage cost to arbitrary values. |
| 13 | Medium | Auth | `_link_qf_profile.sql` deliberately does NOT delete the old profile row — it renames `email` to `email_merged_<uuid>` and clears `referral_code`. Combined with finding #2 this means a victim's old account is permanently "soft-deleted" with no way for them to recover it. |
| 14 | Medium | Admin gate | `ADMIN_EMAILS` is a static hardcoded `Set` in the admin web bundle. Rotating an admin requires a code change + redeploy. Compromise of one of the two admin Google accounts has no MFA enforcement visible in source. |
| 15 | Low | Code hygiene | Anon key + URL hardcoded in 4 places (`lib/main.dart:104-106`, `admin-web/src/lib/supabase.ts:3-4` via env, `call_function.dart:7`, `dump_schema.dart:7`, `seed_quran.dart:10`). Rotating the anon JWT requires source edits. Per-se not a vulnerability (anon keys are public) but increases churn. |
| 16 | Low | CI / hygiene | `.github/workflows/ios-testflight.yml` still references placeholder `com.yourcompany.noorRewards` bundle id, suggesting workflow has never run. `codemagic.yaml` properly injects secrets via env (no leakage). |

---

## Critical findings

### 1. Quran Foundation production secrets committed to git

- **Location**:
  - Working tree: `D:\noor_rewards-main\noor_rewards-main\.env:14-17`
  - Git history: commit `92a278f965a5f5197d755aab936d32f637ed42c4` ("chore: commit real Quran Foundation API credentials into .env"), authored 2026-05-21 by `SAP-SHARKS <support@sapsharks.com>`.
  - `.gitignore:32-43` explicitly whitelists `.env` (`!.env`).
- **What's wrong**: All four QF OAuth2 credentials are in `git log -p .env`:
  - `QURAN_PRELIVE_CLIENT_ID=a9a32c8d-b110-4ac0-b8d8-fa4714be01c6`
  - `QURAN_PRELIVE_CLIENT_SECRET=GHswlErrEnTj14GANnsOvK_iAw`
  - `QURAN_PROD_CLIENT_ID=44f22d7d-b4dc-467b-b4c8-04f545c124e1`
  - `QURAN_PROD_CLIENT_SECRET=d5VUZ~JlHPtdMF6~fm_KrB5sCA`
  The commit message rationalises this as "low-sensitivity" but a `client_secret` is by definition NOT public — anyone with the pair can impersonate the Sabiq app to the QF API, call any endpoint Sabiq is authorised for (bookmark sync, profile reads), and burn through any rate-limit / quota associated with the app's identity.
- **Exploit scenario**: Anyone who clones the repo (or has cloned any historical state since 2026-05-21) extracts the two `*_CLIENT_SECRET` values, then issues `client_credentials` token requests against `https://oauth2.quran.foundation/oauth2/token`. They now hold access tokens that QF will trust as "Sabiq". They can read/write all user data Sabiq is authorised for on QF, or get the app's API key revoked by deliberately exceeding rate limits.
- **Remediation**:
  1. Rotate **both** PROD and PRELIVE credentials in the Quran Foundation developer dashboard immediately.
  2. Move secrets out of `.env`. The repo's `codemagic.yaml:31-45` already supports injecting these from Codemagic env vars — make the placeholder `.env` truly empty.
  3. Fix `.gitignore`: remove `!.env`, add `.env` to ignore list. Use `git update-index --skip-worktree .env` locally instead of whitelisting it.
  4. Purge from git history with `git filter-repo --path .env --invert-paths` then force-push (only if the repo is private). If the repo has ever been public, the secrets are forever compromised — rotation is the only remedy.

### 2. `link_qf_profile` lets any user steal another user's profile

- **Location**: `_link_qf_profile.sql:6-73`. Called from `lib/features/auth/data/qf_auth_service.dart:452-460`.
- **What's wrong**: The RPC is `SECURITY DEFINER` and accepts `p_email` from the client. It then `SELECT … FROM profiles WHERE email = p_email AND id != p_new_id` and copies every progress field (`noor_points`, `total_xp`, `level`, `day_streak`, every streak/best-streak column, `referral_code`, etc.) from the victim's profile into the caller's profile. The victim's row is then soft-deleted by renaming `email` to `email || '_merged_' || gen_random_uuid()` and clearing `referral_code`. There is no check that `auth.uid() = p_new_id` or that the caller has any relation to `p_email`.
- **Exploit scenario**:
  1. Attacker signs up for a fresh Sabiq account → gets `p_new_id = <attacker_uuid>`.
  2. Attacker calls `supabase.rpc('link_qf_profile', { p_email: 'victim@example.com', p_new_id: '<attacker_uuid>', p_name: 'x', p_picture: 'x' })`.
  3. The RPC silently transfers all of `victim@example.com`'s Seeds, total XP, level, referral code, streaks, donation history-link, etc. to the attacker's account, and the victim's account is permanently soft-deleted (email mangled).
  4. Repeat across the entire user base (emails leak from `get_project_recent_donors` -> `profiles` joins, leaderboard, and the donor screen which surfaces `display_name`).
- **Remediation**: Reject calls where `auth.uid()` is not the row owner being claimed, or where `auth.email()` (from the JWT) does not match `p_email`. Example:
  ```sql
  CREATE OR REPLACE FUNCTION link_qf_profile(p_email text, p_new_id uuid, p_name text, p_picture text)
  RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
  BEGIN
    IF auth.uid() IS NULL OR auth.uid() <> p_new_id THEN
      RETURN 'ERROR: forbidden';
    END IF;
    IF lower(coalesce(auth.jwt() ->> 'email','')) <> lower(p_email) THEN
      RETURN 'ERROR: email mismatch';
    END IF;
    -- … existing body …
  END $$;
  ```
  And: actually delete the old row inside a transaction after re-pointing FK rows, instead of orphaning it with a mangled email.

### 3. `earn_xp` lets anyone mint unlimited Seeds to any user

- **Location**: `_seal_credits_garden_migration.sql:79-102`. Called from `lib/services/xp_service.dart:155-158`.
- **What's wrong**: The function signature is `earn_xp(p_user_id uuid, p_amount integer)`, runs `SECURITY DEFINER`, with body:
  ```sql
  UPDATE profiles
  SET    total_xp    = total_xp + p_amount,
         noor_points = noor_points + p_amount
  WHERE  id = p_user_id
  ```
  No `auth.uid() = p_user_id` check, no upper bound on `p_amount`, no negative-amount guard. `noor_points` is the spendable Seeds currency that funds the real-money donor pool (`_donor_pool_economy_migration.sql:16-25` — admin-tunable USD pool, currently $300/month).
- **Exploit scenario**:
  1. Attacker calls `supabase.rpc('earn_xp', { p_user_id: '<attacker_uuid>', p_amount: 1000000000 })`.
  2. Attacker now owns 1 billion Seeds → at the configured max ceiling of `$0.005` per Seed they have technically "earned" up to the entire monthly pool. Per-user cap (`max_donatable_seeds_per_month`, default 5000) limits how much they can drain in a single month but they can still dominate the leaderboard, unlock every badge, and burn through the pool month after month.
  3. Variant: pass another user's UUID and grant them billions of Seeds to inflate the leaderboard or to dilute the donor pool denominator and starve real projects of funding.
  4. Negative `p_amount` also accepted → drain another user's balance to negative.
- **Remediation**:
  ```sql
  CREATE OR REPLACE FUNCTION public.earn_xp(p_user_id uuid, p_amount integer)
  RETURNS integer LANGUAGE plpgsql SECURITY DEFINER AS $$
  DECLARE v_xp integer; v_level integer;
  BEGIN
    IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000 THEN
      RAISE EXCEPTION 'invalid amount';
    END IF;
    -- … rest unchanged …
  END $$;
  ```
  Long-term: have the server compute `p_amount` from the actual `user_activities` rows in the current seal window — never trust the client total. Add a per-user-per-day cap.

### 4. `sponsored_orphans` / `community_project_media` / `onboarding_images` / `app_config` are world-writable to logged-in users

- **Location**:
  - `_sponsored_orphans_migration.sql:89-96` (orphans table policies are `USING (true)` / `WITH CHECK (true)` for INSERT/UPDATE/DELETE to `authenticated`).
  - `_sponsored_orphans_migration.sql:117-125` (`orphan-photos` storage bucket policies are likewise unrestricted for authenticated users).
  - `_projects_media_migration.sql:30-39` (`community_project_media`) — same pattern.
  - `_projects_media_migration.sql:63-76` (`project-media` storage bucket) — same pattern.
  - `_onboarding_images_migration.sql:51-60` (`onboarding_images` table).
  - `_onboarding_images_migration.sql:82-95` (`onboarding-images` storage bucket).
  - `_admin_rls_fix.sql:9-22` (`app_config` — INSERT / UPDATE / DELETE allowed for any `authenticated`).
- **What's wrong**: Every "admin gating done in app" comment in those files is a lie at the security boundary. The admin web (`admin-web/src/lib/supabase.ts:6`) uses the **anon key**, not service role — so the only thing differentiating an admin's REST call from a regular user's REST call is a hardcoded email allowlist evaluated in `admin-web/src/app/dashboard/layout.tsx:106-107`. An attacker who has signed up for the app at all can replicate the same REST traffic the admin panel sends.
- **Exploit scenario**: Concrete sequence with the published anon key + URL (both already in `lib/main.dart:104-106`):
  ```js
  // Anyone who has signed up can run this from a browser console:
  await supabase.from('app_config').upsert({ key: 'min_seed_value_usd', value: '100' });
  await supabase.from('app_config').upsert({ key: 'donor_pool_usd_monthly', value: '0' });
  await supabase.from('app_config').upsert({ key: 'feature_donations_enabled', value: 'false' });
  await supabase.from('sponsored_orphans').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('onboarding_images').update({ image_url: 'https://evil.example/lewd.jpg' }).eq('slot_key', 'onb_hero_1');
  await supabase.storage.from('project-media').upload('cover.jpg', maliciousFile, { upsert: true });
  ```
  Result: economy parameters mass-changed (Realtime broadcasts the new values to every logged-in client per `SettingsService`), every orphan record gone, every onboarding screen replaced with attacker-chosen content, project cover images vandalised.
- **Remediation**: Gate writes on these tables in the DB. Two options:
  1. **JWT email allowlist (matches current admin UX, no schema change)**:
     ```sql
     CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean
       LANGUAGE sql STABLE AS $$
       SELECT lower(coalesce(auth.jwt() ->> 'email','')) IN ('pak.zakn@gmail.com','zaid_azam@zeir.io');
     $$;
     DROP POLICY "orphans_insert_auth" ON sponsored_orphans;
     CREATE POLICY "orphans_admin_write" ON sponsored_orphans
       FOR ALL TO authenticated
       USING (public.is_admin()) WITH CHECK (public.is_admin());
     ```
     Repeat for `community_project_media`, `community_projects`, `onboarding_images`, `app_config`, plus the three storage buckets (storage policies can reference `public.is_admin()` the same way).
  2. **`profiles.is_admin` column** — add a boolean, default false, set to `true` for the two admin rows, and use `EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin)`. Make sure the column is in a separate policy that prevents users from updating it (see also: profiles RLS NEEDS MANUAL REVIEW).

### 5. `.gitignore` is configured to track `.env`

- **Location**: `D:\noor_rewards-main\noor_rewards-main\.gitignore:32-43`, in particular line 41 `*.env` (ignore everything ending `.env`) and line 43 `!.env` (re-include the project root `.env`).
- **What's wrong**: This is the root cause of finding #1 — the file containing secrets is deliberately whitelisted for tracking. Combined with `pubspec.yaml` declaring `.env` as a Flutter asset, the developer's pragmatic fix (commit a placeholder) decayed into the actual fix (commit the real secrets). Anyone editing `.env` locally will accidentally `git add` a secret on their next `git add .`.
- **Exploit scenario**: A future developer rotates the QF secrets — or worse, drops a Supabase **service_role** key into `.env` while debugging — and commits it without thinking. The repo's CI workflows (`codemagic.yaml:31-45`) make `.env` look like a build artifact, masking the danger.
- **Remediation**: Replace lines 41-43 of `.gitignore` with:
  ```gitignore
  # Never track environment files. Use Codemagic / Vercel secrets instead.
  .env
  .env.*
  *.env
  ```
  Then `git rm --cached .env` and commit. The Codemagic build can keep using the runtime-generated `.env` (the script in `codemagic.yaml:38-45` already writes one from env vars).

---

## High findings

### 6. `earn_quran_points` / `earn_dhikr_points` pump `community_projects` totals with attacker-chosen amounts

- **Location**: `_seal_credits_garden_migration.sql:17-44` (Quran) and `_seal_credits_garden_migration.sql:47-73` (Dhikr).
- **What's wrong**: Both functions accept `p_coins` from the client and execute `UPDATE community_projects SET current_points = current_points + p_coins WHERE is_active AND NOT is_completed`. There is no validation that `p_coins` equals the configured per-ayah or per-dhikr value, and no upper bound. The function uses `auth.uid()` for the `user_activities` insert (good) but the project-points pump bypasses any per-user accounting.
- **Exploit scenario**: `supabase.rpc('earn_quran_points', { p_surah: 1, p_ayah: 1, p_coins: 1000000000 })` — every active community project's `current_points` jumps by 1 billion. UI shows every project as "fully funded" → real users believe their donations are unneeded → donor flow drops to zero. Variant: `p_coins: -1` to drag projects negative.
- **Remediation**: Read the canonical per-event reward from `app_config` server-side (the values exist already: `coins_per_ayah`, `coins_per_dhikr`) and ignore `p_coins`. Or clamp `p_coins` to a hardcoded ceiling (e.g. `LEAST(GREATEST(p_coins, 0), 100)`).

### 7. RPCs trust `p_user_id` from the client (IDOR family)

- **Locations** (each is `SECURITY DEFINER` with no `auth.uid() = p_user_id` guard):
  - `_sponsored_orphans_migration.sql:132-171` — `sponsor_orphan(p_user_id, p_orphan_id, p_amount)` deducts seeds and inserts a donation row keyed to `p_user_id`. Caller can sponsor on someone else's behalf, draining their balance.
  - `_sponsored_orphans_migration.sql:231-257` — `get_user_orphan_sponsorships(p_user_id)` lets you read anyone's sponsorship history.
  - `_stats_migration.sql:79-137` and `_daily_stats_migration.sql:41-117` — `record_activity_stats(p_user_id, …)` lets any user write into another user's monthly/daily stats and into `global_daily_stats`.
  - `_stats_migration.sql:142-164` — `get_user_monthly_stats(p_user_id)` reads any user's monthly rollup.
  - `_daily_stats_migration.sql:126-140` — `get_week_screen_time(p_user_id)` reads any user's daily activity histogram (privacy leak).
  - `_dhikr_phrase_tracking_migration.sql:34-53` — `record_dhikr_phrase(p_user_id, p_phrase_id, p_count)` writes phrase counts for any user.
  - `_dhikr_phrase_tracking_migration.sql:57-63` — `get_user_phrase_counts(p_user_id)` reads any user's phrase counts.
  - `_dhikr_phrase_tracking_migration.sql:67-80` — `get_user_lifetime_activity(p_user_id)` reads any user's lifetime totals.
  - `donate_to_project(p_user_id, p_project_id, p_amount)` — body not in repo, but caller at `lib/services/donation_service.dart:94-101` passes the client-supplied uid. NEEDS MANUAL REVIEW of the live RPC body — almost certainly the same shape and the same bug.
- **Exploit scenario** (sponsor-as-victim): Attacker collects target UUIDs from `get_project_recent_donors` (returns `user_id`s plainly). Calls `supabase.rpc('sponsor_orphan', { p_user_id: '<victim_uuid>', p_orphan_id: '<some_orphan>', p_amount: <victim_balance> })` in a loop. Each call drains the victim's `profiles.noor_points` and books a donation in their name. Combined with #3 this is a full "take over victim's economy" primitive.
- **Remediation**: Add to every offending RPC body:
  ```sql
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  ```
  Or drop the `p_user_id` parameter entirely and use `auth.uid()` directly inside the function.

### 8. Storage buckets allow any authenticated user to overwrite/delete any object

- **Locations**:
  - `_sponsored_orphans_migration.sql:117-125` — `orphan-photos` (10 MB images).
  - `_projects_media_migration.sql:57-76` — `project-media` (100 MB videos).
  - `_onboarding_images_migration.sql:77-95` — `onboarding-images` (10 MB images).
- **What's wrong**: Every INSERT/UPDATE/DELETE storage policy is `bucket_id = '<bucket>'` with no `owner = auth.uid()` and no path-prefix check. Combined with the orphan admin page calling `upload(path, file, { upsert: true })` (`admin-web/src/app/dashboard/orphans/page.tsx:309-312`) means any user can replace any file. Plus the buckets are `public = true`, so the malicious content is served back to all users with the legitimate URL the app already shows.
- **Exploit scenario**:
  1. Attacker enumerates `sponsored_orphans` (anyone can `SELECT`) and reads `photo_url` for the most-sponsored orphan.
  2. Attacker extracts the storage key from the URL and uploads a malicious / disturbing image to the same path with `upsert: true`.
  3. Every existing donor sees the spoofed image. Same playbook works for project covers (visible on every dashboard) and onboarding hero images (visible to every new signup).
  4. Variant: spam the 100 MB `project-media` bucket with garbage to drive up Supabase egress / storage cost.
- **Remediation**: Use storage policies that scope writes to the calling user's prefix, and lock admin-managed buckets to admins:
  ```sql
  DROP POLICY "orphan_photos_auth_insert" ON storage.objects;
  CREATE POLICY "orphan_photos_admin_write" ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id = 'orphan-photos' AND public.is_admin())
    WITH CHECK (bucket_id = 'orphan-photos' AND public.is_admin());
  ```
  Repeat for `project-media` and `onboarding-images`. For the `avatars` bucket (user-uploadable from `profile_settings_screen.dart`) scope writes to a `<auth.uid()>/...` path prefix.

### 9. `send-fcm` edge function can spoof notifications to any user (RLS-dependent)

- **Location**: `supabase/functions/send-fcm/index.ts:17-46`.
- **What's wrong**: The function takes `user_id`, `title`, `body` from the request body. It then constructs a Supabase client using the caller's JWT (anon key + Authorization header pass-through), queries `fcm_tokens` for that `user_id`, and sends a notification using Google service-account credentials it holds. Two issues:
  1. If `fcm_tokens` RLS allows users to read other users' tokens (NEEDS MANUAL REVIEW — no policy in repo), any user can send an FCM push with arbitrary `title`/`body` to any other user.
  2. The function does not validate that `user_id == auth.uid()`. Even if the SELECT is RLS-blocked, the function will fall through to `Device token not found` error — no abuse — but any tightening of RLS in the future that relies on the function being "trusted" would break.
- **Exploit scenario** (assuming `fcm_tokens` is broadly readable): Attacker calls
  ```
  POST /functions/v1/send-fcm
  Authorization: Bearer <attacker_anon_jwt>
  { "user_id": "<victim>", "title": "Sabiq Security Alert", "body": "Tap to verify your account: https://phish.example/" }
  ```
  Victim sees a system-styled push from the real Sabiq Firebase project — credible phishing pretext.
- **Remediation**:
  1. Add at the top of the handler:
     ```ts
     const { data: { user } } = await supabase.auth.getUser();
     if (!user || user.id !== user_id) {
       return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 });
     }
     ```
  2. If the function is supposed to be admin-only, gate on `ADMIN_EMAILS`.
  3. Lock down `fcm_tokens` RLS to `user_id = auth.uid()` for SELECT/INSERT/UPDATE/DELETE (NEEDS MANUAL REVIEW — verify).

### 10. Admin status is enforced only client-side

- **Location**:
  - Allowlist: `admin-web/src/lib/supabase.ts:9-12` (`pak.zakn@gmail.com`, `zaid_azam@zeir.io`).
  - Login form check: `admin-web/src/app/page.tsx:20-24`.
  - Dashboard gate: `admin-web/src/app/dashboard/layout.tsx:104-113` — fetches the user, calls `router.replace("/")` if email not in set, otherwise renders.
  - Supabase client: `admin-web/src/lib/supabase.ts:6` uses `createClient(url, anonKey)`. No `createServerClient` with cookies + `service_role`; no Next.js middleware or server route enforcement.
- **What's wrong**: `router.replace("/")` is a navigation, not a permission. Any non-admin who logs in (or who has an existing session) gets a JWT identical to an admin's except for the email claim. The browser then sends that JWT directly to Supabase REST. Postgres RLS is the only thing that can reject the call — and for `app_config`, `sponsored_orphans`, `community_projects`, `community_project_media`, `onboarding_images`, RLS allows any `authenticated` to write (see finding #4).
- **Exploit scenario**: See finding #4's REST-console snippet. The attacker never visits `/dashboard` — they bypass the React gate entirely by talking to Supabase REST directly.
- **Remediation**: Combine the DB fix in #4 with one of:
  1. Move all admin mutations into Supabase Edge Functions that check the caller's email against an allowlist and use the service-role key internally.
  2. Add the `public.is_admin()` policy guard (see remediation in #4) so the DB rejects non-admin writes even if the client gate is bypassed.

---

## Medium findings

### 11. Supabase project ref + pooler hostname committed to git

- **Location**:
  - Working tree + tracked: `supabase/.temp/linked-project.json` → `{"ref":"fwjzhtcxfiendofnhyzp","name":"Noor Rewards","organization_id":"cxamrugmathiprlgsnzo",…}`.
  - `supabase/.temp/pooler-url` → `postgresql://postgres.fwjzhtcxfiendofnhyzp@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres` (no password).
  - Originally committed in commit `94e3dd8`.
- **What's wrong**: Not a credential, but reveals the exact Postgres pooler host and database username. Useful for credential-stuffing or for a future leaked secret to find its target instantly.
- **Remediation**: Add `supabase/.temp/` to `.gitignore` and `git rm -r --cached supabase/.temp/`. Supabase CLI re-generates these on `supabase link`.

### 12. No rate limiting on RPCs and storage writes

- **Location**: All `SECURITY DEFINER` RPCs above (`earn_xp`, `record_activity_stats`, `record_dhikr_phrase`, `sponsor_orphan`, `donate_to_project`, etc.). Storage buckets `orphan-photos`, `project-media`, `onboarding-images`, `avatars`.
- **What's wrong**: Supabase's built-in rate limiting applies to `auth/*` endpoints, not to `rest/v1/*` or `storage/v1/*` from authenticated users. A single signed-in account can issue thousands of RPC calls per minute. Combined with #3, #6, #7 this turns logical bugs into economic / availability incidents at scale.
- **Remediation**:
  - Add per-user counters inside each `SECURITY DEFINER` RPC keyed by `auth.uid()` and the current minute, rejecting > N calls/min.
  - For storage buckets, restrict upload paths to `<auth.uid()>/<filename>` and add a daily upload count quota via a trigger.
  - Use Supabase's read-only replica + a CDN cache for hot reads.

### 13. `link_qf_profile` deliberately orphans the old profile row

- **Location**: `_link_qf_profile.sql:62-65` (`We intentionally DO NOT DELETE the old duplicate profile…`).
- **What's wrong**: The original row is preserved with `email = email || '_merged_' || gen_random_uuid()` and `referral_code = NULL`. The victim of finding #2 cannot recover — they can't even sign in with the original email anymore (their Supabase auth user still exists, but the linked `profiles` row has a mangled email and no Seeds). There is no undo path.
- **Remediation**: After fixing finding #2, perform an actual `UPDATE profiles SET … WHERE id = v_old_profile.id` to keep linkage, or move the FKs atomically. At minimum keep an `original_email` audit column.

### 14. Hardcoded admin allowlist with no MFA gate

- **Location**: `admin-web/src/lib/supabase.ts:9-12`. Rotation policy unclear; no admin audit log table visible.
- **What's wrong**: Two Google accounts hold the keys to the entire economy. Source has no mention of Supabase MFA enforcement, and the admin email allowlist requires a code change + Vercel redeploy to add/remove an admin. Easy to outgrow.
- **Remediation**: Move admin list to an `admins` table (with `created_at`, `created_by`, `removed_at` columns for audit). Gate on `public.is_admin()` SQL function. Enforce MFA at the Supabase Auth level via dashboard settings (`auth.mfa.totp.enroll_enabled = true` + require MFA for the admin role).

---

## Low findings

### 15. Anon key + URL duplicated in 4 source locations

- **Location**:
  - `lib/main.dart:104-106`
  - `admin-web/.env.local:1-2` (also embedded into Next.js bundle)
  - `call_function.dart:7`
  - `dump_schema.dart:7`
  - `seed_quran.dart:10`
- **What's wrong**: Anon keys are PUBLIC by design (they're served in every client app) so this is NOT a vulnerability. But the duplication makes rotation tedious. The `dump_schema.dart` / `seed_quran.dart` / `call_function.dart` helpers look like one-off dev scripts that shouldn't ship.
- **Remediation**: Centralise via `core/env/env.dart` (already imported in `lib/main.dart:35`). Delete or `.gitignore` the dev scripts.

### 16. CI workflows mostly clean

- **Location**: `.github/workflows/build_qa.yml`, `.github/workflows/ios-testflight.yml`, `codemagic.yaml`.
- **What's wrong**:
  - `ios-testflight.yml:14` still uses placeholder `com.yourcompany.noorRewards` — workflow has likely never run successfully. Not a security risk, but stale.
  - `codemagic.yaml:38-45` writes `.env` via shell heredoc from environment variables. Variables are interpolated by the shell — if an env value happens to contain backticks or `$(…)`, command substitution could leak. Best practice would be `printenv | grep ^QURAN_ > .env` instead.
  - `ios-testflight.yml:122-128` calls `xcrun altool --upload-app` with `--verbose`. iOS upload logs sometimes echo API key IDs; check that Issuer ID / Key ID are not printed to public action logs.
- **Remediation**: Fix `BUNDLE_ID`. Switch the codemagic heredoc to a safer write. Audit one TestFlight upload log for accidental secret echoing.

---

## Prioritized fix checklist

1. **Rotate the Quran Foundation production + pre-live credentials in the QF dashboard NOW.** (Finding #1)
2. **Remove `!.env` from `.gitignore`, replace with strict ignore, `git rm --cached .env`, commit, force-push.** Verify no other secret-bearing file is whitelisted. (Finding #5)
3. **Add `auth.uid()` checks to `earn_xp`, `sponsor_orphan`, `record_activity_stats`, `record_dhikr_phrase`, `get_user_monthly_stats`, `get_week_screen_time`, `get_user_phrase_counts`, `get_user_lifetime_activity`, `get_user_orphan_sponsorships`, and confirm `donate_to_project` does the same.** (Findings #3, #7)
4. **Patch `link_qf_profile` to require `auth.uid() = p_new_id` AND `auth.jwt() ->> 'email' = p_email`.** (Finding #2)
5. **Replace `USING (true) WITH CHECK (true)` on `sponsored_orphans`, `community_project_media`, `onboarding_images`, and `app_config` with `public.is_admin()` policies.** (Finding #4)
6. **Tighten storage policies on `orphan-photos`, `project-media`, `onboarding-images` to admin-only writes; tighten `avatars` to `<auth.uid()>/…` prefix.** (Finding #8)
7. **Clamp `p_coins` in `earn_quran_points` / `earn_dhikr_points` — read the canonical value from `app_config` server-side, or `LEAST(p_coins, hardcoded_cap)`.** (Finding #6)
8. **Audit and lock down `fcm_tokens` RLS (must be `user_id = auth.uid()` for all CRUD). Add `user.id !== body.user_id` rejection to `send-fcm`.** (Finding #9)
9. **Add `public.is_admin()` SQL function + admin allowlist table; enforce MFA on the two admin Google accounts in the Supabase dashboard.** (Findings #4, #10, #14)
10. **Add `.gitignore` entry for `supabase/.temp/`; `git rm -r --cached supabase/.temp/`.** (Finding #11)
11. **Add per-user rate counters inside high-volume `SECURITY DEFINER` RPCs.** (Finding #12)
12. **Delete dev scripts (`call_function.dart`, `dump_schema.dart`, `seed_quran.dart`) or move them into a `.gitignore`d `scripts/` dir.** (Finding #15)
13. **Fix `BUNDLE_ID` in `ios-testflight.yml`; audit one TestFlight upload log for secret leakage.** (Finding #16)
14. **Verify the GitHub repo's visibility setting. If it has EVER been public during the period 2026-05-21 → now, treat #1 secrets as fully compromised regardless of any rotation.**

---

## Items that need manual review

- **Profiles RLS** — no policy on `profiles` is in the repo. Need to inspect live Supabase to confirm whether users can `UPDATE profiles SET noor_points = …, level = …, is_admin = …` directly. Code paths like `lib/screens/profile_settings_screen.dart:162-166` and `lib/screens/profile_setup_screen.dart:137` do a raw `from('profiles').upsert({...})` — if the policy is "user can update own row", they can update any column, including a hypothetical `is_admin` / `role` column.
- **`fcm_tokens` RLS** — referenced by `send-fcm`, `nightly-coin-reminder`, `reward-webhook`, `admin-web/src/app/dashboard/users/[id]/page.tsx`, plus 6 other edge functions. Policy not in repo. Verify the table allows read/write only for `auth.uid() = user_id`.
- **`community_projects` RLS** — `earn_quran_points` / `earn_dhikr_points` update `current_points` directly; finding #6 assumes the table itself is not separately writable by clients but the policy isn't in the repo. Verify.
- **`donate_to_project` RPC body** — not in repo. Must verify it enforces `auth.uid() = p_user_id` and validates `p_amount` against the caller's `noor_points`.
- **`user_activities`, `user_badges`, `user_challenge_progress`, `streak_history`, `leaderboard_global`, `user_analytics`, `quran_bookmarks`, `quran_favorites`, `azkar_categories`, `azkar_items`, `badges`, `challenges`, `xp_levels`** — all written/read from client code, no RLS in repo. Need to enumerate live policies.
- **`avatars` storage bucket** — used by `profile_settings_screen.dart` for user avatar uploads. Bucket creation + policies not in repo. Verify per-user prefix isolation.
- **GitHub repo visibility** — cannot determine from working tree. If public at any point since the QF credential commit, the secrets are externally compromised forever.
- **Supabase MFA settings for the two admin accounts** — verify in dashboard.
- **`record_streak_activity` / `award_badge` / `get_streak_history`** RPC bodies — referenced in CLAUDE.md as core RPCs but not in any committed `.sql` file. Likely the same `SECURITY DEFINER` + trust-the-client pattern as the rest.
- **Other edge functions** (`community-momentum`, `level-up-close`, `monthly-milestone`, `monthly-quran-reminder`, `resume-reading`, `streak-at-risk`, `local-azkaar-reminders`) — not deeply audited; sample (`nightly-coin-reminder`) uses `SUPABASE_SERVICE_ROLE_KEY` correctly server-side. Verify the others don't echo secrets.

---

## Rotation steps for exposed secrets

### Quran Foundation client_id + client_secret (Finding #1) — DO IMMEDIATELY

1. Sign in to `https://api-docs.quran.foundation/` (developer dashboard).
2. Locate the app registered as "Sabiq" / "Noor Rewards" — both PROD and PRELIVE.
3. For each environment, **regenerate the client secret** (or, ideally, **delete the existing client_id and create a new one** — this also invalidates the old `client_id` which has been leaked).
4. Note the new pair.
5. In Codemagic: `Workflow Editor → Environment variables` (or `Teams → Variables`), add as Secure:
   - `IS_DEV=false`
   - `QURAN_PROD_CLIENT_ID=<new>`
   - `QURAN_PROD_CLIENT_SECRET=<new>`
   - `QURAN_PRELIVE_CLIENT_ID=<new>`
   - `QURAN_PRELIVE_CLIENT_SECRET=<new>`
   The existing `codemagic.yaml:38-45` heredoc already consumes these.
6. In Supabase Edge Functions (used by `qf-token-exchange` / `qf-token-refresh`): Supabase dashboard → `Project Settings → Edge Functions → Secrets`. Update `QF_CLIENT_SECRET` (and any `QF_CLIENT_SECRET_<client_id>` variants).
7. Edit the working-tree `.env` to be empty placeholders, commit, push.
8. Remove `!.env` from `.gitignore` and add `.env` to ignore list, commit, push.
9. Purge the secret-bearing commits from history (`92a278f` and any later `.env` commits):
   ```bash
   git filter-repo --path .env --invert-paths
   git push --force-with-lease --all
   git push --force-with-lease --tags
   ```
   Only do this if no one else has unpushed work; coordinate with the team.
10. **If the repo has ever been public**, contact GitHub support (`security@github.com`) to ask for cached views to be purged, and assume the secrets are permanently public — rotation is the only mitigation.

### Supabase anon key (Finding #15) — NOT URGENT

The anon key in `lib/main.dart`, `admin-web/.env.local`, and the dev scripts is public by design. No rotation needed unless you change RLS to be permissive enough that the anon key alone grants meaningful access.

### Supabase service_role key — NOT FOUND IN REPO, KEEP IT THAT WAY

Confirmed via `git log --all -S "SUPABASE_SERVICE_ROLE"` and `git log --all -S "service_role"` — only references are inside edge function code (`Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`), never a value. Good.

### Firebase API keys (`android/app/src/google-services.json`, `ios/Runner/GoogleService-Info.plist`)

These are public per Firebase's docs — they identify the project, they don't authenticate. No rotation. Just make sure Firebase security rules (or the FCM server-key replacement: service account in `FCM_PRIVATE_KEY` env) are tight in the Supabase Edge Function environment.

### Git history of `supabase/.temp/pooler-url` (Finding #11) — NOT A CREDENTIAL

The pooler URL has no password embedded. No rotation needed. Just stop tracking the file going forward.
