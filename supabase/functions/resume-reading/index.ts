// resume-reading — "You left off at Surah X, Ayah Y" nudge
// Schedule: Cron every hour, targets users whose local time is ~14:00 (2 PM)
// Only sends to users who read yesterday but not today

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';

const SURAH_NAMES: Record<number, string> = {
  1:'Al-Fatiha',2:'Al-Baqarah',3:'Ali Imran',4:'An-Nisa',5:'Al-Maidah',
  6:'Al-Anam',7:'Al-Araf',8:'Al-Anfal',9:'At-Tawbah',10:'Yunus',
  11:'Hud',12:'Yusuf',13:'Ar-Rad',14:'Ibrahim',15:'Al-Hijr',
  16:'An-Nahl',17:'Al-Isra',18:'Al-Kahf',19:'Maryam',20:'Ta-Ha',
  21:'Al-Anbiya',22:'Al-Hajj',23:'Al-Muminun',24:'An-Nur',25:'Al-Furqan',
  26:'Ash-Shuara',27:'An-Naml',28:'Al-Qasas',29:'Al-Ankabut',30:'Ar-Rum',
  31:'Luqman',32:'As-Sajdah',33:'Al-Ahzab',34:'Saba',35:'Fatir',
  36:'Ya-Sin',37:'As-Saffat',38:'Sad',39:'Az-Zumar',40:'Ghafir',
  41:'Fussilat',42:'Ash-Shura',43:'Az-Zukhruf',44:'Ad-Dukhan',45:'Al-Jathiyah',
  46:'Al-Ahqaf',47:'Muhammad',48:'Al-Fath',49:'Al-Hujurat',50:'Qaf',
  51:'Adh-Dhariyat',52:'At-Tur',53:'An-Najm',54:'Al-Qamar',55:'Ar-Rahman',
  56:'Al-Waqiah',57:'Al-Hadid',58:'Al-Mujadilah',59:'Al-Hashr',60:'Al-Mumtahanah',
  61:'As-Saff',62:'Al-Jumuah',63:'Al-Munafiqun',64:'At-Taghabun',65:'At-Talaq',
  66:'At-Tahrim',67:'Al-Mulk',68:'Al-Qalam',69:'Al-Haqqah',70:'Al-Maarij',
  71:'Nuh',72:'Al-Jinn',73:'Al-Muzzammil',74:'Al-Muddaththir',75:'Al-Qiyamah',
  76:'Al-Insan',77:'Al-Mursalat',78:'An-Naba',79:'An-Naziat',80:'Abasa',
  81:'At-Takwir',82:'Al-Infitar',83:'Al-Mutaffifin',84:'Al-Inshiqaq',85:'Al-Buruj',
  86:'At-Tariq',87:'Al-Ala',88:'Al-Ghashiyah',89:'Al-Fajr',90:'Al-Balad',
  91:'Ash-Shams',92:'Al-Layl',93:'Ad-Duha',94:'Ash-Sharh',95:'At-Tin',
  96:'Al-Alaq',97:'Al-Qadr',98:'Al-Bayyinah',99:'Az-Zalzalah',100:'Al-Adiyat',
  101:'Al-Qariah',102:'At-Takathur',103:'Al-Asr',104:'Al-Humazah',105:'Al-Fil',
  106:'Quraysh',107:'Al-Maun',108:'Al-Kawthar',109:'Al-Kafirun',110:'An-Nasr',
  111:'Al-Masad',112:'Al-Ikhlas',113:'Al-Falaq',114:'An-Nas',
};

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const now = new Date();

    // 1. Get FCM tokens, filter for 2 PM local
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);

    const afternoonUsers = new Map<string, { token: string; locale: string }>();
    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        const hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '0', 10);
        if (hour === 14) {
          afternoonUsers.set(row.user_id, {
            token: row.token,
            locale: row.app_locale ?? 'en',
          });
        }
      } catch { /* skip */ }
    }

    if (afternoonUsers.size === 0) {
      return new Response(JSON.stringify({ message: 'No users at 14:00' }));
    }

    // 2. Get quran_progress for these users — who read yesterday but not today
    const today = now.toISOString().substring(0, 10);
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const yStr = yesterday.toISOString().substring(0, 10);

    const { data: progress } = await supabase
      .from('quran_progress')
      .select('user_id, current_surah, current_ayah, last_read_date')
      .in('user_id', [...afternoonUsers.keys()]);

    const resumeUsers: { userId: string; token: string; locale: string; surah: number; ayah: number }[] = [];
    for (const p of progress || []) {
      // Read yesterday (or earlier) but NOT today
      if (p.last_read_date && p.last_read_date !== today && p.current_surah > 0) {
        const entry = afternoonUsers.get(p.user_id);
        if (entry) {
          resumeUsers.push({
            userId: p.user_id,
            token: entry.token,
            locale: entry.locale,
            surah: p.current_surah,
            ayah: p.current_ayah,
          });
        }
      }
    }

    // 3. Dedup
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'resume_reading')
      .gte('sent_at', todayStart.toISOString());

    const sentSet = new Set((alreadySent || []).map((r: any) => r.user_id));
    const toNotify = resumeUsers.filter(u => !sentSet.has(u.userId));

    if (toNotify.length === 0) {
      return new Response(JSON.stringify({ message: 'No resume candidates' }));
    }

    // 4. Send
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    for (const u of toNotify) {
      const surahName = SURAH_NAMES[u.surah] || `Surah ${u.surah}`;
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'resume_reading',
        u.locale,
        { surahName, ayah: u.ayah },
        {
          title: 'Continue where you left off',
          body: `You were reading ${surahName}, Ayah ${u.ayah}. Pick up where you stopped.`,
          route: 'quran',
        },
      );

      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: u.token,
              notification: {
                title: variant.title,
                body: variant.body,
                ...(variant.imageUrl ? { image: variant.imageUrl } : {}),
              },
              data: { route: variant.route ?? '', nid },
              android: {
                priority: 'high',
                notification: {
                  sound: 'default',
                  ...(variant.imageUrl ? { image: variant.imageUrl } : {}),
                },
              },
              apns: {
                payload: { aps: { sound: 'default', 'mutable-content': 1 } },
                ...(variant.imageUrl ? { fcm_options: { image: variant.imageUrl } } : {}),
              },
            },
          }),
        }
      );

      if (res.ok) {
        sent++;
        await supabase.from('notification_log').insert({
          user_id: u.userId,
          notification_type: 'resume_reading',
          notification_id: nid,
          title: variant.title,
          body: variant.body,
          route: variant.route,
          variant_id: variant.id || null,
          sent_at: now.toISOString(),
        }).catch(() => {});
      }
    }

    return new Response(JSON.stringify({ success: true, sent }));
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});

async function getAccessToken(): Promise<string> {
  const { clientEmail, privateKey } = getFcmCreds();
  const key = await importPKCS8(privateKey, 'RS256');
  const jwt = await new SignJWT({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
  }).setProtectedHeader({ alg: 'RS256', typ: 'JWT' }).setIssuedAt().setExpirationTime('1h').sign(key);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error_description || data.error);
  return data.access_token;
}
