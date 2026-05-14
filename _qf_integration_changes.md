# QF (Quran Foundation) bookmark-sync integration changes

Reference notes for everything I changed while wiring up the QF cross-sync
feature, so any of it can be reverted cleanly if needed.

## Quick rollback commands

```bash
# Show a single change in context
git log --oneline -- lib/services/quran_api_service.dart

# Revert a single file to its state before this work
git checkout <commit-before> -- lib/services/quran_api_service.dart

# Revert the whole feature on a branch
git revert <commit>..HEAD
```

## Files added

| File | Purpose | Safe to delete? |
|---|---|---|
| `_qf_integration_changes.md` | This file | Yes — pure documentation |

## Files modified

### `lib/core/env/env.dart`
- Added `qfUserApiBase` getter that returns `apis-prelive.quran.foundation`
  in dev and `apis.quran.foundation` in prod.
- To revert: remove the new getter.

### `lib/services/quran_api_service.dart`
- New constant resolution: `_kUserApiBase` now reads `Env.qfUserApiBase`
  (was previously hardcoded to `https://apis.quran.foundation`).
- New `_qfRequest()` helper wraps every user-API call with refresh-and-retry
  on HTTP 401 / 403 `invalid_token`.
- `_isAuthFailure()` helper detects expired-token responses.
- Added `getBookmarksRaw()` and `addBookmarkRaw()` — diagnostic-only methods.
- `getBookmarks()` URL now includes `?mushafId=1&first=20`.
- `removeBookmark()` URL now includes `?mushafId=1`.
- Response parser handles three list shapes: `[]`, `{bookmarks:[]}`,
  `{data:[]}`, `{data:{items:[]}}`.
- `syncBookmarks()` rewritten to be two-way: pulls from both stores in
  parallel, then upserts the deltas. Returns counts: `up`, `down`, `failed`.
- New `import '../core/env/env.dart';` and
  `import 'package:supabase_flutter/supabase_flutter.dart';`.
- To revert: `git checkout <prev> -- lib/services/quran_api_service.dart`.

### `lib/features/auth/data/qf_auth_service.dart`
- OAuth `scope:` parameter changed from `'openid'` to
  `Env.isDev ? 'openid offline_access user bookmark collection reading_session'
   : 'openid offline_access'`.
- This required two consent re-grants from the user (once for `offline_access`,
  once for the user-data scopes) — that's the only user-visible side-effect
  from this file.
- To revert: change the scope back to `'openid'` and have the user re-link.

### `lib/screens/quran_screen.dart`
- Four bug fixes for broken string interpolation: `'$_surah:_ayah'` →
  `'$_surah:$_ayah'` at lines 1410, 2249, 2250, 2262. Without these the
  in-memory bookmark/favourite key was always `"X:_ayah"` (literal) so
  toggles on every ayah treated them as the same item.
- `_loadBookmarks()` rewritten to merge Supabase + QF and trigger
  `_reconcileBookmarks()` in the background.
- New private `_reconcileBookmarks()` method.
- To revert: restore lines 1410/2249/2250/2262 to the original (broken) state
  and remove `_reconcileBookmarks()`.

### `lib/screens/start_journey_screen.dart`
- After `QfAuthService.instance.signIn()`, awaits
  `QuranApiService.instance.syncBookmarks()` (with 8s timeout) and shows
  the result in a SnackBar.
- New import: `'../services/quran_api_service.dart'`.

### `lib/main.dart`
- `initState` calls `QuranApiService.instance.syncBookmarks()` in the
  background when a QF token already exists at app launch.
- New helper `_syncQfBookmarksIfLinked()`.
- New import: `'services/quran_api_service.dart'`.

### `lib/screens/profile_settings_screen.dart`
- New "Sync Quran.com Bookmarks" support-card row.
- New `_runQuranComSyncDiagnostic()` method — runs sync, refresh probe,
  token JWT decode, /userinfo probe, multi-host probe, GET/POST probes,
  and dumps everything in a dialog.
- New imports: `dart:convert`, `package:http/http.dart as http`,
  `'../core/env/env.dart'`, `'../services/quran_api_service.dart'`.
- **This is the diagnostic UI.** When everything is verified working it
  can be removed — the support row + method are self-contained.

## Files **not** touched but worth noting

### `.env` (you edit this — not in git)
- `IS_DEV=true|false` switches the auth base (prelive vs production).
- `QURAN_PRELIVE_CLIENT_ID` / `QURAN_PROD_CLIENT_ID` — your QF client IDs.
- Defaults in `env.dart` are kept as a safety net if these env vars are
  missing.

### `supabase/functions/qf-token-exchange/`, `qf-token-refresh/`
- Source unchanged. **But you must set their secrets** in the Supabase
  dashboard:
    - `QF_CLIENT_SECRET_<client-id>` = `<client_secret from QF>` (per-id, optional)
    - `QF_CLIENT_SECRET` = `<client_secret from QF>` (generic fallback)
- These are looked up at runtime by the Edge Functions.

## Known config required at QF (developer portal)

- Add redirect URI `noorrewards://oauth2/callback` to **every** OAuth client
  you intend to use.
- Production client `44f22d7d-...` needs `bookmark` (and ideally `user`,
  `collection`, `reading_session`) added to its allow-listed scopes
  before sync can work in production.
