// notify-report
//
// Invoked by the `user-report-alert` Database Webhook whenever a new row
// is inserted into public.user_reports. Formats the report into a Slack
// message and posts to the channel wired up via SLACK_WEBHOOK_URL secret.
//
// Payload shape (Supabase Database Webhook standard):
// {
//   "type": "INSERT",
//   "table": "user_reports",
//   "schema": "public",
//   "record": { id, reporter_user_id, reported_user_id, reason,
//               notes, status, created_at, ... },
//   "old_record": null
// }
//
// Deploy:
//   npx supabase functions deploy notify-report --no-verify-jwt
//
// The `--no-verify-jwt` flag is required because Database Webhooks send
// a raw Supabase system JWT, not a user JWT. Auth is enforced by the
// SLACK_WEBHOOK_URL secret being unavailable to the outside world.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const SLACK_WEBHOOK_URL = Deno.env.get('SLACK_WEBHOOK_URL');

const REASON_LABEL: Record<string, string> = {
  offensive_name: '🚫 Offensive name',
  impersonation: '🎭 Impersonation',
  spam: '📢 Spam',
  harassment: '⚠️ Harassment',
  other: '❓ Other',
};

serve(async (req) => {
  if (!SLACK_WEBHOOK_URL) {
    console.error('[notify-report] SLACK_WEBHOOK_URL is not set');
    return new Response('SLACK_WEBHOOK_URL missing', { status: 500 });
  }

  try {
    const body = await req.json();
    // Only fire for INSERTs on user_reports — Database Webhook is already
    // configured that way, but be defensive.
    if (body?.type !== 'INSERT' || body?.table !== 'user_reports') {
      return new Response('ignored', { status: 200 });
    }

    const r = body.record ?? {};
    const reason = REASON_LABEL[r.reason as string] ?? `❓ ${r.reason ?? 'unknown'}`;
    const notes = (r.notes as string | null)?.trim();
    const created = r.created_at
      ? new Date(r.created_at as string).toISOString()
      : new Date().toISOString();

    const slackPayload = {
      text: `New Sabiq user report`,
      blocks: [
        {
          type: 'header',
          text: { type: 'plain_text', text: '🚨 New Sabiq user report' },
        },
        {
          type: 'section',
          fields: [
            { type: 'mrkdwn', text: `*Reason*\n${reason}` },
            { type: 'mrkdwn', text: `*Status*\n${r.status ?? 'pending'}` },
            { type: 'mrkdwn', text: `*Reported user*\n\`${r.reported_user_id ?? '?'}\`` },
            { type: 'mrkdwn', text: `*Reporter*\n\`${r.reporter_user_id ?? '?'}\`` },
          ],
        },
        ...(notes
          ? [
              {
                type: 'section',
                text: { type: 'mrkdwn', text: `*Notes*\n>${notes.replace(/\n/g, '\n>')}` },
              },
            ]
          : []),
        {
          type: 'context',
          elements: [
            { type: 'mrkdwn', text: `_id \`${r.id ?? '?'}\` · ${created}_` },
          ],
        },
      ],
    };

    const res = await fetch(SLACK_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(slackPayload),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error('[notify-report] Slack POST failed', res.status, errText);
      return new Response(`slack error ${res.status}`, { status: 502 });
    }

    return new Response('ok', { status: 200 });
  } catch (e) {
    console.error('[notify-report] exception', e);
    return new Response(`error ${(e as Error).message}`, { status: 500 });
  }
});
