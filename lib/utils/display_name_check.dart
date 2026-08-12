// Client-side mirror of the server trigger (public._check_display_name) so
// users get instant feedback before hitting Save. Server enforcement is the
// source of truth — if this list drifts, the server still catches it.
class DisplayNameCheck {
  // Match the DB word list in
  // supabase/migrations/20260812_010_block_and_tighten_reports.sql
  // (the expanded profanity trigger). Order doesn't matter but every entry
  // the trigger checks must be here too.
  static const _banned = <String>[
    // English
    'fuck','shit','bitch','cunt','dick','pussy','whore','slut','asshole',
    'nigger','nigga','faggot','fag','retard','kike','chink','spic',
    'porn','sex','xxx','nsfw','hitler','nazi','isis','daesh',
    // Arabic transliterations
    'kafir','murtad','zani','zaniya','sharmuta','ayr','kus','zeb',
    // Urdu / Hindi
    'chutiya','madarchod','behenchod','randi','gandu','harami',
    // Turkish
    'orospu','piç','amina','sikeyim','sikerim',
    // Indonesian / Malay
    'anjing','babi','memek','kontol','bangsat','pukimak','sundal',
    // French
    'putain','salope','encule','connard','pute','merde',
    // Russian (transliterated)
    'suka','blyad','pizda','huy','yobana',
    // Sacred names & titles — impersonation is the real risk on an Islamic
    // leaderboard. Users with legitimate similar names can add a distinguisher.
    'allah','muhammad','rasulullah','prophet','nabi','muhammadsaw',
    'jesus','isa','moses','musa','abraham','ibrahim',
    'quran','koran','islam',
    'admin','sabiq','sabiqteam','support','moderator','staff',
  ];

  /// Returns null if OK, or a reason string if blocked.
  static String? validate(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final lowered = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final w in _banned) {
      if (lowered.contains(w)) return 'blocked';
    }
    return null;
  }
}
