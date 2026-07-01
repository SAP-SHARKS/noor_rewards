// lib/screens/dhikr_hub_screen.dart
//
// Dua & Azkar hub — Variant A "Editorial Cards" redesign.
//
// • Morning + Evening sit at the top as two painterly hero cards (no
//   imagery — sun/moon scenes are CustomPainted).
// • Every other category — both "essentials" and "others" — renders as a
//   simple white row: gold monoline icon chip · serif name · meta · chevron.
// • All previous business logic is preserved (visibility filter, session
//   accumulators, exit celebration, navigation to DhikrScreen).
//
// The icon set is a unified monoline gold language (Material outlined +
// the honey-deep accent), so categories no longer rely on per-tile images.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/app_config.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../theme/y4_theme.dart';
import '../widgets/dhikr_exit_celebration.dart';
import '../widgets/noor_offline.dart';
import 'akhirah_balance_screen.dart';
import 'dhikr_screen.dart';

AppConfig get _dhcfg => SettingsService.instance.config;
Color get _kBg => _dhcfg.dashBg;

// ── Editorial palette tokens (local) — sit alongside Y4 ────────────────────
const Color _kAccentGold = Y4.honeyDeep;
const Color _kIconChip = Color(0xFFFBF3DC); // soft butter chip for icons
const Color _kRowBorder = Color(0x0F785F28); // very faint warm hairline
const Color _kChevron = Color(0xFFCDBF9F);
const Color _kMetaInk = Y4.inkSoft;

// ─────────────────────────────────────────────────────────────────────────────
// Category metadata — id is the source of truth (used for navigation,
// localization, count lookup, hidden-flag filter). English `title` is kept
// as a fallback when a locale doesn't have a string for the id.
// ─────────────────────────────────────────────────────────────────────────────
class _Cat {
  final String id;
  final String title;
  const _Cat(this.id, this.title);
}

const List<_Cat> _kEssentials = [
  _Cat('ummah', 'Duas of Ummah'),
  _Cat('duas_before_sleep', 'Duas before Sleep'),
  _Cat('tahajjud', 'Tahajjud'),
  _Cat('duas_after_salah', 'Duas after Salah'),
  _Cat('salawat', 'Salawat'),
  _Cat('sunnah', 'Sunnah Duas'),
  _Cat('rabbana_40', '40 Rabbana Duas'),
  _Cat('istighfar', 'Istighfar'),
  _Cat('daily_duas', 'Daily Duas'),
  _Cat('ruquiya', 'Ruqya'),
  _Cat('general', 'Dhikar All Times'),
  _Cat('asmaul_husna', 'Names of Allah'),
  // ── Book of Complete Prayer — split into 6 standalone categories
  _Cat('quranic_duas', 'Quranic Supplications'),
  _Cat('prophetic_duas', 'Prophetic Supplications'),
  _Cat('morning_evening_remembrance', 'Morning & Evening Remembrance'),
  _Cat('further_duas', 'Further Supplications'),
  _Cat('closing_salawat', 'Closing Remembrance & Salawat'),
  _Cat('hajj_umrah', 'Hajj & Umrah Supplications'),
];

const List<_Cat> _kOthers = [
  _Cat('nightmares', 'Nightmares'),
  _Cat('waking_up', 'Waking up'),
  _Cat('clothes', 'Clothes'),
  _Cat('wudu', 'Wudu'),
  _Cat('food_drink', 'Food & Drink'),
  _Cat('home', 'Home'),
  _Cat('istikharah', 'Istikharah'),
  _Cat('masjid', 'Adaan & Masjid'),
  _Cat('difficulty', 'Diff & Happy'),
  _Cat('iman_protection', 'Iman Protect'),
  _Cat('travel', 'Travel'),
  _Cat('shopping', 'Shopping'),
  _Cat('family', 'Marriage'),
  _Cat('social', 'Social'),
  _Cat('nature', 'Nature'),
  _Cat('death', 'Death'),
  _Cat('gatherings', 'Gatherings'),
  _Cat('hajj', 'Hajj & Umrah'),
];

class DhikrHubScreen extends StatefulWidget {
  const DhikrHubScreen({super.key});
  @override
  State<DhikrHubScreen> createState() => _DhikrHubScreenState();
}

class _DhikrHubScreenState extends State<DhikrHubScreen> {
  Set<String>? _hiddenIds;
  // category_id → number of azkar items mapped to it (best-effort; empty on
  // failure, in which case the row meta just shows the time hint or nothing).
  Map<String, int> _counts = const {};

  // ── Session accumulators ───────────────────────────────────────────────
  int _sessionPoints = 0;
  int _sessionSets = 0;
  int _sessionSeconds = 0;
  bool _isExitingHub = false;

  @override
  void initState() {
    super.initState();
    _loadVisibility();
    _loadCounts();
  }

  Future<void> _openCategory(String id) async {
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id)),
    );
    if (result is Map) {
      _sessionPoints += (result['points'] as int?) ?? 0;
      _sessionSets += (result['sets'] as int?) ?? 0;
      _sessionSeconds += (result['seconds'] as int?) ?? 0;
    } else if (result is int) {
      _sessionPoints += result;
    }
  }

  // Daily dhikr-time persistence (unchanged behaviour from prior version).
  static const String _kDhikrSecondsPrefix = 'dhikr_seconds_';
  static String _todayKey() {
    final n = DateTime.now();
    return '$_kDhikrSecondsPrefix${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<int> _bumpAndReadTodaySeconds(int add) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _todayKey();
      final prev = prefs.getInt(key) ?? 0;
      final next = prev + add;
      await prefs.setInt(key, next);
      return next;
    } catch (_) {
      return add;
    }
  }

  // Fires the two-popup celebration if the user actually completed any zikr
  // during this hub session, then transitions to the Akhirah summary.
  Future<bool> _handleHubExit() async {
    if (_isExitingHub) return false;
    _isExitingHub = true;
    if (_sessionSets <= 0) {
      if (mounted) Navigator.of(context).pop(_sessionPoints);
      return false;
    }

    int streakDays = 0;
    try {
      final snap = await StreakService.instance.loadSnapshot().timeout(
            const Duration(seconds: 2),
          );
      streakDays = snap.dhikr;
    } catch (_) {}
    if (!mounted) return false;

    final todaySeconds = await _bumpAndReadTodaySeconds(_sessionSeconds);
    if (!mounted) return false;

    await showDhikrExitCelebration(
      context,
      pointsEarned: _sessionPoints,
      streakDays: streakDays,
    );
    if (!mounted) return false;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AkhirahBalanceScreen(
          sessionPoints: _sessionPoints,
          popResult: _sessionPoints,
          dhikrSecondsToday: todaySeconds,
        ),
      ),
      result: _sessionPoints,
    );
    return false;
  }

  // Translates a category by its stable id, with English fallback for
  // unmapped admin-added categories.
  String _localTitle(String fallback, String id) {
    final l = AppLocalizations.of(context);
    if (l == null) return fallback;
    switch (id) {
      case 'morning':
        return l.morning;
      case 'evening':
        return l.evening;
      case 'ummah':
        return l.duasOfUmmah;
      case 'duas_before_sleep':
        return l.duasBeforeSleep;
      case 'tahajjud':
        return l.tahajjud;
      case 'duas_after_salah':
        return l.duasAfterSalah;
      case 'salawat':
        return l.salawat;
      case 'sunnah':
        return l.sunnahDuas;
      case 'rabbana_40':
        return l.rabbana40Duas;
      case 'istighfar':
        return l.istighfar;
      case 'daily_duas':
        return l.dailyDuasCategory;
      case 'ruquiya':
        return l.ruquiyaCategory;
      case 'general':
        return l.dhikarAllTimes;
      case 'asmaul_husna':
        return l.namesOfAllah;
      case 'quranic_duas':
        return l.quranicDuas;
      case 'prophetic_duas':
        return l.propheticDuas;
      case 'morning_evening_remembrance':
        return l.morningEveningRemembrance;
      case 'further_duas':
        return l.furtherDuas;
      case 'closing_salawat':
        return l.closingSalawat;
      case 'hajj_umrah':
        return l.hajjAndUmrahCategory;
      case 'nightmares':
        return l.nightmares;
      case 'waking_up':
        return l.wakingUp;
      case 'clothes':
        return l.clothes;
      case 'wudu':
        return l.wudu;
      case 'food_drink':
        return l.foodAndDrink;
      case 'home':
        return l.home;
      case 'istikharah':
        return l.istikharah;
      case 'masjid':
        return l.adaanAndMasjid;
      case 'difficulty':
        return l.diffAndHappy;
      case 'iman_protection':
        return l.imanProtect;
      case 'travel':
        return l.travel;
      case 'shopping':
        return l.shopping;
      case 'family':
        return l.marriage;
      case 'social':
        return l.social;
      case 'nature':
        return l.nature;
      case 'death':
        return l.death;
      case 'gatherings':
        return l.gatherings;
      case 'hajj':
        return l.hajjAndUmrah;
      default:
        if (fallback == 'Morning') return l.morning;
        if (fallback == 'Evening') return l.evening;
        return fallback;
    }
  }

  Future<void> _loadVisibility() async {
    try {
      final res = await Supabase.instance.client
          .from('azkar_categories')
          .select('id, is_visible');
      if (!mounted) return;
      final hidden = <String>{};
      for (final r in (res as List)) {
        if (r['is_visible'] == false) hidden.add(r['id'] as String);
      }
      setState(() => _hiddenIds = hidden);
    } catch (_) {
      if (mounted) setState(() => _hiddenIds = <String>{});
    }
  }

  // Counts the items mapped to each category via the many-to-many tag table
  // (`azkar_item_categories`). Used only to populate the row meta line ("N
  // duas"); failure is silent so the redesign still renders without it.
  Future<void> _loadCounts() async {
    try {
      final rows = await Supabase.instance.client
          .from('azkar_item_categories')
          .select('category_id');
      if (!mounted) return;
      final map = <String, int>{};
      for (final r in (rows as List)) {
        final id = r['category_id'] as String?;
        if (id == null) continue;
        map[id] = (map[id] ?? 0) + 1;
      }
      setState(() => _counts = map);
    } catch (_) {
      // Leave _counts empty — meta line will simply omit the count.
    }
  }

  // Material outlined icons mapped to category ids, in the same monoline
  // style — the visual unification the mockup calls for.
  IconData _iconFor(String id) {
    switch (id) {
      case 'ummah':
        return Icons.public_outlined;
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'evening':
        return Icons.nights_stay_outlined;
      case 'duas_before_sleep':
        return Icons.bedtime_outlined;
      case 'tahajjud':
        return Icons.dark_mode_outlined;
      case 'duas_after_salah':
        return Icons.mosque_outlined;
      case 'salawat':
        return Icons.favorite_outline;
      case 'sunnah':
        return Icons.menu_book_outlined;
      case 'rabbana_40':
        return Icons.auto_stories_outlined;
      case 'istighfar':
        return Icons.spa_outlined;
      case 'daily_duas':
        return Icons.front_hand_outlined;
      case 'ruquiya':
        return Icons.shield_outlined;
      case 'general':
        return Icons.auto_awesome_outlined;
      case 'asmaul_husna':
        return Icons.format_quote_outlined;
      case 'book_of_prayer':
        return Icons.import_contacts_outlined;
      case 'nightmares':
        return Icons.thunderstorm_outlined;
      case 'waking_up':
        return Icons.wb_twilight_outlined;
      case 'clothes':
        return Icons.checkroom_outlined;
      case 'wudu':
        return Icons.water_drop_outlined;
      case 'food_drink':
        return Icons.restaurant_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'istikharah':
        return Icons.explore_outlined;
      case 'masjid':
        return Icons.campaign_outlined;
      case 'difficulty':
        return Icons.balance_outlined;
      case 'iman_protection':
        return Icons.security_outlined;
      case 'travel':
        return Icons.flight_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'family':
        return Icons.diversity_3_outlined;
      case 'social':
        return Icons.handshake_outlined;
      case 'nature':
        return Icons.eco_outlined;
      case 'death':
        return Icons.local_florist_outlined;
      case 'gatherings':
        return Icons.groups_outlined;
      case 'hajj':
        return Icons.brightness_5_outlined;
      default:
        return Icons.bookmark_outline;
    }
  }

  // "N duas" / "N adhkar" — kept short and faithful to the mockup. Returns
  // an empty string when we don't have a count, so callers can hide the
  // line cleanly. Localised via `unitDuas` / `unitAdhkar`.
  String _metaFor(String id) {
    final c = _counts[id];
    if (c == null || c <= 0) return '';
    final isAdhkar = id == 'morning' || id == 'evening' || id == 'general';
    final l = AppLocalizations.of(context);
    return isAdhkar
        ? (l?.unitAdhkar(c.toString()) ?? '$c adhkar')
        : (l?.unitDuas(c.toString()) ?? '$c duas');
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    if (_hiddenIds == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: const Center(child: NoorInlineLoader()),
      );
    }

    final hidden = _hiddenIds!;
    final morningVisible = !hidden.contains('morning');
    final eveningVisible = !hidden.contains('evening');
    final visibleEssentials =
        _kEssentials.where((c) => !hidden.contains(c.id)).toList();
    final visibleOthers =
        _kOthers.where((c) => !hidden.contains(c.id)).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleHubExit();
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Y4.bg,
          surfaceTintColor: Y4.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Y4.ink,
              size: 20,
            ),
            onPressed: _handleHubExit,
          ),
          title: Text(
            AppLocalizations.of(context)?.dhikarAndDua ?? 'Dhikr & Dua',
            style: Y4.display(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Y4.palette.ink,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow above the heroes
              const _Eyebrow(text: 'DAILY ESSENTIALS'),
              const SizedBox(height: 12),

              // ── Morning + Evening hero row ─────────────────────────────
              if (morningVisible || eveningVisible) ...[
                SizedBox(
                  height: 168,
                  child: Row(
                    children: [
                      if (morningVisible)
                        Expanded(
                          child: _EditorialHero(
                            title: _localTitle('Morning', 'morning'),
                            meta: _metaFor('morning'),
                            kind: _HeroKind.morning,
                            onTap: () => _openCategory('morning'),
                          ),
                        ),
                      if (morningVisible && eveningVisible)
                        const SizedBox(width: 12),
                      if (eveningVisible)
                        Expanded(
                          child: _EditorialHero(
                            title: _localTitle('Evening', 'evening'),
                            meta: _metaFor('evening'),
                            kind: _HeroKind.evening,
                            onTap: () => _openCategory('evening'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // ── More collections (the remaining essentials) ────────────
              if (visibleEssentials.isNotEmpty) ...[
                _SectionHeader(
                  first: AppLocalizations.of(context)?.moreCollections ??
                      'More Collections',
                  accent: '',
                ),
                const SizedBox(height: 12),
                for (final c in visibleEssentials)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _CategoryRow(
                      title: _localTitle(c.title, c.id),
                      meta: _metaFor(c.id),
                      icon: _iconFor(c.id),
                      onTap: () => _openCategory(c.id),
                    ),
                  ),
              ],

              // ── Other categories ────────────────────────────────────────
              if (visibleOthers.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionHeader(
                  first: AppLocalizations.of(context)?.otherCategories ??
                      'Other Categories',
                  accent: '',
                ),
                const SizedBox(height: 12),
                for (final c in visibleOthers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _CategoryRow(
                      title: _localTitle(c.title, c.id),
                      meta: _metaFor(c.id),
                      icon: _iconFor(c.id),
                      onTap: () => _openCategory(c.id),
                    ),
                  ),
              ],

              if (visibleEssentials.isEmpty &&
                  visibleOthers.isEmpty &&
                  !morningVisible &&
                  !eveningVisible)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    AppLocalizations.of(context)?.noCategoriesAvailable ??
                        'No categories available.',
                    style: GoogleFonts.outfit(
                      color: _kMetaInk,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small eyebrow label above the hero row.
// ─────────────────────────────────────────────────────────────────────────────
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow({required this.text});
  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kAccentGold,
        letterSpacing: 2.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header — "More collections" / "Other categories" with italic gold
// accent on the second word, matching the mockup exactly.
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String first;
  final String accent;
  const _SectionHeader({required this.first, required this.accent});
  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: first,
            style: Y4.display(
              fontSize: 21,
              fontWeight: FontWeight.w500,
              color: Y4.palette.ink,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          TextSpan(
            text: accent,
            style: Y4.display(
              fontSize: 21,
              fontWeight: FontWeight.w500,
              color: _kAccentGold,
              fontStyle: FontStyle.italic,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editorial hero card (Morning / Evening) — painterly background, name + meta
// anchored bottom-left, soft drop shadow.
// ─────────────────────────────────────────────────────────────────────────────
enum _HeroKind { morning, evening }

class _EditorialHero extends StatelessWidget {
  final String title;
  final String meta;
  final _HeroKind kind;
  final VoidCallback onTap;
  const _EditorialHero({
    required this.title,
    required this.meta,
    required this.kind,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    final isMorning = kind == _HeroKind.morning;
    final colors = isMorning
        ? const [Color(0xFFF4C84E), Color(0xFFE89B3C)]
        : const [Color(0xFF3A506B), Color(0xFF20304A)];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: const GradientRotation(2.79), // ≈ 160deg
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter:
                        isMorning ? _MorningScene() : _EveningScene(),
                  ),
                ),
                // Label block — anchored bottom-left
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Morning scene — soft white sun + two layered hill silhouettes.
class _MorningScene extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final sun = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(s.width - 38, 38), 22, sun);

    final hill1 = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.86)
        ..quadraticBezierTo(
            s.width * 0.25, s.height * 0.72, s.width * 0.5, s.height * 0.82)
        ..quadraticBezierTo(
            s.width * 0.75, s.height * 0.96, s.width, s.height * 0.80)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      hill1,
    );

    final hill2 = Paint()..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.94)
        ..quadraticBezierTo(
            s.width * 0.3, s.height * 0.84, s.width * 0.6, s.height * 0.92)
        ..quadraticBezierTo(
            s.width * 0.85, s.height * 0.96, s.width, s.height * 0.90)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      hill2,
    );
  }

  @override
  bool shouldRepaint(covariant _MorningScene old) => false;
}

// Evening scene — crescent moon (white circle masked by the bg colour),
// four pin-prick stars, and a single soft hill at the bottom.
class _EveningScene extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final moonCenter = Offset(s.width - 42, 40);
    final moonColor = Paint()..color = Colors.white.withValues(alpha: 0.88);
    final cutout = Paint()..color = const Color(0xFF2c3e57);
    canvas.drawCircle(moonCenter, 18, moonColor);
    canvas.drawCircle(moonCenter.translate(6, -4), 18, cutout);

    final star = Paint()..color = Colors.white.withValues(alpha: 0.70);
    canvas.drawCircle(Offset(s.width * 0.25, 32), 1.4, star);
    canvas.drawCircle(Offset(s.width * 0.45, 22), 1.1, star);
    canvas.drawCircle(Offset(s.width * 0.60, 44), 1.2, star);
    canvas.drawCircle(Offset(s.width * 0.15, 56), 1.0, star);

    final hill = Paint()..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.90)
        ..quadraticBezierTo(
            s.width * 0.3, s.height * 0.80, s.width * 0.6, s.height * 0.90)
        ..quadraticBezierTo(
            s.width * 0.85, s.height * 0.94, s.width, s.height * 0.88)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      hill,
    );
  }

  @override
  bool shouldRepaint(covariant _EveningScene old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category row — gold icon chip · serif name · meta · chevron. White card,
// soft shadow, hairline border.
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final String title;
  final String meta;
  final IconData icon;
  final VoidCallback onTap;
  const _CategoryRow({
    required this.title,
    required this.meta,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kRowBorder),
            boxShadow: [
              BoxShadow(
                color: Y4.palette.honeyDeep.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: -6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kIconChip,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _kAccentGold, size: 23),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Y4.palette.ink,
                          height: 1.15,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kMetaInk,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _kChevron, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
