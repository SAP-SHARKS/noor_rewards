// Shared FCM credential resolver for all push-notification Edge Functions.
//
// Tries one secret first: `FIREBASE_SERVICE_ACCOUNT` — the full JSON downloaded
// from Firebase Console → Project Settings → Service Accounts → Generate
// new private key. Falls back to the older split-secret form
// (`FCM_PROJECT_ID` + `FCM_CLIENT_EMAIL` + `FCM_PRIVATE_KEY`) so an existing
// deployment without the JSON keeps working.
//
// Usage:
//   import { getFcmCreds } from '../_shared/fcm.ts';
//   const { projectId, clientEmail, privateKey } = getFcmCreds();
//
// Both forms accept `\n`-escaped private keys (the way Supabase stores
// multi-line secrets) and unescape them before returning.

export interface FcmCreds {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

export function getFcmCreds(): FcmCreds {
  // Preferred: single JSON blob.
  const json = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (json && json.trim().length > 0) {
    try {
      const sa = JSON.parse(json);
      const projectId = sa.project_id as string | undefined;
      const clientEmail = sa.client_email as string | undefined;
      const privateKeyRaw = sa.private_key as string | undefined;
      if (!projectId || !clientEmail || !privateKeyRaw) {
        throw new Error(
          'FIREBASE_SERVICE_ACCOUNT JSON missing required fields ' +
            '(project_id, client_email, private_key)',
        );
      }
      return {
        projectId,
        clientEmail,
        privateKey: privateKeyRaw.replace(/\\n/g, '\n'),
      };
    } catch (e) {
      throw new Error(
        `Failed to parse FIREBASE_SERVICE_ACCOUNT JSON: ${(e as Error).message}`,
      );
    }
  }

  // Legacy fallback: 3 separate secrets.
  const projectId = Deno.env.get('FCM_PROJECT_ID');
  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
  const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');
  if (!projectId || !clientEmail || !privateKeyStr) {
    throw new Error(
      'FCM credentials missing. Set FIREBASE_SERVICE_ACCOUNT (JSON) OR ' +
        'all three of FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY.',
    );
  }
  return {
    projectId,
    clientEmail,
    privateKey: privateKeyStr.replace(/\\n/g, '\n'),
  };
}
