/// Lightweight model for a sponsored orphan. Mirrors the `sponsored_orphans`
/// table; fields are nullable where the Supabase schema allows NULL.
class Orphan {
  final String id;
  final String firstName;
  final String? lastInitial;
  final int age;
  final String? gender; // 'male' | 'female' | null
  final String? grade;
  final String? school;
  final String? city;
  final String? country;
  final String? fatherPassedCause;
  final String? motherStatus;
  final int siblingsCount;
  final String? story;
  // Per-locale translations of `story` (filled by auto-translate-orphan).
  // NULL for any locale = fall back to English `story` via [storyForLocale].
  final Map<String, String?> storyByLang;
  final String? photoUrl;
  final int targetSeeds;
  final int minSponsorship;
  final String? partnerOrg;
  final bool isActive;
  final int sortOrder;

  // Aggregate stats — populated separately via get_orphan_stats(_bulk).
  int currentSeeds;
  int sponsorCount;

  Orphan({
    required this.id,
    required this.firstName,
    required this.age,
    required this.targetSeeds,
    required this.minSponsorship,
    required this.isActive,
    required this.sortOrder,
    this.lastInitial,
    this.gender,
    this.grade,
    this.school,
    this.city,
    this.country,
    this.fatherPassedCause,
    this.motherStatus,
    this.siblingsCount = 0,
    this.story,
    this.storyByLang = const {},
    this.photoUrl,
    this.partnerOrg,
    this.currentSeeds = 0,
    this.sponsorCount = 0,
  });

  factory Orphan.fromMap(Map<String, dynamic> m) => Orphan(
        id: m['id'] as String,
        firstName: (m['first_name'] as String?) ?? '',
        lastInitial: m['last_initial'] as String?,
        age: (m['age'] as num?)?.toInt() ?? 0,
        gender: m['gender'] as String?,
        grade: m['grade'] as String?,
        school: m['school'] as String?,
        city: m['city'] as String?,
        country: m['country'] as String?,
        fatherPassedCause: m['father_passed_cause'] as String?,
        motherStatus: m['mother_status'] as String?,
        siblingsCount: (m['siblings_count'] as num?)?.toInt() ?? 0,
        story: m['story'] as String?,
        storyByLang: {
          'ar': m['story_ar'] as String?,
          'ur': m['story_ur'] as String?,
          'fr': m['story_fr'] as String?,
          'id': m['story_id'] as String?,
          'ms': m['story_ms'] as String?,
          'ru': m['story_ru'] as String?,
          'tr': m['story_tr'] as String?,
        },
        photoUrl: m['photo_url'] as String?,
        targetSeeds: (m['target_seeds'] as num?)?.toInt() ?? 1000,
        minSponsorship: (m['min_sponsorship'] as num?)?.toInt() ?? 50,
        partnerOrg: m['partner_org'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );

  /// "Amina K. · 9" (or "Amina · 9" when no last initial)
  String get displayName =>
      lastInitial != null && lastInitial!.isNotEmpty
          ? '$firstName $lastInitial.'
          : firstName;

  /// "Karachi, Pakistan" — null if neither field is set.
  String? get displayLocation {
    final parts = [city, country].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  double get progressRatio =>
      targetSeeds <= 0 ? 0 : (currentSeeds / targetSeeds).clamp(0.0, 1.0);

  /// Locale-aware story. Returns the translated `story_<lang>` when the
  /// active locale has a non-empty value, otherwise falls back to the
  /// canonical English `story`.
  String? storyForLocale(String lang) {
    final t = storyByLang[lang];
    if (t != null && t.trim().isNotEmpty) return t;
    return story;
  }
}
