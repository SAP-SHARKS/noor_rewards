# Security Audit

## Executive Summary

This audit reviewed the repository-local Flutter app, Next.js admin app, Supabase Edge Functions, SQL migrations, storage policies, and checked-in configuration. The live Supabase schema was not queried, so any table not defined in repository SQL is marked "Needs verification" for current RLS state.

Severity summary:

| Severity | Count | Theme |
| --- | ---: | --- |
| Critical | 7 | Client-side admin authorization, broad authenticated RLS, secrets in repo, insecure SECURITY DEFINER RPCs, unauthenticated/service-role webhook exposure |
| High | 8 | IDOR risks, unsafe push notification endpoint, storage overwrite/delete exposure, missing server-side admin model, public/broad analytics reads |
| Medium | 8 | Rate limits, audit logging gaps, sensitive error leakage, CORS, dependency/config hardening |
| Low | 5 | Operational hardening, policy naming, generated artifacts, docs drift |

Top risks:

1. Admin authorization is not production-safe. The admin web app gates access with a hardcoded email allowlist in browser code, while database policies allow any authenticated user to mutate admin-managed tables and storage.
2. Multiple `SECURITY DEFINER` RPCs accept `p_user_id` and do not verify `auth.uid()`, allowing authenticated callers to read or mutate another user's data if EXECUTE is available.
3. Real QF client secrets are present in the root `.env` and documentation, and anon JWTs are hardcoded in scripts and app code.
4. Storage buckets for admin-uploaded media allow any authenticated user to upload, overwrite, or delete files.
5. The `reward-webhook` Edge Function uses the service role key and has no visible webhook signature/shared-secret verification.

## Application Map

Frontend routes:

| Area | Routes/files | Notes |
| --- | --- | --- |
| Flutter mobile/web app | `lib/main.dart`, `lib/screens/*`, `lib/services/*` | Initializes Supabase with anon key in `lib/main.dart:95`; auth checked through `Supabase.instance.client.auth.currentUser` in many screens/services. |
| Auth | `lib/auth/auth_screen.dart`, `lib/screens/start_journey_screen.dart`, `lib/features/auth/data/qf_auth_service.dart` | Email/password, OAuth, anonymous Supabase sessions for QF flow. |
| Admin web | `admin-web/src/app/page.tsx`, `admin-web/src/app/dashboard/**` | Client-only Next app. Dashboard routes include overview, economy, donor pool, theme, projects, orphans, users, features, banners, raw config, analytics, categories, onboarding. |
| Admin gate | `admin-web/src/lib/supabase.ts:9`, `admin-web/src/app/page.tsx:20`, `admin-web/src/app/dashboard/layout.tsx:132` | Hardcoded email allowlist in client bundle. |

Backend/API routes:

| Type | Files | Notes |
| --- | --- | --- |
| Next API routes/server actions | None found under `admin-web/src/app` | Admin app performs direct client-side Supabase calls using anon key. |
| Supabase Edge Functions | `supabase/functions/*/index.ts` | Notification cron-like jobs, QF token exchange/refresh, reward webhook, send-fcm. |
| Cron jobs | `community-momentum`, `level-up-close`, `local-azkaar-reminders`, `monthly-milestone`, `monthly-quran-reminder`, `nightly-coin-reminder`, `resume-reading`, `streak-at-risk` | Use `SUPABASE_SERVICE_ROLE_KEY` and FCM secrets. Schedule source not in repo. Needs verification in Supabase dashboard. |
| Webhooks | `supabase/functions/reward-webhook/index.ts` | Intended for Supabase Database Webhooks; no request signature/shared-secret check found. |

Supabase clients:

| File | Key used |
| --- | --- |
| `lib/main.dart:95` | Hardcoded Supabase URL and anon JWT. |
| `admin-web/src/lib/supabase.ts:3` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`. |
| Edge cron functions | `SUPABASE_SERVICE_ROLE_KEY`. |
| `supabase/functions/send-fcm/index.ts:31` | `SUPABASE_ANON_KEY` plus caller Authorization header. |

Storage buckets identified:

| Bucket | Source | Public? | Current write policy |
| --- | --- | --- | --- |
| `project-media` | `_projects_media_migration.sql:42` | true | Any authenticated insert/update/delete. |
| `onboarding-images` | `_onboarding_images_migration.sql:63` | true | Any authenticated insert/update/delete. |
| `orphan-photos` | `_sponsored_orphans_migration.sql:99` | true | Any authenticated insert/update/delete. |
| `avatars` | `lib/screens/profile_settings_screen.dart:207` | Needs verification | User uploads to `avatars/{uid}/...`; policies not found in repo. |

RPC functions identified:

| Function | Source | Risk note |
| --- | --- | --- |
| `sponsor_orphan` | `_sponsored_orphans_migration.sql:132` | Accepts `p_user_id`; no `auth.uid()` check. |
| `get_orphan_stats`, `get_orphan_stats_bulk`, `get_orphan_recent_sponsors`, `get_user_orphan_sponsorships` | `_sponsored_orphans_migration.sql` | User-supplied IDs; privacy/IDOR checks needed. |
| `record_activity_stats`, `get_user_monthly_stats`, `get_global_stats`, `increment_global_active`, `sync_monthly_points` | `_stats_migration.sql`, `_daily_stats_migration.sql` | Several are `SECURITY DEFINER`; user ID ownership missing. |
| `record_dhikr_phrase`, `get_user_phrase_counts`, `get_user_lifetime_activity` | `_dhikr_phrase_tracking_migration.sql` | Needs ownership verification. |
| `earn_quran_points`, `earn_dhikr_points`, `earn_xp` | `_seal_credits_garden_migration.sql` | Needs abuse/ownership verification. |
| `link_qf_profile` | `_link_qf_profile.sql` | Account-linking sensitive; needs strict auth verification. |
| `get_project_recent_donors`, `get_project_donor_counts` | `_project_recent_donors_migration.sql`, `_project_donor_counts_migration.sql` | Granted to anon/authenticated; privacy review needed. |
| `grant_points` | `admin-web/src/app/dashboard/users/page.tsx:41` | Admin function not defined in repo; Needs verification. |

Authentication state checks:

| File | Check |
| --- | --- |
| `admin-web/src/app/dashboard/layout.tsx:132` | `supabase.auth.getUser()` then client-side `ADMIN_EMAILS.has(email)`. |
| `admin-web/src/app/page.tsx:20` | Blocks login form for non-allowlisted email before sign-in. |
| `lib/main.dart` | AuthGate uses Supabase current user plus QF metadata; profile upsert in `lib/main.dart:494`. |
| Flutter services/screens | Repeated `auth.currentUser?.id` checks before reads/writes. These are convenience checks, not authorization without RLS/RPC enforcement. |

## Critical Findings

### C-01: Admin authorization is enforced in the browser, while RLS allows any authenticated user to perform admin writes

- Severity: Critical
- File/table/route affected: `admin-web/src/lib/supabase.ts:9`, `admin-web/src/app/dashboard/layout.tsx:132`, `_admin_rls_fix.sql:11`, `_projects_media_migration.sql:30`, `_onboarding_images_migration.sql:51`, `_sponsored_orphans_migration.sql:91`
- What is vulnerable: Admin identity is a hardcoded email set shipped to the browser. Database policies allow all authenticated users to insert/update/delete `app_config`, `community_project_media`, `onboarding_images`, `sponsored_orphans`, and related storage objects.
- Exploit scenario: A normal authenticated user copies the anon key/session from the app and directly calls PostgREST to change feature flags, upload malicious media, edit orphan records, delete onboarding assets, or alter donation project media. They do not need to load the admin UI.
- Recommended fix: Move admin authority into a trusted database role table and enforce it in RLS and server-side routes/functions. Remove broad authenticated write policies.
- Exact SQL change:

```sql
create table if not exists public.app_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'support')),
  created_at timestamptz not null default now()
);

alter table public.app_roles enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.app_roles
    where user_id = auth.uid() and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Example admin table fix.
drop policy if exists "config_insert_auth" on public.app_config;
drop policy if exists "config_update_auth" on public.app_config;
drop policy if exists "config_delete_auth" on public.app_config;

create policy "app_config_admin_insert" on public.app_config
  for insert to authenticated with check (public.is_admin());
create policy "app_config_admin_update" on public.app_config
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "app_config_admin_delete" on public.app_config
  for delete to authenticated using (public.is_admin());
```

Apply the same `public.is_admin()` write policy pattern to `community_projects`, `community_project_media`, `onboarding_images`, `sponsored_orphans`, `azkar_categories`, `azkar_items`, admin analytics/admin-only views, and admin storage buckets.

### C-02: `sponsor_orphan` can debit arbitrary users because it trusts `p_user_id`

- Severity: Critical
- File/table/route affected: `_sponsored_orphans_migration.sql:132`, `lib/services/donation_service.dart:487`
- What is vulnerable: The function is `SECURITY DEFINER`, accepts `p_user_id`, locks `profiles` for that ID, subtracts points, and inserts `user_donations`. It never checks `p_user_id = auth.uid()`.
- Exploit scenario: An authenticated user calls `rpc('sponsor_orphan', { p_user_id: victim_uuid, p_orphan_id, p_amount })` and spends another user's Seeds. If execute is available to `anon` or `authenticated` (Postgres defaults often allow PUBLIC execute unless revoked), this is a direct account-balance impact.
- Recommended fix: Remove `p_user_id` from the public RPC and bind to `auth.uid()` inside the function. Revoke PUBLIC execute.
- Exact SQL change:

```sql
revoke all on function public.sponsor_orphan(uuid, uuid, integer) from public, anon, authenticated;

create or replace function public.sponsor_orphan(
  p_orphan_id uuid,
  p_amount integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_min_sponsorship integer;
  v_is_active boolean;
  v_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select min_sponsorship, is_active
    into v_min_sponsorship, v_is_active
  from public.sponsored_orphans
  where id = p_orphan_id;

  if not found or not v_is_active or p_amount < v_min_sponsorship then
    return false;
  end if;

  select noor_points into v_balance
  from public.profiles
  where id = v_user_id
  for update;

  if v_balance is null or v_balance < p_amount then
    return false;
  end if;

  update public.profiles
    set noor_points = noor_points - p_amount
    where id = v_user_id;

  insert into public.user_donations (user_id, orphan_id, points_donated, created_at)
  values (v_user_id, p_orphan_id, p_amount, now());

  return true;
end;
$$;

grant execute on function public.sponsor_orphan(uuid, integer) to authenticated;
```

Update Flutter to call the two-argument RPC.

### C-03: Stats RPCs allow cross-user reads/writes and metric inflation

- Severity: Critical
- File/table/route affected: `_stats_migration.sql:79`, `_stats_migration.sql:142`, `_daily_stats_migration.sql:41`, `_daily_stats_migration.sql:126`, `lib/services/stats_service.dart:208`, `lib/screens/impact_report_screen.dart:293`
- What is vulnerable: `record_activity_stats(p_user_id, ...)`, `get_user_monthly_stats(p_user_id)`, and `get_week_screen_time(p_user_id)` are `SECURITY DEFINER` or execute with elevated access and trust a caller-provided user ID.
- Exploit scenario: A user records activity for other users, pollutes global stats, or reads another user's monthly/daily worship stats by changing `p_user_id`.
- Recommended fix: Public RPCs must use `auth.uid()` and ignore client-supplied user IDs, or explicitly enforce equality.
- Exact SQL change:

```sql
create or replace function public.record_activity_stats(
  p_type text,
  p_count int default 1,
  p_duration_sec int default 0
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if p_type not in ('quran', 'dhikr') then
    raise exception 'Invalid activity type';
  end if;
  if p_count < 0 or p_count > 1000 or p_duration_sec < 0 or p_duration_sec > 86400 then
    raise exception 'Invalid activity payload';
  end if;

  -- Existing body, but use v_user_id for every user_id write.
end;
$$;

create or replace function public.get_week_screen_time()
returns table (stat_date date, total_sec int)
language sql
stable
security definer
set search_path = public
as $$
  with days as (
    select (current_date - i)::date as d
    from generate_series(6, 0, -1) as i
  )
  select days.d,
         coalesce(uds.quran_time_sec, 0) + coalesce(uds.dhikr_time_sec, 0)
  from days
  left join public.user_daily_stats uds
    on uds.user_id = auth.uid() and uds.stat_date = days.d
  order by days.d asc;
$$;
```

### C-04: Admin-managed storage buckets allow any authenticated user to upload, overwrite, and delete

- Severity: Critical
- File/table/route affected: `_projects_media_migration.sql:63`, `_onboarding_images_migration.sql:82`, `_sponsored_orphans_migration.sql:119`, admin upload pages under `admin-web/src/app/dashboard/**`
- What is vulnerable: Storage policies only check `bucket_id`, not admin role, object prefix ownership, file naming, or overwrite authorization.
- Exploit scenario: Any signed-in app user uploads a large/malicious public file, overwrites project/orphan/onboarding assets, or deletes public media.
- Recommended fix: Use `public.is_admin()` for admin buckets. For avatars, use per-user path isolation.
- Exact SQL change:

```sql
drop policy if exists "project_media_auth_insert" on storage.objects;
drop policy if exists "project_media_auth_update" on storage.objects;
drop policy if exists "project_media_auth_delete" on storage.objects;

create policy "project_media_admin_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'project-media' and public.is_admin());
create policy "project_media_admin_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'project-media' and public.is_admin())
  with check (bucket_id = 'project-media' and public.is_admin());
create policy "project_media_admin_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'project-media' and public.is_admin());

-- Repeat for onboarding-images and orphan-photos.
```

For avatars:

```sql
create policy "avatars_owner_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars_owner_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars_owner_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
```

### C-05: Real secrets are present in repository files

- Severity: Critical
- File/table/route affected: `.env:13`, `.env:17`, `_qf_bookmark_sync_status.md:55`, `call_function.dart:7`, `dump_schema.dart:7`, `seed_quran.dart:10`, `lib/main.dart:95`
- What is vulnerable: QF prelive and production client secrets are checked in locally. Supabase anon JWTs are hardcoded in scripts and the Flutter app. The `.gitignore` explicitly unignores root `.env` with `!.env`, which makes accidental secret commits likely.
- Exploit scenario: Anyone with repository access can exchange/refresh QF tokens as the application client. If these files were pushed, GitHub history may retain secrets even after deletion.
- Recommended fix: Rotate QF client secrets immediately. Remove real secrets from tracked files and history. Keep anon keys in build-time config where possible; anon key is public but should not be duplicated in scratch scripts.
- Exact change:

```gitignore
.env
.env.*
!.env.example
```

Create `.env.example` with placeholders only. In GitHub, enable secret scanning and push protection, then purge historical secrets with `git filter-repo` or GitHub support if already pushed.

### C-06: `reward-webhook` uses the service role key without request authentication

- Severity: Critical
- File/table/route affected: `supabase/functions/reward-webhook/index.ts:38`
- What is vulnerable: The function parses any JSON body, uses `SUPABASE_SERVICE_ROLE_KEY`, fetches FCM tokens, and sends push notifications. No webhook signature, shared secret, method allowlist, or origin trust check is visible.
- Exploit scenario: If the Edge Function is publicly invokable, an attacker posts fake INSERT payloads with arbitrary `user_id` values and triggers notification spam. The service role query bypasses RLS for `fcm_tokens`.
- Recommended fix: Require a secret header from the Supabase Database Webhook and reject all other requests before parsing payload details.
- Exact code change:

```ts
const expected = Deno.env.get('REWARD_WEBHOOK_SECRET');
const got = req.headers.get('x-webhook-secret');
if (!expected || got !== expected) {
  return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
}
if (req.method !== 'POST') {
  return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });
}
```

Also configure the Edge Function with JWT verification disabled only if the shared secret is present and managed in Supabase secrets.

### C-07: Existing migrations intentionally create broad authenticated write access for public content tables

- Severity: Critical
- File/table/route affected: `_admin_rls_fix.sql`, `_projects_media_migration.sql`, `_onboarding_images_migration.sql`, `_sponsored_orphans_migration.sql`
- What is vulnerable: Comments explicitly state "admin gating done in app" or "admin gating happens client-side". This is not a secure authorization boundary.
- Exploit scenario: Attackers skip UI and write directly through Supabase REST/RPC/storage APIs.
- Recommended fix: Treat all broad `TO authenticated WITH CHECK (true)` policies on admin-owned resources as production blockers. Replace with `public.is_admin()` and add audit logs.

## High Findings

### H-01: Admin user pages likely rely on RLS that is not defined in repo

- Severity: High
- File/table/route affected: `admin-web/src/app/dashboard/users/page.tsx:27`, `admin-web/src/app/dashboard/users/[id]/page.tsx:150`
- What is vulnerable: Admin pages read `profiles`, `user_analytics`, `user_monthly_stats`, `user_daily_stats`, `user_dhikr_phrase_counts`, `fcm_tokens`, `user_progress`, `quran_bookmarks`, `user_activities`, and `badges` directly from the browser anon client. Policies granting admin read access are not present in repo.
- Exploit scenario: If broad read policies exist, any authenticated user can enumerate profiles or sensitive user activity. If strict own-user policies exist, the admin UI will not work without service-side admin APIs.
- Recommended fix: Move admin data reads into server-side Next route handlers or Edge Functions using service role, with server-side `is_admin()` verification. Never expose `fcm_tokens` to the browser.

### H-02: `send-fcm` can be abused for arbitrary push notifications

- Severity: High
- File/table/route affected: `supabase/functions/send-fcm/index.ts:16`, `supabase/functions/send-fcm/index.ts:40`
- What is vulnerable: Authenticated callers can provide `user_id`, `title`, `body`, and `data`. There is no ownership/admin check, rate limit, or content control. It relies on RLS over `fcm_tokens` to block cross-user token lookup.
- Exploit scenario: If `fcm_tokens` read policy is broad or misconfigured, a user can send arbitrary push messages to other users. Even with own-token RLS, a user can spam their own devices and burn FCM resources.
- Recommended fix: Restrict to service/admin callers or enforce `user_id === caller.id` plus strict rate limits and use-case-specific templates.

### H-03: Public QF token exchange/refresh functions expose OAuth client-secret operations to every authenticated app user

- Severity: High
- File/table/route affected: `supabase/functions/qf-token-exchange/index.ts:20`, `supabase/functions/qf-token-refresh/index.ts:16`, `supabase/config.toml`
- What is vulnerable: `verify_jwt = true` means any Supabase-authenticated user can call the functions. The functions accept arbitrary `client_id`, return provider details, and use server-side QF client secrets.
- Exploit scenario: A malicious authenticated user scripts token refresh/exchange attempts and uses detailed provider errors for credential probing or abuse.
- Recommended fix: Validate `client_id` against an allowlist, validate redirect URI exactly, rate limit by `auth.uid()` and IP, and return generic errors.

### H-04: Direct profile updates from clients create mass-assignment risk unless RLS and column grants are strict

- Severity: High
- File/table/route affected: `lib/main.dart:494`, `lib/screens/profile_setup_screen.dart:137`, `lib/screens/profile_settings_screen.dart:162`, `lib/features/auth/data/qf_auth_service.dart:538`
- What is vulnerable: Multiple client paths upsert/update `profiles`. Repo does not show column-level restrictions. If RLS allows users to update their row with unrestricted columns, users may alter `noor_points`, role flags, streaks, or other computed fields.
- Exploit scenario: A user calls REST update against `profiles` and sets points/streak/admin-like columns.
- Recommended fix: Split editable profile fields into a separate table or use column-specific grants/RPCs. Revoke direct update on sensitive columns.

```sql
revoke update on public.profiles from authenticated;
grant select on public.profiles to authenticated;

create policy "profiles_read_own" on public.profiles
  for select to authenticated using (id = auth.uid());

create or replace function public.update_my_profile(
  p_display_name text,
  p_avatar_url text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set display_name = left(p_display_name, 80),
      avatar_url = p_avatar_url
  where id = auth.uid();
end;
$$;
```

### H-05: Donation and sponsor aggregate RPCs may expose user identities

- Severity: High
- File/table/route affected: `_sponsored_orphans_migration.sql:205`, `_project_recent_donors_migration.sql:10`, `lib/services/donation_service.dart:193`, `lib/services/donation_service.dart:439`
- What is vulnerable: Recent sponsor/donor functions return display names, avatars, donated amounts, and timestamps. Some project functions are granted to `anon`.
- Exploit scenario: Anyone can enumerate donor activity and infer giving patterns unless this is an explicit product requirement.
- Recommended fix: Return only public donor aliases or aggregate counts by default. Gate detailed donor lists to the donor themselves or admins.

### H-06: `get_user_orphan_sponsorships(p_user_id)` is an IDOR-prone RPC

- Severity: High
- File/table/route affected: `_sponsored_orphans_migration.sql:231`, `lib/services/donation_service.dart:517`
- What is vulnerable: Function accepts user ID and returns sponsored orphans. No auth check in function.
- Exploit scenario: Caller changes `p_user_id` to enumerate another user's donation history.
- Recommended fix:

```sql
create or replace function public.get_user_orphan_sponsorships()
returns table (
  orphan_id uuid,
  first_name text,
  last_initial text,
  photo_url text,
  city text,
  country text,
  total_donated bigint,
  last_donated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select o.id, o.first_name, o.last_initial, o.photo_url, o.city, o.country,
         sum(ud.points_donated)::bigint, max(ud.created_at)
  from public.user_donations ud
  join public.sponsored_orphans o on o.id = ud.orphan_id
  where ud.user_id = auth.uid()
  group by o.id
  order by max(ud.created_at) desc;
$$;
```

### H-07: Missing RLS definitions for many user-private tables

- Severity: High
- File/table/route affected: `profiles`, `user_analytics`, `user_activities`, `user_badges`, `quran_bookmarks`, `quran_progress`, `user_progress`, `fcm_tokens`, `streak_history`
- What is vulnerable: The repo uses these tables from the client, but RLS migrations are not present here. The prompt also states RLS is not enabled for all tables.
- Exploit scenario: Missing RLS on any of these tables allows cross-user reads/writes by changing IDs in REST requests.
- Recommended fix: Enable RLS and add owner policies for every user-owned table. Treat all missing RLS as critical until verified in the live database.

### H-08: Admin analytics views may expose broad user telemetry

- Severity: High
- File/table/route affected: `admin-web/src/app/dashboard/analytics/page.tsx:34`
- What is vulnerable: Browser admin page reads `analytics_country_summary` and `analytics_device_summary`. RLS/view security mode is not defined in repo.
- Exploit scenario: If views are selectable by authenticated or anon users, usage and geography telemetry can be scraped.
- Recommended fix: Restrict analytics views to `public.is_admin()` via security-barrier views or serve through an admin-only backend.

## Medium Findings

### M-01: Edge Functions use permissive CORS

- Severity: Medium
- File/table/route affected: `supabase/functions/send-fcm/index.ts:5`, `supabase/functions/qf-token-exchange/index.ts:4`, `supabase/functions/qf-token-refresh/index.ts:3`
- What is vulnerable: `Access-Control-Allow-Origin: *` allows any website to invoke functions from a user's browser if they have a token.
- Recommended fix: Restrict origins to production app/admin domains where browser invocation is required. Keep mobile flows token-bound.

### M-02: Sensitive error leakage from Edge Functions

- Severity: Medium
- File/table/route affected: `supabase/functions/send-fcm/index.ts:128`, `supabase/functions/qf-token-exchange/index.ts:45`, `supabase/functions/qf-token-refresh/index.ts:49`
- What is vulnerable: Error messages include DB errors, provider details, and token endpoint data.
- Recommended fix: Log details server-side, return generic errors to clients.

### M-03: No rate limits found for RPCs or Edge Functions

- Severity: Medium
- File/table/route affected: All public RPCs and Edge Functions
- What is vulnerable: Points, stats, token exchange, refresh, and notification functions can be scripted.
- Recommended fix: Add rate limit table keyed by `auth.uid()`/IP/function, or enforce through API gateway/Edge middleware.

### M-04: SECURITY DEFINER functions lack `set search_path`

- Severity: Medium
- File/table/route affected: `_stats_migration.sql`, `_daily_stats_migration.sql`, `_sponsored_orphans_migration.sql`, `_seal_credits_garden_migration.sql`
- What is vulnerable: Several functions use `SECURITY DEFINER` without `set search_path = public`, increasing risk of search-path hijacking.
- Recommended fix: Recreate all definer functions with `set search_path = public`.

### M-05: Notification cron jobs use service role and broad data scans

- Severity: Medium
- File/table/route affected: `supabase/functions/*reminder*/index.ts`, `supabase/functions/streak-at-risk/index.ts`, `supabase/functions/resume-reading/index.ts`
- What is vulnerable: Service-role jobs read `fcm_tokens`, `profiles`, `user_activities`, `quran_progress`, and `notification_log`. Invocation controls/schedules are not in repo.
- Recommended fix: Verify all cron functions require JWT or a scheduler secret. Add idempotency keys and per-user notification caps.

### M-06: Public content write flows lack moderation/audit logs

- Severity: Medium
- File/table/route affected: Admin project/orphan/onboarding/category/config pages
- What is vulnerable: Admin actions are not written to immutable audit logs.
- Recommended fix:

```sql
create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id),
  action text not null,
  target_table text,
  target_id text,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);
alter table public.admin_audit_log enable row level security;
create policy "admin_audit_admin_read" on public.admin_audit_log
  for select to authenticated using (public.is_admin());
```

### M-07: GitHub workflow hardening needs verification

- Severity: Medium
- File/table/route affected: `.github/workflows/build_qa.yml`, `.github/workflows/ios-testflight.yml`
- What is vulnerable: Build/deploy workflows exist, but branch protection, required reviews, Dependabot, and secret scanning settings are GitHub-side controls not verifiable from repo files.
- Recommended fix: Enable branch protection on main, required PR reviews, required status checks, CODEOWNERS, Dependabot security updates, secret scanning, push protection, and least-privilege GitHub Actions permissions.

### M-08: Admin app uses direct browser Supabase access for privileged operations

- Severity: Medium
- File/table/route affected: `admin-web/src/app/dashboard/**`
- What is vulnerable: Even with RLS fixed, the browser receives all admin UI code and relies on database policies for every operation.
- Recommended fix: Prefer Next route handlers/server components with `@supabase/ssr`, server-side admin verification, CSRF protection for cookie flows, and service role only on the server.

## Low Findings

### L-01: Root `.env` comments contradict `.gitignore`

- Severity: Low
- File/table/route affected: `.gitignore`, `.env`
- What is vulnerable: `.gitignore` says root `.env` is tracked with placeholders, while `.env` says never commit and contains real values.
- Recommended fix: Use `.env.example` only.

### L-02: Generated/build artifacts are present in the working tree

- Severity: Low
- File/table/route affected: `build/`, `admin-web/tsconfig.tsbuildinfo`, logs and scratch scripts
- What is vulnerable: Larger attack surface for accidental leakage and stale secret fragments.
- Recommended fix: Remove generated artifacts from version control and add ignore rules.

### L-03: Hardcoded admin emails are brittle

- Severity: Low
- File/table/route affected: `admin-web/src/lib/supabase.ts:9`
- What is vulnerable: Admin grants require code deploy and expose admin identities.
- Recommended fix: Use database roles managed by existing admins with audit logs.

### L-04: Public anon key duplication increases rotation work

- Severity: Low
- File/table/route affected: `lib/main.dart`, `call_function.dart`, `dump_schema.dart`, `seed_quran.dart`
- What is vulnerable: Anon key is public, but duplication makes key rotation error-prone.
- Recommended fix: Centralize config and remove scratch scripts or load from environment.

### L-05: Policy comments normalize insecure patterns

- Severity: Low
- File/table/route affected: SQL migration comments
- What is vulnerable: Comments saying "admin gating in app" encourage future insecure changes.
- Recommended fix: Update comments to state database-enforced role checks are mandatory.

## Supabase RLS Matrix

Status is based on repository SQL only. "Needs verification" means the table is used by code but no matching RLS migration was found locally.

| Table/view | RLS enabled? | Current policies found | Risk | Recommended policy |
| --- | --- | --- | --- | --- |
| `app_config` | Yes | Select true; insert/update/delete for authenticated (`_admin_rls_fix.sql`) | Critical: any authenticated user can change runtime config | Public/auth read only if non-sensitive; admin-only write using `public.is_admin()` |
| `sponsored_orphans` | Yes | Select true; insert/update/delete authenticated | Critical admin-content tampering | Public select only active rows; admin-only insert/update/delete |
| `community_project_media` | Yes | Select true; insert/update/delete authenticated | Critical media tampering | Public select; admin-only writes |
| `onboarding_images` | Yes | Select true; insert/update/delete authenticated | Critical onboarding tampering | Public select; admin-only writes |
| `user_monthly_stats` | Yes | Owner select; service_role all | Good baseline, but RPCs bypass owner checks | Owner select; no direct client writes; RPCs bind to `auth.uid()` |
| `user_daily_stats` | Yes | Owner select; service_role all | Good baseline, but `get_week_screen_time(p_user_id)` IDOR | Owner select; RPC binds to `auth.uid()` |
| `global_daily_stats` | Yes | Select true; service_role all | Public aggregate OK if intended | Public select; service/admin writes only |
| `user_dhikr_phrase_counts` | Yes | Owner select; service_role all | Needs RPC ownership review | Owner select; no direct writes; RPC binds to `auth.uid()` |
| `profiles` | Needs verification | None in repo | Critical if no RLS; high mass-assignment risk if broad update | Owner select/update only safe columns; admin read via server; sensitive columns not client writable |
| `user_donations` | Needs verification | Altered by orphan migration, no RLS shown | Critical financial/privacy table | Owner select own rows; insert only via secure RPC; no client update/delete; aggregates via safe RPC |
| `community_projects` | Needs verification | Admin app writes directly | Critical if authenticated writes exist | Public select active projects; admin-only writes |
| `community_project_updates` | Needs verification | Flutter reads | Medium content integrity | Public select for published; admin-only writes |
| `azkar_categories` | Needs verification | Admin app writes directly; Flutter reads | Critical if broad writes | Public select visible; admin-only writes |
| `azkar_items` | Needs verification | Flutter reads | High content integrity | Public select visible; admin-only writes |
| `onboarding_images` | Yes | Broad auth writes | Critical | Public select; admin-only writes |
| `quran_bookmarks` | Needs verification | Client reads/writes by `user_id` | Critical privacy/IDOR | Owner select/insert/update/delete where `user_id = auth.uid()` and WITH CHECK same |
| `quran_progress` | Needs verification | Client upsert/update by `user_id` | Critical privacy/IDOR | Owner select/upsert/update only |
| `user_progress` | Needs verification | Tafsir progress by `user_id` | Critical privacy/IDOR | Owner select/upsert/update only |
| `quran_verses` | Needs verification | Public content | Low if read-only | Public select; no client writes |
| `quran_translations` | Needs verification | Public content | Low if read-only | Public select; no client writes |
| `fcm_tokens` | Needs verification | Client upsert; Edge Functions read | Critical if readable by others | Owner insert/update/delete/select; service role read; never admin browser-readable |
| `notification_log` | Needs verification | Edge Functions insert/read | Medium spam/idempotency | Service role only, or owner select if exposed |
| `user_analytics` | Needs verification | Client upsert/read; admin reads | Critical telemetry privacy | Owner select/update via RPC only; admin via server |
| `user_activities` | Needs verification | Client inserts/reads; Edge jobs scan | Critical if broad | Owner select own; insert via RPC; no update/delete |
| `user_badges` | Needs verification | Client/admin reads | High privacy/integrity | Owner select; award via RPC/service; admin via server |
| `badges` | Needs verification | `xp_service` reads all, admin user page uses `badges.user_id` | Schema unclear | If catalog: public read/admin write. If user badges: owner policies |
| `challenges` | Needs verification | Client reads | Medium content integrity | Public read active; admin-only writes |
| `user_challenge_progress` | Needs verification | Client reads | High privacy | Owner select/update through RPC |
| `xp_levels` | Needs verification | Client reads | Low if read-only | Public select; admin-only writes |
| `leaderboard_global` | Needs verification | Client reads | Medium privacy | Public select only safe display fields; restrict exact user data if sensitive |
| `streak_history` | Needs verification | Client fallback reads | High privacy | Owner select only; writes via service/RPC |
| `analytics_country_summary` | Needs verification | Admin browser reads | High telemetry exposure | Admin-only server-side route or `public.is_admin()` view |
| `analytics_device_summary` | Needs verification | Admin browser reads | High telemetry exposure | Admin-only server-side route or `public.is_admin()` view |
| `app_roles` | Not present | Recommended new table | N/A | RLS enabled; only admins can read/manage, bootstrap first admin manually |

Owner policy template:

```sql
alter table public.quran_bookmarks enable row level security;

create policy "quran_bookmarks_owner_select" on public.quran_bookmarks
  for select to authenticated using (user_id = auth.uid());
create policy "quran_bookmarks_owner_insert" on public.quran_bookmarks
  for insert to authenticated with check (user_id = auth.uid());
create policy "quran_bookmarks_owner_update" on public.quran_bookmarks
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "quran_bookmarks_owner_delete" on public.quran_bookmarks
  for delete to authenticated using (user_id = auth.uid());

create index if not exists idx_quran_bookmarks_user_id on public.quran_bookmarks(user_id);
```

## Admin Panel Review

Admin access is not secure for production.

What was verified:

- `admin-web/src/lib/supabase.ts:9` defines `ADMIN_EMAILS` in client code.
- `admin-web/src/app/page.tsx:20` checks the email before sign-in.
- `admin-web/src/app/dashboard/layout.tsx:132` calls `supabase.auth.getUser()` and checks the same client-side email set.
- Admin pages perform direct Supabase browser writes to `app_config`, `community_projects`, `community_project_media`, `onboarding_images`, `sponsored_orphans`, `azkar_categories`, and likely users/points RPCs.
- SQL migrations back this with broad authenticated write policies, not trusted admin-role checks.

Impact:

- Changing localStorage alone does not grant Supabase authorization, but bypassing the UI entirely does. Any authenticated Supabase session can call the same REST/storage APIs if RLS permits it.
- Admin permission does not come from a trusted database source.
- The hardcoded email list is public in the JS bundle and cannot safely represent authorization.

Recommended secure role model:

1. Create `app_roles(user_id, role)` in Postgres.
2. Bootstrap initial admin manually in Supabase SQL editor.
3. Use `public.is_admin()` in RLS policies.
4. Move high-risk admin operations into server-side Next route handlers or Edge Functions.
5. Service role key must only run server-side.
6. Add `admin_audit_log` for all creates/updates/deletes/grants.
7. Remove all `TO authenticated WITH CHECK (true)` admin write policies.

## API and Backend Review

Edge Functions:

| Function | Auth/service role | Finding |
| --- | --- | --- |
| `send-fcm` | Caller anon client with Authorization header | Missing ownership/admin check, arbitrary title/body/data, no rate limit, permissive CORS, detailed errors. |
| `reward-webhook` | Service role | Missing webhook authentication; service-role FCM lookup; can spam if public. |
| `qf-token-exchange` | `verify_jwt = true` | Any authenticated user can use server-held client secret; needs allowlist/rate limits/generic errors. |
| `qf-token-refresh` | `verify_jwt = true` | Same as exchange; accepts client_id/refresh_token. |
| Reminder/cron functions | Service role | Schedule/invocation protection Needs verification; add scheduler secrets/idempotency/rate caps. |

Next backend:

- No API routes or server actions found.
- Admin app is client-side direct-to-Supabase. This makes RLS the only authorization layer.

Abuse prevention gaps:

- No rate limiting found for points/stats/donation RPCs.
- No abuse thresholds for points earned per time window.
- No CAPTCHA/bot control for signup or anonymous sessions found in repo.
- No account lockout/MFA requirement for admins found in repo.

## Secrets & GitHub Review

Secrets found:

| File | Finding |
| --- | --- |
| `.env:13` | QF prelive client secret present. |
| `.env:17` | QF production client secret present. |
| `_qf_bookmark_sync_status.md:55` | QF prelive client secret documented. |
| `call_function.dart:7`, `dump_schema.dart:7`, `seed_quran.dart:10`, `lib/main.dart:95` | Supabase anon JWT hardcoded. |
| `android/app/src/google-services.json` | Firebase web API key present. Usually public, but restrict in Google Cloud/Firebase. |

Required actions:

1. Rotate QF prelive and production client secrets.
2. Search Git history and remote GitHub for these values.
3. Replace root `.env` with `.env.example`; stop tracking real `.env`.
4. Enable GitHub secret scanning and push protection.
5. Enable branch protection, required reviews, required status checks, CODEOWNERS.
6. Enable Dependabot for npm, pub, Gradle, GitHub Actions.
7. Add CI checks: `gitleaks` or `trufflehog`, `npm audit`, `flutter analyze`, dependency review.
8. Restrict Firebase API key by package name/SHA where supported.

## Storage Review

`project-media`, `onboarding-images`, and `orphan-photos` are public buckets. Public read is product-reasonable for published content, but current writes are not safe:

- Any authenticated user can insert.
- Any authenticated user can update.
- Any authenticated user can delete.
- Object paths are not constrained.
- Upload overwrite controls rely on client behavior.

`avatars` bucket is used by `lib/screens/profile_settings_screen.dart:207`, with file path `avatars/{uid}/...` implied by code. Bucket and policies were not found in repo. Needs verification.

Recommended storage policy model:

| Bucket | Read | Write |
| --- | --- | --- |
| `project-media` | Public select | Admin-only insert/update/delete |
| `onboarding-images` | Public select | Admin-only insert/update/delete |
| `orphan-photos` | Public select for approved records only; consider private until approved | Admin-only insert/update/delete |
| `avatars` | Public select only if avatars are intended public | Owner-only path write/delete |

## Scalability Recommendations

RLS performance:

- Index every `auth.uid()` policy column: `profiles(id)`, `user_* (user_id)`, `fcm_tokens(user_id)`, `quran_bookmarks(user_id)`, `quran_progress(user_id)`, `user_donations(user_id)`.
- Add composite indexes for common filters:

```sql
create index if not exists idx_user_donations_user_created on public.user_donations(user_id, created_at desc);
create index if not exists idx_user_donations_project on public.user_donations(project_id) where project_id is not null;
create index if not exists idx_user_donations_orphan on public.user_donations(orphan_id) where orphan_id is not null;
create index if not exists idx_user_activities_user_created on public.user_activities(user_id, created_at desc);
create index if not exists idx_quran_bookmarks_user_surah_ayah on public.quran_bookmarks(user_id, surah, ayah);
create index if not exists idx_fcm_tokens_user_id on public.fcm_tokens(user_id);
```

Policy scalability:

- Avoid policies with unindexed subqueries per row.
- Use `public.is_admin()` carefully; ensure `app_roles.user_id` is primary key.
- Prefer `security definer` helper functions with fixed `search_path`.

Rate limits:

- Add per-user daily/hourly limits for point-earning RPCs, notification sends, QF token exchange/refresh, profile updates, and uploads.
- Add maximum donation/sponsor attempt frequency.
- Cap upload size and total files per admin action; buckets already define per-file limits for some buckets.

Logging/monitoring:

- Add immutable admin audit logs.
- Log failed authorization attempts.
- Monitor suspicious RPC rates, points earned, donation attempts, and upload failures.
- Use Supabase logs/alerts for RLS denied spikes and Edge Function error rates.

Abuse prevention:

- Enforce admin MFA.
- Disable or throttle anonymous sign-in abuse if QF flow allows anonymous sessions.
- Add server-side validation for all points/stats increments.
- Add idempotency keys to notification log writes.

## Prioritized Fix Plan

### Day 1 critical lock-down

- Rotate QF secrets and remove real `.env` values.
- Disable broad authenticated write policies on admin tables/storage.
- Add `app_roles` and `public.is_admin()`.
- Add shared-secret verification to `reward-webhook`.
- Revoke public execute on unsafe RPCs until patched.

### Day 2 RLS policies

- Verify live RLS status for every table.
- Enable RLS on all tables.
- Add owner policies for all user-owned tables.
- Add public read/admin write policies for public content tables.
- Add required indexes for RLS predicates.

### Day 3 admin hardening

- Replace hardcoded email allowlist with database roles.
- Move sensitive admin reads/writes into server-side routes or Edge Functions.
- Add admin audit logs.
- Require admin MFA and review admin invite/grant flow.

### Day 4 API fixes

- Patch `sponsor_orphan`, stats RPCs, phrase/streak/points RPCs to bind to `auth.uid()`.
- Validate payload ranges and activity types server-side.
- Restrict `send-fcm` to templates and owner/admin use.
- Add generic error responses.

### Day 5 storage/secrets

- Replace storage policies with admin/owner policies.
- Verify `avatars` bucket privacy and path isolation.
- Remove scratch scripts with hardcoded anon keys.
- Add GitHub secret scanning/push protection and CI secret scan.

### Day 6 logging/rate limits

- Add rate-limit tables or gateway controls.
- Add notification idempotency and per-user caps.
- Add monitoring alerts for Edge Function abuse and RLS denials.
- Add donation/points anomaly alerts.

### Day 7 retest

- Test direct REST calls as anon, normal authenticated user, admin, and service role.
- Attempt IDORs by changing `user_id`, `project_id`, `orphan_id`.
- Attempt storage overwrite/delete as normal user.
- Attempt admin route access with changed localStorage/cookies/query params.
- Re-run secret scan and dependency audit.
