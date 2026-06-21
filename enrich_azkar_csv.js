// Enriches azkar_export.csv with an "Illustration" column.
// Reads:  azkar_export.csv  (5 cols: Category, Zikar Name, Arabic, Translation, Benefit)
// Writes: azkar_full.csv    (6 cols: + Illustration; UTF-8 BOM for Excel)

const fs = require('fs');
const path = require('path');

const INPUT       = path.join(__dirname, 'azkar_export.csv');
const OUTPUT      = path.join(__dirname, 'azkar_full.csv');         // UTF-8 BOM, comma-separated
const OUTPUT_XLSX = path.join(__dirname, 'azkar_full_excel.csv');   // UTF-16 LE BOM, tab-separated (opens cleanly in Excel)

// Minimal RFC4180 CSV parser (handles quoted fields with commas + escaped quotes + newlines inside quotes).
function parseCsv(text) {
  const rows = [];
  let row = [], cur = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) {
      if (c === '"') {
        if (text[i + 1] === '"') { cur += '"'; i++; } else { inQ = false; }
      } else cur += c;
    } else {
      if (c === '"') inQ = true;
      else if (c === ',') { row.push(cur); cur = ''; }
      else if (c === '\n') { row.push(cur); rows.push(row); row = []; cur = ''; }
      else if (c === '\r') { /* skip */ }
      else cur += c;
    }
  }
  if (cur.length || row.length) { row.push(cur); rows.push(row); }
  return rows.filter(r => r.length > 1 || (r[0] && r[0].trim()));
}

function csvEscape(s) {
  if (s == null) return '';
  const str = String(s);
  return /[",\n\r]/.test(str) ? `"${str.replace(/"/g, '""')}"` : str;
}

// --- Illustration rules ----------------------------------------------------
// Order matters: first match wins. Each rule = { test(haystack, name, cat), text }
// "haystack" = lower-case (name + translation + benefit).

const rules = [
  // ─── Specific famous azkar ────────────────────────────────────────────
  { test: (h, n) => /ayat[- ]?ul[- ]?kursi|ayatul kursi|ayat al[- ]?kursi/i.test(n + h),
    text: 'Glowing celestial throne extending across the heavens and earth, with a soft golden dome of protection forming over a kneeling worshipper.' },

  { test: (h, n) => /sayyid al-?istighfar|sayyidul[- ]?istighfar|master of all prayers for forgiveness/i.test(n + h),
    text: 'Two tall gates of Paradise swinging slowly open, warm golden light pouring through onto a kneeling figure with head bowed.' },

  { test: (h, n) => /al[- ]?ikhlas|ikhlas \(3x\)|surah al-?ikhlas|qul huwa allahu ahad/i.test(n + h),
    text: 'Open Quran turned to Surah Al-Ikhlas, calligraphy glowing, a single soft ray of light rising from the page.' },

  { test: (h, n) => /al[- ]?falaq|surah al-?falaq|lord of daybreak|lord of the daybreak/i.test(n + h),
    text: 'Open Quran on Surah Al-Falaq, dawn breaking on the horizon, a dark knot of evil dissolving into the morning light.' },

  { test: (h, n) => /an[- ]?nas|surah an-?nas|retreating whisperer|whispers in the breasts/i.test(n + h),
    text: 'Open Quran on Surah An-Nas, a whispering shadow retreating from a softly glowing heart-silhouette.' },

  { test: (h, n) => /al[- ]?mulk|surah al-?mulk|tabarak alladhi/i.test(n + h),
    text: 'Open Quran on Surah Al-Mulk under a starry night sky, a soft shield of light enveloping a sleeping form.' },

  { test: (h, n) => /as[- ]?sajda|surah as-?sajdah|tanzeel as-?sajdah/i.test(n + h),
    text: 'Open Quran turned to Surah As-Sajdah under a starry sky, a kneeling silhouette in prostration beside a soft moonlit window.' },

  { test: (h, n) => /al[- ]?kafirun|kafirun|disbelievers, i do not worship/i.test(n + h),
    text: 'Open Quran on Surah Al-Kafirun, a clear straight path of light forking cleanly away from a crumbling pile of idols.' },

  { test: (h, n) => /al[- ]?fatih?ah|al fateha|al[- ]?fatiha/i.test(n + h),
    text: 'Open Quran turned to Surah Al-Fatihah, gentle light radiating outward from the calligraphy onto open palms.' },

  { test: (h, n) => /alif laam meem|alif lam mim|al-?baqarah \(?2:?1/i.test(n + h),
    text: 'Open Quran with the opening of Surah Al-Baqarah glowing, soft path of guidance light leading into the page.' },

  { test: (h, n) => /al-?baqarah 28[56]|burden a soul|messenger has believed/i.test(n + h),
    text: 'Cupped hands holding a soft, weighted light of guidance, an unburdened figure standing upright beside.' },

  // Yunus dua — la ilaha illa anta subhanaka (specific phrasing)
  { test: (h, n) => /dhun[- ]?nun|yunus|i have been of the wrongdoers|i have indeed been among the wrongdoers/i.test(n + h),
    text: 'A small lone figure within softly-lit deep blue water, a single ray of mercy piercing the dark from above.' },

  // ─── Salawat / Durood ────────────────────────────────────────────────
  { test: (h, n, c) => /durood|salawat|sallallahu|prayers upon muhammad|blessings upon|prayer upon the prophet|honour and have mercy upon muhammad|send blessings upon muhammad|peace and blessings/i.test(n + h) || /salawat/i.test(c),
    text: 'Pink and white rose petals drifting upward toward elegant calligraphy of the Prophet’s name, soft gold halo around it.' },

  // ─── Tahajjud / Witr / Qunut ────────────────────────────────────────
  { test: (h, n) => /tahajjud|night prayer|nur al-?samawat|light of the heavens|begin tahajjud/i.test(n + h),
    text: 'Silhouette in sajdah on a prayer mat lit by a single moonbeam through an arched window, stars overhead.' },

  { test: (h, n) => /qunut|witr|malik al-?quddus|sovereign, the most holy|guide me among those you have guided/i.test(n + h),
    text: 'Standing figure in prayer with hands raised, a single luminous drop of mercy reflecting moonlight beside them.' },

  // ─── Hajj / Umrah ──────────────────────────────────────────────────
  { test: (h, n) => /labbayk|talbiyah|here i am, o allah/i.test(n + h),
    text: 'Distant view of the Kaaba in soft golden light, a wide circle of pilgrims raising their voices, hands lifted in declaration.' },

  { test: (h, n) => /black stone|hajar al-?aswad|while facing.*black stone|yemeni corner/i.test(n + h),
    text: 'Close view of the Kaaba’s corner with hands gently raised in greeting toward the Black Stone, soft starlight overhead.' },

  { test: (h, n) => /safa|marwa|between the two hills|safā and marwah/i.test(n + h),
    text: 'A figure walking briskly between two soft golden hills under a clear sky, the Kaaba glowing in the distance.' },

  { test: (h, n) => /arafah|day of arafah|standing.*arafat/i.test(n + h),
    text: 'A wide plain of pilgrims under a vast amber sunset sky, hands raised in supplication toward the horizon at Arafat.' },

  { test: (h, n) => /jamrah|jamarat|stoning|seven pebbles/i.test(n + h),
    text: 'A single pebble arcing through soft light toward the stoning pillar, a calm pilgrim silhouette in foreground.' },

  { test: (h, n) => /zamzam|drink.*zamzam/i.test(n + h),
    text: 'A cup of bright clear water held to the lips, soft droplets of light rising from the surface, the Kaaba glowing softly behind.' },

  { test: (h, n) => /tawaf|circuits|circumambulation/i.test(n + h),
    text: 'Concentric rings of pilgrims circling the Kaaba in soft golden light, a single figure with hand raised in greeting.' },

  { test: (h, n, c) => /hajj|umrah|maqam ibrahim|standing-?place of abraham|ihram/i.test(n + h) || /hajj|umrah/i.test(c),
    text: 'The Kaaba framed by a soft amber dawn sky, pilgrims in white circling quietly, hands raised in remembrance.' },

  // ─── Travel ────────────────────────────────────────────────────────
  { test: (h, n, c) => /travel|journey|mounting|vehicle|returning, repenting|ayibuna|completed a journey|set out on a journey/i.test(n + h) || /travel/i.test(c),
    text: 'Open desert road at sunrise, a traveller silhouette beside a vehicle, distant mountains and a rising sun on the horizon.' },

  // ─── Sleep ──────────────────────────────────────────────────────────
  { test: (h, n) => /blowing into the palms|blow over.*hands|cup his hands together and blow/i.test(n + h),
    text: 'Two cupped hands held together with a soft breath of light rising from them, a sleeping figure resting calmly nearby.' },

  { test: (h, n) => /shake out.*bed|wada‘?tu janbi|wadatu janbi|laid down my side/i.test(n + h),
    text: 'A hand gently smoothing the surface of a moonlit bed, a soft white blanket folded back to receive a sleeper.' },

  { test: (h, n) => /amutu wa ahya|bismika.*amutu|in your name.*i die and i live/i.test(n + h),
    text: 'Sleeping figure under a crescent moon on one side, the same figure rising in soft dawn light on the other side.' },

  { test: (h, n, c) => /sleep|bedtime|before sleeping|sleeping figure|when he lay down|when.*went to bed|nightmares?/i.test(h) || /^sleep$|duas before sleep/i.test(c),
    text: 'A sleeping figure beneath a soft blanket, a crescent moon and stars above, a gentle guardian-light hovering nearby.' },

  // ─── Post-prayer / Salah ───────────────────────────────────────────
  { test: (h, n, c) => /post-?prayer|after every obligatory prayer|after every prayer|tasbihat after|at the end of every.*salat|finished his prayer/i.test(h) || /post-?prayer|duas after salah/i.test(c),
    text: 'Hands in seated tashahhud holding wooden prayer beads, soft golden glow rising from the fingertips.' },

  // ─── Istighfar / Repentance ───────────────────────────────────────
  { test: (h, n, c) => /astaghfirullah|seek forgiveness|seek your forgiveness|i seek allah’?s forgiveness|sayyid al-?istighfar|repent to him|repent to you|tawbah/i.test(n + h) || /istighfar/i.test(c),
    text: 'Hands cupped in repentance, soft drops of forgiving light falling from above onto the open palms.' },

  // ─── Waking up ────────────────────────────────────────────────────
  { test: (h, n, c) => /waking|woke up|wake up from sleep|gave us life after.*taken it|ahyana ba‘da|after sleep/i.test(h) || /waking up/i.test(c),
    text: 'A figure sitting upright on the edge of a bed at dawn, soft golden sunrise spilling through an open window onto the floor.' },

  // ─── Clothes ──────────────────────────────────────────────────────
  { test: (h, n, c) => /clothed me|garment|putting on a garment|clothed me with this/i.test(h) || /clothes/i.test(c),
    text: 'A neatly folded white garment resting on a warm wooden surface, soft light rising from its folds.' },

  // ─── Wudu ─────────────────────────────────────────────────────────
  { test: (h, n, c) => /wudu|ablution|after ablution|gates of paradise open for him|al-ghurr-ul-muhajjalun/i.test(h) || /^wudu$/i.test(c),
    text: 'Clear water flowing gently over open hands above a small brass basin, soft droplets catching the light.' },

  // ─── Food & Drink ─────────────────────────────────────────────────
  { test: (h, n, c) => /eating|eat food|when you eat|fed us|after eating|after meals|drink|sneez/i.test(h) && /^food|sneez|sneezing/i.test(c + n)
       || /food & drink/i.test(c),
    text: 'A simple wooden table with bread, dates, and a cup of water, hands gently raised in gratitude above the meal.' },

  // ─── Sneezing dua (special) ──────────────────────────────────────
  { test: (h, n) => /sneez|yarhamukallah|may allah have mercy on you|guide you and rectify/i.test(n + h),
    text: 'A person covering the nose with cloth, gentle dust particles drifting into a single warm sunbeam.' },

  // ─── Anger dua ──────────────────────────────────────────────────
  { test: (h, n) => /angry|anger|refuge in allah from .*shay.*anger will leave/i.test(n + h),
    text: 'A seated figure with eyes closed, a dark cloud of anger lifting away from the head into the wind.' },

  // ─── Mirror dua ─────────────────────────────────────────────────
  { test: (h, n) => /mirror|made my (?:physical )?form beautiful|hassanta khalqi/i.test(n + h),
    text: 'A person standing before a softly glowing mirror, reflection gently radiant, hands lifted in quiet supplication.' },

  // ─── Home / Entering & Leaving ──────────────────────────────────
  { test: (h, n, c) => /entering (?:the )?house|enter(?:ing)? home|leaving home|leaving the home|best entrance|when leaving home|when entering home|in the name of allah we enter|when you enter your home/i.test(h) || /^home$/i.test(c),
    text: 'Warm doorway of a home at dusk, a figure stepping over the threshold with hand softly raised in remembrance.' },

  // ─── Istikharah ───────────────────────────────────────────────
  { test: (h, n, c) => /istikhara|astakhiruka|guidance.*decision|two rak.*ahs.*decision/i.test(h) || /istikharah/i.test(c),
    text: 'A figure standing at a quiet crossroads under a starry sky, a single bright guiding star directly above the path ahead.' },

  // ─── Adhan / Masjid ──────────────────────────────────────────
  { test: (h, n) => /entering the mosque|leaving the mosque|gates of your mercy|al-wasilah/i.test(n + h),
    text: 'A warm wooden mosque doorway opening onto a soft inner light, a figure stepping over the threshold with hands raised.' },

  { test: (h, n, c) => /adhan|adaan|mu.?adhin|after the adhan|hayya ‘alas-?salah|hayya ‘alal-?falah/i.test(h) || /adaan|adhan/i.test(c),
    text: 'A minaret silhouette against a pale dawn sky, soft circular waves of sound radiating outward over a sleeping city.' },

  // ─── Difficulty / Distress / Calamity / Happiness ───────────
  { test: (h, n) => /inna lillahi wa inna ilayhi raji‘un|inna lillahi wa inna ilayhi rajiun|calamity|in times of calamity|upon the death of someone/i.test(n + h),
    text: 'A small figure looking upward at a soft beam of mercy from above, gentle blossoms drifting down around them.' },

  { test: (h, n) => /hasbunallahu wa ni‘?mal wakil|hasbunallah|sufficient for us|thrown in the fire/i.test(n + h),
    text: 'A small figure standing calmly inside soft flames that have turned to gentle gardens of light around them.' },

  { test: (h, n, c) => /difficulty|distress|in distress|hardship|removes distress|fearful|worry/i.test(h) || /difficulty/i.test(c),
    text: 'A figure with head softly bowed beneath a heavy cloud, a single beam of light breaking through and reaching their shoulders.' },

  // ─── Protection of Iman / Heart guidance ────────────────────
  { test: (h, n, c) => /waswas|whisper|doubts in the heart|protection of iman|firm.*heart upon.*religion|alter.*the hearts|altereth.*hearts|muqallib al-?qulub/i.test(h) || /protection of iman/i.test(c),
    text: 'A small glowing heart shielded by a translucent dome of light, dark whispering wisps held back at its surface.' },

  // ─── Marketplace ────────────────────────────────────────────
  { test: (h, n, c) => /marketplace|market|entering the marketplace|sūq|suq/i.test(h) || /money|shoping|shopping/i.test(c),
    text: 'A soft silhouette stepping into a covered bazaar at dawn, lanterns glowing above stalls, hands raised in quiet remembrance.' },

  // ─── Marriage & Children ───────────────────────────────────
  { test: (h, n, c) => /marriage|spouse|spouses|newlywed|congratulation|unite our hearts|harmony in family/i.test(h) || /marriage|childern|children/i.test(c),
    text: 'Two silhouettes side by side beneath a soft canopy of light, small star-blossoms drifting gently down between them.' },

  { test: (h, n) => /righteous offspring|grant me.*offspring|bless me.*children|joy of (?:our|my) hearts|qurrata a‘?yun|joy of our eyes/i.test(n + h),
    text: 'A pair of cupped hands holding two small luminous seedlings, a gentle ray of light nurturing them from above.' },

  // ─── Social interactions / greetings / gatherings ──────────
  { test: (h, n) => /salaam|salam|peace be upon you|spreading salaam/i.test(n + h),
    text: 'Two figures meeting on a soft path, hands placed gently over their hearts, a warm halo of greeting between them.' },

  { test: (h, n, c) => /gathering|expiation of the gathering|kaffarat al-majlis|at the end of every sitting|sealed the session/i.test(h) || /gatherings/i.test(c),
    text: 'A small circle of seated silhouettes beneath soft hanging lanterns, a gentle gold light closing softly over the group.' },

  // ─── Nature ────────────────────────────────────────────────
  { test: (h, n) => /rain|beneficial rain|expose himself to rain/i.test(n + h),
    text: 'Soft falling rain over green earth at dawn, two open hands raised to receive the drops, faint sunlight breaking through the clouds.' },

  { test: (h, n) => /thunder|thunder is heard|glory be to him whom the thunder/i.test(n + h),
    text: 'A wide night sky with a single quiet flash of light over distant mountains, soft cloud forms hushed in glorification.' },

  // ─── Death / Janazah / Graves ─────────────────────────────
  { test: (h, n, c) => /janazah|funeral prayer|deceased|the dead|grave|graveyard|visiting the graves|punishment.*grave|torment.*grave/i.test(h) || /^death$/i.test(c),
    text: 'A simple white-shrouded form at peace under a soft starlit sky, a gentle column of mercy-light descending from above.' },

  // ─── Forty Rabbana — calligraphy-led ──────────────────────
  { test: (h, n, c) => /rabbana|our lord/i.test(h) && /40 rabbana|rabbana duas/i.test(c),
    text: 'Calligraphic word “Rabbana” glowing softly in the centre of an open page, light streaming outward like gentle rays.' },

  // ─── Quranic / Prophetic Supplications (Quran-led pages) ──
  { test: (h, n, c) => /quranic supplications?|prophet.*yunus|prophet.*musa|prophet.*ibrahim|prophet.*nuh|prophet.*adam/i.test(h + c),
    text: 'An open Quran on a wooden rehl with a soft gold ray rising from the page, hands gently cupped to receive it.' },

  // ─── Ruqya ─────────────────────────────────────────────
  { test: (h, n, c) => /ruqya|ruquiya|black magic|sihr|guard.*against.*magic|protect.*children.*harm|healing and protection|shield yourself from all evil/i.test(h) || /ruqya/i.test(c),
    text: 'Two open palms gently raised above a softly glowing chest, soft blue healing light flowing from the hands into the heart.' },

  // ─── Sick / Illness ──────────────────────────────────
  { test: (h, n) => /sick|illness|cure.*illness|good health.*protection|visiting.*sick|grant me well-?being in my (?:body|hearing|sight)/i.test(n + h),
    text: 'A hand gently resting over a softly-lit chest, warm healing light radiating outward through the limbs.' },

  // ─── Toilet (entering / leaving) ─────────────────────
  { test: (h, n) => /toilet|lavatory|relieve oneself|when entering the toilet|when leaving the toilet|ghufranaka/i.test(n + h),
    text: 'A simple wooden door slightly ajar with a soft glow within, a single tasbih bead resting on the threshold beside it.' },

  // ─── Refuge from shirk ───────────────────────────────
  { test: (h, n) => /shirk|associating anything|associating partner.*allah|polytheism/i.test(n + h),
    text: 'Two raised hands rejecting tiny crumbling idols at their feet, a clean beam of light streaming down from above.' },

  // ─── Protection (la yadurru, kalimat tammat, refuge perfect words) ──
  { test: (h, n) => /la yadurru|nothing can harm|name nothing.*harm/i.test(n + h),
    text: 'A translucent dome of light surrounding a small figure, dark wisps deflecting harmlessly off its surface.' },

  { test: (h, n) => /perfect words of allah|kalimat.*tammat|complete word of allah|protection from all evil/i.test(n + h),
    text: 'A glowing circle of Arabic letters orbiting a kneeling figure, dark shadows held back at its edge.' },

  // ─── Dominion / kingdom ───────────────────────────
  { test: (h, n) => /dominion belongs to allah|kingdom belongs to allah|to allah belongs all|sovereignty belongs to allah|whole kingdom belongs/i.test(n + h),
    text: 'A glowing key of dominion suspended in a starlit sky above an open landscape of mountains, oceans, and earth.' },

  // ─── Fitrah ──────────────────────────────────────
  { test: (h, n) => /fitrah|natural religion/i.test(n + h),
    text: 'A small child-silhouette with a soft halo, surrounded by five gentle stars representing the pillars of Islam.' },

  // ─── By Your leave (bika) ────────────────────────
  { test: (h, n) => /by you we (?:live|die)|bika asbahna|bika amsayna|by your leave/i.test(n + h),
    text: 'Sunrise and sunset side by side on a continuous horizon, a soft path of light connecting the two.' },

  // ─── Pleased with Allah ──────────────────────────
  { test: (h, n) => /pleased with allah|raditu billahi/i.test(n + h),
    text: 'A smiling silhouette with arms gently open, soft starlight gathering quietly at the chest.' },

  // ─── Knower of unseen ────────────────────────────
  { test: (h, n) => /knower of the unseen|alimal-?ghayb|knower of (?:the )?hidden things/i.test(n + h),
    text: 'Open palms beneath a small luminous eye-of-knowledge in the sky, dark wisps retreating to the edges.' },

  // ─── Scales / outweigh dhikr ─────────────────────
  { test: (h, n) => /outweigh.*dhikr|numerous as.*created|weight of his throne|ink of his words|heavy on the scales|full is the scale/i.test(n + h),
    text: 'A golden scale tipped fully to one side beneath a swirling galaxy of countless tasbih beads.' },

  // ─── Unparalleled reward / breaking chains ──────
  { test: (h, n) => /unparalleled reward|reward of freeing|hundred good deeds|ten good deeds|protected from shaytan/i.test(n + h),
    text: 'Ten chains breaking and falling from a freed wrist, a white dove rising into warm dawn light.' },

  // ─── Praise befitting greatness ────────────────
  { test: (h, n) => /glory of your countenance|praise befitting|jalal.*wajh/i.test(n + h),
    text: 'A small figure looking upward at vast luminous Arabic calligraphy of Allah’s name filling the sky.' },

  // ─── Gratitude / shukr ────────────────────────
  { test: (h, n) => /gratitude|all the favours|fulfil obligation of gratitude|grateful for your favors|grateful of your providence|shukr/i.test(n + h),
    text: 'Hands cupped to receive rays of light from above, tiny green seedlings sprouting from the palms.' },

  // ─── Concealment / sitr ───────────────────────
  { test: (h, n) => /concealment|conceal my faults|cover up my defects|sitr/i.test(n + h),
    text: 'A soft veil of golden cloth draping gently over a kneeling figure from above.' },

  // ─── Freed from hellfire / bearing witness ─
  { test: (h, n) => /freed from the hellfire|bear witness|ushhiduka|i call upon you to bear witness/i.test(n + h),
    text: 'A figure with arms open, four angelic light-figures circling, a closing door of fire fading away below.' },

  // ─── Ya Hayyu Ya Qayyum ──────────────────────
  { test: (h, n) => /ya hayy?u ya qayyum|ever-?living.*sustainer|in your mercy.*relief|rectify all (?:of )?my affairs/i.test(n + h),
    text: 'A single steady candle flame held in cupped hands, the surrounding darkness softly receding.' },

  // ─── Well-being in both worlds ────────────────
  { test: (h, n) => /well-?being in both worlds|pardon and well-?being|world and the (?:next|hereafter)|al-?afiyah/i.test(n + h),
    text: 'A path of light bridging two soft horizons: a green earthly landscape on one side and a luminous Jannah glow on the other.' },

  // ─── Ummah / oppressed / steadfast ───────────
  { test: (h, n, c) => /ummah|oppressed|mustad'?afin|victory.*disbeliev|defeat.*disbeliev|patience.*plant.*feet/i.test(n + h) || /ummah/i.test(c),
    text: 'Hands cupped gently around a small green globe, a soft halo of light spreading over the Muslim lands.' },

  { test: (h, n) => /steadfast|deviate after.*guided|hearts (?:firm|deviate)/i.test(n + h),
    text: 'A small heart resting in open palms, golden roots reaching down into firm earth beneath it.' },

  // ─── Rabbana atina (single dua, not whole category) ─
  { test: (h, n) => /rabbana atina|good in this world and good in the hereafter|comprehensive du'?a/i.test(n + h),
    text: 'Two open hands cupping a small green Earth on one side and a luminous miniature Jannah orb on the other.' },

  // ─── Knowledge / beneficial knowledge ──────
  { test: (h, n) => /beneficial knowledge|increase me in knowledge|ilman nafi|rabbi zidni ilma/i.test(n + h),
    text: 'A glowing open book on a wooden lectern, soft pages of light lifting upward like rising knowledge.' },

  // ─── Parents ────────────────────────────────
  { test: (h, n) => /rabbir-?hamhuma|merciful to them as they raised me|dua for the parents|forgive me, my parents/i.test(n + h),
    text: 'A small silhouette holding two larger silhouettes’ hands beneath a soft halo of light, gentle blossoms around them.' },

  // ─── Greatest Name of Allah ────────────────
  { test: (h, n) => /greatest name of allah|al-?ahad.*as-?samad|samad.*who begets not/i.test(n + h),
    text: 'A vast night sky filled with soft golden calligraphy of Allah’s names, the central name glowing slightly brighter.' },

  // ─── Breaking fast ──────────────────────────
  { test: (h, n) => /breaking fast|thirst (?:has )?gone|wetness|reward is sure|iftar/i.test(n + h),
    text: 'A single cup of water and a date on a small wooden plate at sunset, soft orange light glowing across the surface.' },

  // ─── Protection from hellfire ───────────────
  { test: (h, n) => /save me from the fire|protect.*from.*hell|protection from hellfire|fear of hellfire/i.test(n + h),
    text: 'Cupped hands raised toward a soft pearl gate of Jannah above, a dim red glow of fire receding harmlessly below.' },

  // ─── Difficult affairs / ease ───────────────
  { test: (h, n) => /no ease|except in that which you have made easy|any difficult affairs|la sahla illa/i.test(n + h),
    text: 'A narrow rocky path widening gently into a smooth road of light beneath a soft dawn sky.' },

  // ─── Anxiety / sorrow / debt ────────────────
  { test: (h, n) => /worry and grief|anxiety|sorrow|laziness|incapacity|miserliness|heavily in debt|burden of indebtedness/i.test(n + h),
    text: 'Four heavy chains breaking off a wrist, the freed hand rising into warm dawn light above the broken links.' },

  // ─── Relations / intimacy with spouse ──────
  { test: (h, n) => /sexual intercourse|relation with wife|allahumma jannibna-?sh-?shaitan/i.test(n + h),
    text: 'A soft warm doorway of a home in twilight, two silhouettes paused before it with hands raised in gentle remembrance.' },

  // ─── Generic kalimah / tasbih fallbacks within General ──
  { test: (h, n) => /la ilaha illa allah|none has the right to be worshipped|no god but allah/i.test(n + h),
    text: 'Calligraphy of the Kalimah glowing in the sky, chains of slavery breaking and falling toward the earth below.' },

  { test: (h, n) => /la hawla wa la quwwata|no power.*strength|treasure.*paradise/i.test(n + h),
    text: 'A sealed golden treasure-chest of Paradise just beginning to open, a single key glowing with the words inscribed upon it.' },

  { test: (h, n) => /subhanallahi wa bihamdihi|glory be to allah and his is the praise/i.test(n + h),
    text: 'A vast ocean horizon at dawn, foam softly dissolving into the rising sunlight on the surface.' },

  { test: (h, n) => /subhanallah(?:i)? al-?'?azim|glory be to allah, the almighty/i.test(n + h),
    text: 'Two weightless feathers floating above a heavy golden scale tipped fully downward by their unseen weight.' },

  { test: (h, n) => /subhanallah|glory be to allah/i.test(n + h),
    text: 'Wooden tasbih beads glowing one after another as a hand counts, soft light rising with each bead.' },

  { test: (h, n) => /alhamdulillah|all praise is for allah|all praise is due to allah/i.test(n + h),
    text: 'A golden scale tipping fully to the side of good deeds, soft warm light radiating from the heavier pan.' },

  { test: (h, n) => /allahu akbar|allah is the greatest/i.test(n + h),
    text: 'A vast night sky above tiny mountains and a praying silhouette, the word Allahu Akbar glowing softly among the stars.' },

  // ─── Time-of-day fallbacks ─────────────────
  { test: (h, n, c) => /^morning$/i.test(c),
    text: 'Pale gold sunrise over a calm horizon, two hands gently raised in supplication toward the dawn light.' },

  { test: (h, n, c) => /^evening$/i.test(c),
    text: 'Soft purple and orange dusk over a mosque silhouette, hands raised in supplication beneath the twilight sky.' },

  { test: (h, n, c) => /morning & evening remembrance/i.test(c),
    text: 'A soft horizon glowing with both sunrise and dusk colours, two hands raised gently in supplication beneath the sky.' },

  // ─── Big remaining bucket categories ──────
  { test: (h, n, c) => /further supplications|closing remembrance|prophetic supplications|daily duas/i.test(c),
    text: 'A pair of open hands raised in quiet supplication beneath a soft halo of light, prayer beads resting nearby.' },
];

const FALLBACK = 'A pair of open hands raised in quiet supplication beneath a soft halo of light, prayer beads resting nearby.';

function pickIllustration(category, name, translation, benefit) {
  const hay = `${name} ${translation} ${benefit}`.toLowerCase();
  for (const r of rules) {
    try {
      if (r.test(hay, name, category)) return r.text;
    } catch (_) { /* ignore bad regex */ }
  }
  return FALLBACK;
}

// --- run -----------------------------------------------------------------
const text = fs.readFileSync(INPUT, 'utf8');
const rows = parseCsv(text);
if (rows.length === 0) { console.error('Empty input'); process.exit(1); }

const header = rows[0];
const idx = {
  cat:  header.indexOf('Category Name'),
  name: header.indexOf('Zikar Name'),
  ar:   header.indexOf('Arabic'),
  tr:   header.indexOf('Translation'),
  ben:  header.indexOf('Benefit Text'),
};
for (const k of Object.keys(idx)) {
  if (idx[k] === -1) { console.error('Missing column:', k); process.exit(1); }
}

const outRows = [['Category Name', 'Zikar Name', 'Arabic', 'Translation', 'Benefit Text', 'Illustration']];
for (let i = 1; i < rows.length; i++) {
  const r = rows[i];
  const cat  = r[idx.cat]  || '';
  const name = r[idx.name] || '';
  const ar   = r[idx.ar]   || '';
  const tr   = r[idx.tr]   || '';
  const ben  = r[idx.ben]  || '';
  const illus = pickIllustration(cat, name, tr, ben);
  outRows.push([cat, name, ar, tr, ben, illus]);
}

const BOM = '﻿';
const csv = BOM + outRows.map(row => row.map(csvEscape).join(',')).join('\r\n');
fs.writeFileSync(OUTPUT, csv, 'utf8');

// ---- Excel-friendly variant (UTF-16 LE BOM, TAB-separated) ---------------
// Excel on Windows auto-detects UTF-16 LE with BOM correctly even when it
// ignores the UTF-8 BOM. Tabs avoid the need to quote cells with commas.
// Excel-TSV escaping: cells with tab/CR/LF/quote → wrap in quotes, double inner quotes.
function tsvEscape(s) {
  if (s == null) return '';
  const str = String(s);
  return /["\t\r\n]/.test(str) ? `"${str.replace(/"/g, '""')}"` : str;
}
const tsvBody = outRows.map(row => row.map(tsvEscape).join('\t')).join('\r\n');
const tsvWithBom = '﻿' + tsvBody;
// Write as UTF-16 LE
const utf16Buf = Buffer.from(tsvWithBom, 'utf16le');
fs.writeFileSync(OUTPUT_XLSX, utf16Buf);

// Category breakdown so we can spot any miscounts
const counts = {};
for (let i = 1; i < outRows.length; i++) {
  const c = outRows[i][0];
  counts[c] = (counts[c] || 0) + 1;
}
console.log(`Wrote ${outRows.length - 1} rows -> ${OUTPUT}`);
console.log(`Wrote ${outRows.length - 1} rows -> ${OUTPUT_XLSX}   (use this in Excel)`);
console.log('Per-category counts:');
Object.keys(counts).sort().forEach(k => console.log(`  ${k.padEnd(35)} ${counts[k]}`));
