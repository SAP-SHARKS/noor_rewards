# Quran.com Bookmark Cross-Sync — Status & Next Steps

Reference doc to pick up the bookmark-sync feature where we left off,
once Quran Foundation enables the production scopes.

---

## TL;DR — Where we are right now

- **PRELIVE**: cross-sync between the app and `apis-prelive.quran.foundation`
  is **fully working**. Bookmarks toggle in both directions, sync stays in
  agreement, auto-refresh handles token expiry.
- **PRODUCTION** (the actual `quran.com` web user data store): **blocked on
  Quran Foundation** enabling the user-data scopes on our production OAuth
  client. The OAuth login flow itself works; user-feature scopes are
  disabled by default per QF policy. (Confirmed by Basit Minhas at QF on
  the support thread.)
- All Flutter code changes are stable and shipped. Nothing on our side
  needs to change to switch from prelive → production. Just config.

---

## What's done (code)

| Area | File | Change |
|---|---|---|
| API host | `lib/core/env/env.dart` | `qfUserApiBase` switches `apis-prelive.quran.foundation` ↔ `apis.quran.foundation` based on `Env.isDev`. |
| API host | `lib/services/quran_api_service.dart` | `_kUserApiBase` reads `Env.qfUserApiBase`. |
| OAuth scopes | `lib/features/auth/data/qf_auth_service.dart` | Dev requests full scope set (`openid offline_access user bookmark collection reading_session`); prod requests just `openid offline_access` until QF enables the rest. |
| Refresh + retry | `lib/services/quran_api_service.dart` | `_qfRequest` detects 401 / 403 `invalid_token`, calls `QfAuthService.refresh()`, replays the request once. |
| GET pagination | `lib/services/quran_api_service.dart` | URL is `?mushafId=1&first=20` (max page size is 20; `first` or `last` is required). |
| DELETE | `lib/services/quran_api_service.dart` | URL is `/auth/v1/bookmarks/$s:$a?mushafId=1`. |
| POST body | `lib/services/quran_api_service.dart` | `{key, type:"ayah", verseNumber, mushaf:1}`. |
| Response parser | `lib/services/quran_api_service.dart` | Handles `{success, data:[…]}` envelope and other shapes. |
| Two-way reconcile | `lib/services/quran_api_service.dart` `syncBookmarks()` | Pulls both sides in parallel, upserts the deltas QF→Supabase + pushes the deltas Supabase→QF. Surfaces `(up, down, failed)` counts. |
| Toggle reliability | `lib/screens/quran_screen.dart` `_toggleBookmark` | Both QF and Supabase writes are awaited together; on either failure the local UI rolls back so the icon stays consistent. Fixes "unbookmark doesn't stick" caused by a fire-and-forget QF DELETE. |
| Non-blocking load | `lib/screens/quran_screen.dart` `_loadBookmarks` | Paints Supabase bookmarks immediately; QF fetch + reconcile run in `_syncWithQfInBackground` so a slow QF can't stall the Quran reader. |
| Post-login sync | `lib/screens/start_journey_screen.dart` | Calls `syncBookmarks()` with an 8s timeout right after `QfAuthService.signIn()` completes; shows the result in a SnackBar. |
| Boot-time sync | `lib/main.dart` | On app launch, if a QF token already exists, runs `syncBookmarks()` in the background. |
| Inline error banner | `lib/screens/start_journey_screen.dart` | A red banner at the top of the login screen shows `QfAuthService.lastSignInErrorN` whenever a sign-in attempt failed. Dismissible. |
| Email-conflict bypass | `lib/features/auth/data/qf_auth_service.dart` `_fetchAndStoreUserInfo` | Returning-user check (`isSameSub`) happens before the email_account_exists call, so re-linking the same QF identity (e.g. after env switching) never bounces back to login. |
| Diagnostic UI | `lib/screens/profile_settings_screen.dart` | "Sync Quran.com Bookmarks" support row → runs `syncBookmarks()` and shows a concise dialog: green success message + counts on both sides, or red error + last sign-in error. |

(Verbose diagnostic probes that helped us hunt down config issues — JWT
decode, 5-host loop, raw HTTP dumps, `[stats]` debug spam — were all
removed once the integration stabilized.)

---

## What's done (config — already applied)

### Supabase Edge Function secrets

- `QF_ENV` = `prelive` (for prelive testing) OR `production` (for prod).
- `QF_CLIENT_SECRET_a9a32c8d-b110-4ac0-b8d8-fa4714be01c6` = `GHswlErrEnTj14GANnsOvK_iAw`
  → prelive client secret.
- `QF_CLIENT_SECRET_44f22d7d-b4dc-467b-b4c8-04f545c124e1` = (set previously)
  → production client secret. Verify it matches what QF gave us.

### `.env`

- `IS_DEV=true` for prelive testing; `IS_DEV=false` for production.
- `QURAN_PRELIVE_CLIENT_ID=a9a32c8d-b110-4ac0-b8d8-fa4714be01c6` (our own).
- `QURAN_PROD_CLIENT_ID=44f22d7d-b4dc-467b-b4c8-04f545c124e1` (our own).

### QF developer portal

- Redirect URI `noorrewards://oauth2/callback` is whitelisted on both
  prelive client (`a9a32c8d-…`) and production client (`44f22d7d-…`).
- **Prelive client** has full scopes enabled: `user`, `bookmark`,
  `collection`, `reading_session`, plus `openid` and `offline_access`.
- **Production client** currently has only `openid` enabled. This is
  what we're waiting on QF to expand.

---

## What's blocked — production scope enablement

### The blocker

Quran Foundation confirmed: production OAuth clients have **NO
authentication / user features enabled by default**. The OAuth login
flow works (we verified that), but bookmarks / reading sessions /
collections / userinfo all return `insufficient_scope` or `invalid_token`
until QF specifically enables those scopes for our prod client.

### What to request from QF support

Reply to Basit Minhas (`pak.zakn@gmail.com` thread) and ask:

> Salam Basit,
>
> Please enable the following scopes on our production OAuth client
> `44f22d7d-b4dc-467b-b4c8-04f545c124e1` so we can ship cross-sync
> bookmarks between our app (Sabiq Rewards) and quran.com:
>
> - `offline_access`
> - `user`
> - `bookmark`
> - `collection`
> - `reading_session`
>
> All five scopes are already enabled on our prelive client
> `a9a32c8d-…` and we have the cross-sync working end-to-end there.
> We just need the same set unlocked on production so we can demo
> against the live quran.com user data store.
>
> Jazakum Allahu Khairan,

### When QF replies that scopes are enabled

Do this in order:

1. In `lib/features/auth/data/qf_auth_service.dart`, find the `signIn()`
   method and change the `scope:` parameter so production also requests
   the full set:

   ```dart
   // Before (current):
   'scope': Env.isDev
       ? 'openid offline_access user bookmark collection reading_session'
       : 'openid offline_access',

   // After:
   'scope':
       'openid offline_access user bookmark collection reading_session',
   ```

2. In `.env`, set:
   ```
   IS_DEV=false
   ```

3. In Supabase Dashboard → Edge Functions → Secrets, set:
   ```
   QF_ENV = production
   ```

4. **Clear app data** on the test device (Settings → Apps → Sabiq
   Rewards → Storage → Clear data). This avoids the email-conflict
   bounce-back that would otherwise trigger because the same email is
   already stamped on a prelive Supabase user.

5. Re-open the app. Tap **Continue with Quran**. The QF consent screen
   should now list bookmark / user / collection / reading_session
   permissions. Approve.

6. Go to **Profile Settings → Help & Support → Sync Quran.com
   Bookmarks**. Expected result:
   - Green message: `Synced N bookmarks (X up, Y down)` or
     `Bookmarks already in sync`.
   - Counts on both sides should match.
   - Mulk and Taha (and any other bookmarks you made on
     quran.com web) should appear in the app's Quran reader.
   - Any bookmarks you make in the app should appear on
     quran.com/my-quran.

If anything fails at this point, share the diagnostic dialog +
the `Last sign-in error` if any is shown — most likely it'll be
a scope name typo or a still-disabled scope.

---

## Verifying prelive still works (sanity check)

Useful for the hackathon demo / smoke-test while we wait on
production.

1. `.env` → `IS_DEV=true`.
2. Supabase `QF_ENV` → `prelive` (or anything not "production"; the
   Edge Function falls back to prelive).
3. Hot-restart the app.
4. **Continue with Quran** → consent → returns to dashboard.
5. Open the Quran reader, bookmark any ayah (e.g. 5:7).
6. Profile Settings → Sync Quran.com Bookmarks → should show
   `Synced 1 bookmark (1 up, 0 down)` and `Bookmarks on Quran.com: N`
   counting up by one.

If prelive ever starts returning 504s or other infra errors,
that's a Quran Foundation server outage. No code change fixes it;
wait 10–15 minutes and retry.

---

## Known issue — performance

When the QF API is degraded (504 gateway-timeout), every QF call
takes up to 10 s before timing out. We mitigated this by making
`_loadBookmarks` paint Supabase data immediately and reconcile QF
in the background, but individual toggle actions still wait on
QF round-trips (necessary for correctness — we don't want to claim
a bookmark synced when it didn't). When QF is healthy, response
times are sub-second.

If you ever see the Quran reader taking many seconds to first
paint, that's almost always a slow `_fetchAyah` against
`api.quran.com` (un-cached surah on a slow network). Subsequent
opens of the same surah use the 7-day Hive cache and are instant.

---

## Rollback (if anything breaks)

Every change is documented per-file in `_qf_integration_changes.md`
with revert commands. The shortest emergency rollback is:

```bash
git revert <commit-range-for-bookmark-sync>
```

Worst-case, simply disable the feature by removing the
"Sync Quran.com Bookmarks" support-row from
`lib/screens/profile_settings_screen.dart` and not calling
`syncBookmarks()` anywhere — the rest of the app keeps working.
