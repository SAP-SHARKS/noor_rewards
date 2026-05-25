# Manual Review Checklist

The audit found 5 things that I can't verify from the repo — only you can check them in the Supabase Dashboard or GitHub Settings. Work through each in order. **Most important first.**

For every SQL query below, run it in **Supabase Dashboard → SQL Editor**.

---

## 1. Profiles table RLS (Critical — affects every user)

**Why it matters:** The Flutter app does direct `from('profiles').upsert(...)` from many screens. If profiles RLS is missing or too loose, any user could change another user's points/level/streak by hitting REST directly.

**Check what's there now:**

```sql
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'profiles';

SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'profiles';
```

**What you want to see:**
- `relrowsecurity` = `true`
- At least 2 policies — one for SELECT, one for UPDATE — both with `qual: (id = auth.uid())` and UPDATE also with `with_check: (id = auth.uid())`
- NO `INSERT` or `UPDATE` policy with `qual: true` or roles `{public}` (that would mean any user can update any profile)

**If it's missing or too loose**, paste the query result here and I'll write the migration.

---

## 2. Other tables with no RLS in the repo (High)

These 18 tables are written/read from the client but have no RLS migration committed. RLS may already be configured live; we just can't see it from source.

**Check which tables have RLS enabled:**

```sql
SELECT relname AS table_name,
       relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND relkind = 'r'
  AND relname IN (
    'profiles', 'community_projects', 'user_donations', 'fcm_tokens',
    'user_activities', 'user_badges', 'streak_history', 'quran_bookmarks',
    'quran_progress', 'user_progress', 'user_analytics',
    'leaderboard_global', 'azkar_categories', 'azkar_items',
    'badges', 'challenges', 'user_challenge_progress', 'xp_levels'
  )
ORDER BY table_name;
```

**What you want:** every row's `rls_enabled` = `true`.

**For any that show `false`**, paste the list here and I'll write owner-only policies in one migration.

---

## 3. fcm_tokens RLS (Critical — prevents push spoofing)

`fcm_tokens` is referenced by 8 edge functions. If non-owners can read it, any user can look up another user's FCM token and send them notifications.

```sql
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'fcm_tokens';
```

**What you want:**
- SELECT/INSERT/UPDATE/DELETE policies all with `qual: (user_id = auth.uid())` for the `authenticated` role
- A separate `service_role` policy with `qual: true` (so the edge functions work)

---

## 4. Analytics views (Medium — privacy)

The admin analytics page reads `analytics_country_summary` and `analytics_device_summary`. If these are views without RLS, any logged-in user could scrape them.

```sql
SELECT viewname, viewowner FROM pg_views
WHERE viewname IN ('analytics_country_summary', 'analytics_device_summary');

SELECT relname, relrowsecurity FROM pg_class
WHERE relname IN ('analytics_country_summary', 'analytics_device_summary');
```

If views exist and have no RLS, change them to be security-definer functions gated on `public.is_admin()`. Paste the result and I'll handle it.

---

## 5. Cron jobs / edge function invocation gates (Medium)

Several edge functions use the service-role key and run via Supabase cron (`nightly-coin-reminder`, `monthly-quran-reminder`, etc.). Check that random visitors can't invoke them by URL.

**Supabase Dashboard → Edge Functions → for each of:**
- `community-momentum`
- `level-up-close`
- `local-azkaar-reminders`
- `monthly-milestone`
- `monthly-quran-reminder`
- `nightly-coin-reminder`
- `resume-reading`
- `streak-at-risk`

Open each → **Details** → check **"Verify JWT"** is either:
- `ON` (only authenticated callers — admin or service-role token from the scheduler)
- OR these functions have a shared-secret check in their code

If any have **JWT verification OFF** AND no in-code secret check, anyone with the URL can invoke them — flag it and we'll add `x-cron-secret` checks (same pattern as `reward-webhook` from Phase 4).

---

## 6. GitHub repo hardening (Medium — one-time setup)

Open https://github.com/SAP-SHARKS/noor_rewards → **Settings**.

Tick these:

- [ ] **General → Default branch** = `main`
- [ ] **Branches → Branch protection rules → Add rule for `main`**:
  - Require a pull request before merging
  - Require approvals (1+)
  - Require status checks (none yet — that's fine)
  - Do NOT allow force pushes (except from you)
- [ ] **Code security → Secret scanning** = **Enabled**
- [ ] **Code security → Push protection** = **Enabled** (this is the big one — GitHub will reject pushes that contain secret patterns)
- [ ] **Code security → Dependabot alerts** = **Enabled**
- [ ] **Code security → Dependabot security updates** = **Enabled**

Push protection alone would have prevented the QF secret commit.

---

## 7. Admin MFA (Critical for the 2 admin accounts)

The two admin Google accounts (`pak.zakn@gmail.com`, `zaid_azam@zeir.io`) have full DB write access via the admin web. Anyone who phishes those accounts owns the app.

For each admin email:
1. Go to https://myaccount.google.com/security
2. Confirm **2-Step Verification** is ON
3. Confirm at least one **Security key** (YubiKey) OR **Google Authenticator** is registered
4. Avoid SMS as the only second factor (SIM-swappable)

---

## When to come back

After working through 1–5, paste the results that don't look right and I'll write fix migrations. For 6 & 7, just check them off — no code involvement needed.
