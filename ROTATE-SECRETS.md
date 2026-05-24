# What you need to do

Your QF (Quran Foundation) secret keys got pushed to GitHub. Anyone who saw the repo has them. Do these 4 things in order.

---

## 1. Get new keys from Quran Foundation (5 minutes)

1. Go to https://api-docs.quran.foundation/ and log in.
2. Find the app called "Sabiq" / "Noor Rewards".
3. Click **Regenerate secret** on the production app.
4. Click **Regenerate secret** on the pre-live app.
5. Copy the 4 new values somewhere safe (your password manager).

You now have new keys. The old ones still work for a few minutes — keep going.

---

## 2. Update where the new keys live (10 minutes)

**In Codemagic** (the thing that builds your app):
- Open Codemagic → your app → Environment variables
- Replace these 4 values with the new ones:
  - `QURAN_PROD_CLIENT_ID`
  - `QURAN_PROD_CLIENT_SECRET`
  - `QURAN_PRELIVE_CLIENT_ID`
  - `QURAN_PRELIVE_CLIENT_SECRET`

**In Supabase** (for the edge functions):
- Open Supabase dashboard → your project → Settings → Edge Functions → Secrets
- Replace `QF_CLIENT_SECRET` (and `QF_CLIENT_ID` if present) with the new values.

**On your laptop:**
- Open `D:\noor_rewards-main\noor_rewards-main\.env` in a text editor
- Replace the 4 values with the new ones
- Save

---

## 3. Stop tracking the `.env` file (5 minutes)

Open a terminal in `D:\noor_rewards-main\noor_rewards-main` and run these one at a time:

```
git rm --cached .env
git rm -r --cached supabase/.temp/
```

Then open `.gitignore` in a text editor. Find the line `!.env` and **delete it**.

Then save and run:

```
git add .gitignore
git commit -m "stop tracking .env"
git push
```

---

## 4. Tell me when done

Say **"done"** and I'll start the next fix. We can clean up the git history later — the most important thing is that the old keys no longer work because you rotated them in step 1.