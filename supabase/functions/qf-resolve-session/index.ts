// qf-resolve-session
//
// Takes a Quran Foundation access token, verifies it against the QF
// /userinfo endpoint, then returns a Supabase magic-link token_hash that
// signs the client into the existing Supabase user (matched by qf_sub or
// email) — or creates a brand-new Supabase user if no match exists.
//
// This replaces the previous "signInAnonymously + merge" dance on the
// client, which left a trail of orphan merged-out profile rows every time
// a user re-logged-in with the same QF account.
//
// Request body:  { qf_access_token: string }
// Response 200:  { token_hash: string, email: string, is_existing: boolean }
// Response 401:  invalid QF token
// Response 500:  internal error

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { qf_access_token } = await req.json();
    if (!qf_access_token || typeof qf_access_token !== "string") {
      return json({ error: "missing_qf_access_token" }, 400);
    }

    // 1) Resolve the QF identity (email + sub) by calling QF userinfo with
    //    the token. This both verifies the token is valid and gives us the
    //    canonical identity to key off of.
    const qfEnv = Deno.env.get("QF_ENV") || "production";
    const authBase =
      qfEnv === "production"
        ? "https://oauth2.quran.foundation"
        : "https://prelive-oauth2.quran.foundation";

    const uiRes = await fetch(`${authBase}/userinfo`, {
      headers: { Authorization: `Bearer ${qf_access_token}` },
    });
    if (!uiRes.ok) {
      console.warn("qf-resolve-session: QF userinfo failed", uiRes.status);
      return json({ error: "invalid_qf_token" }, 401);
    }

    const info = await uiRes.json();
    const email = (info.email as string | undefined)?.toLowerCase().trim();
    const sub = (info.sub as string | undefined)?.trim();
    const name = (info.name as string | undefined) || "";
    const picture = (info.picture as string | undefined) || "";

    if (!email && !sub) {
      console.error("qf-resolve-session: userinfo missing both email and sub");
      return json({ error: "qf_userinfo_incomplete" }, 502);
    }

    // 2) Look up an existing Supabase user. First by qf_sub (most reliable —
    //    a returning QF user always has the same sub), then by email as a
    //    fallback for users who linked Google first and then QF.
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    let userId: string | null = null;

    if (sub) {
      const { data, error } = await admin.rpc("find_auth_user_by_qf_sub", {
        p_sub: sub,
      });
      if (!error && data) userId = data as string;
    }

    if (!userId && email) {
      const { data, error } = await admin.rpc("find_auth_user_by_email", {
        p_email: email,
      });
      if (!error && data) userId = data as string;
    }

    let signInEmail = email;
    let isExisting = !!userId;

    // 3a) Existing user — make sure their qf_sub is stamped (in case this
    //     is the email-fallback match), then generate a magic link.
    if (userId) {
      const { data: u } = await admin.auth.admin.getUserById(userId);
      const existingEmail = u?.user?.email;
      if (existingEmail) signInEmail = existingEmail.toLowerCase();

      // Stamp qf_sub if it wasn't there yet so the next login is a
      // direct sub-match (no email fallback needed).
      const existingMeta = (u?.user?.user_metadata as Record<string, unknown>) ||
        {};
      if (sub && existingMeta.qf_sub !== sub) {
        await admin.auth.admin.updateUserById(userId, {
          user_metadata: {
            ...existingMeta,
            qf_sub: sub,
            qf_email: email ?? existingMeta.qf_email,
            qf_name: name || existingMeta.qf_name,
            qf_picture: picture || existingMeta.qf_picture,
            provider: "quran_com",
          },
        });
      }
    } else {
      // 3b) No matching user — create one.
      if (!email) {
        // Can't create without email. Caller should fall back to
        // anonymous signin (which the old path did).
        return json({ error: "qf_userinfo_no_email" }, 400);
      }
      const { data: created, error: createErr } =
        await admin.auth.admin.createUser({
          email,
          email_confirm: true,
          user_metadata: {
            provider: "quran_com",
            qf_sub: sub,
            qf_email: email,
            qf_name: name,
            qf_picture: picture,
            full_name: name,
            avatar_url: picture,
          },
        });
      if (createErr || !created?.user) {
        console.error("qf-resolve-session: createUser failed", createErr);
        return json({ error: "create_user_failed" }, 500);
      }
      userId = created.user.id;
      signInEmail = email;
    }

    // 4) Generate a magic-link OTP for the resolved user. The client uses
    //    verifyOTP({type: magiclink, tokenHash}) to mint a real session
    //    without ever needing to navigate to the action_link.
    const { data: linkData, error: linkErr } =
      await admin.auth.admin.generateLink({
        type: "magiclink",
        email: signInEmail!,
      });

    if (linkErr || !linkData?.properties) {
      console.error("qf-resolve-session: generateLink failed", linkErr);
      return json({ error: "magic_link_failed" }, 500);
    }

    const tokenHash = (linkData.properties as Record<string, string>)
      .hashed_token;
    if (!tokenHash) {
      console.error(
        "qf-resolve-session: generateLink returned no hashed_token",
        linkData.properties,
      );
      return json({ error: "magic_link_missing_hash" }, 500);
    }

    return json({
      token_hash: tokenHash,
      email: signInEmail,
      is_existing: isExisting,
    });
  } catch (err) {
    console.error("qf-resolve-session error:", err);
    return json({ error: "internal" }, 500);
  }
});
