import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/xp_service.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kBg    = Color(0xFFF7F3EE);
const _kText  = Color(0xFF1C1C1E);
const _kSub   = Color(0xFF8E8E93);
const _kPink  = Color(0xFFFF6B9D);
const _kPinkL = Color(0xFFF9D5D8);
const _kWhite = Colors.white;

// ── Azkar model ──────────────────────────────────────────────────────────────
class _Azkar {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int    recommendedCount;
  final String category;
  final String reward;

  const _Azkar({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.recommendedCount,
    required this.category,
    required this.reward,
  });

  factory _Azkar.fromJson(Map<String, dynamic> j) => _Azkar(
    id:               j['id'] as String,
    arabic:           j['arabic'] as String,
    transliteration:  j['transliteration'] as String,
    translation:      j['translation'] as String,
    recommendedCount: j['recommended_count'] as int,
    category:         j['category'] as String,
    reward:           j['reward'] as String,
  );
}

// ── Category config ───────────────────────────────────────────────────────────
const _categories = [
  (id: 'all',         label: 'All',         icon: Icons.apps_rounded),
  (id: 'general',     label: 'General',     icon: Icons.auto_awesome_rounded),
  (id: 'morning',     label: 'Morning',     icon: Icons.wb_sunny_rounded),
  (id: 'evening',     label: 'Evening',     icon: Icons.nights_stay_rounded),
  (id: 'post_prayer', label: 'Post-Prayer', icon: Icons.mosque_rounded),
  (id: 'sleeping',    label: 'Sleep',       icon: Icons.bedtime_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});
  @override State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  List<_Azkar> _allAzkar = [];
  List<_Azkar> _filtered = [];
  String       _selectedCat = 'all';
  int          _dhikrIdx   = 0;
  int          _count       = 0;
  int          _pointsToday = 0;
  int          _setsCompleted = 0; // total sets done this session
  bool         _saving      = false;
  bool         _rewardExpanded = false;
  bool         _loading     = true;

  late AnimationController _tapCtrl;
  late Animation<double>   _tapScale;

  final _supabase = Supabase.instance.client;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tapCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _tapScale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
    _loadAzkar();
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  // ── Load JSON ─────────────────────────────────────────────────────────────
  Future<void> _loadAzkar() async {
    final raw  = await rootBundle.loadString('assets/data/azkar.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => _Azkar.fromJson(e as Map<String, dynamic>))
        .toList();
    setState(() {
      _allAzkar = list;
      _applyFilter();
      _loading  = false;
    });
  }

  void _applyFilter() {
    _filtered = _selectedCat == 'all'
        ? List.from(_allAzkar)
        : _allAzkar.where((a) => a.category == _selectedCat).toList();
    _dhikrIdx = 0;
    _count    = 0;
    _rewardExpanded = false;
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  _Azkar get _current => _filtered[_dhikrIdx];

  void _tap() {
    HapticFeedback.lightImpact();
    _tapCtrl.forward().then((_) => _tapCtrl.reverse());
    setState(() => _count++);
    if (_count == _current.recommendedCount) {
      Future.delayed(const Duration(milliseconds: 200), _showCompleteDialog);
    }
  }

  Future<void> _completeDhikr() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Legacy Noor points RPC (keep existing points system intact)
      await _supabase.rpc('earn_dhikr_points',
          params: {'p_type': _current.transliteration, 'p_count': _count});
      // Award weighted XP based on which dhikr was completed
      await XpService.instance.earnDhikrXp(_current.id);
      // Award first_dhikr badge on the very first set ever
      if (_setsCompleted == 0) {
        await XpService.instance.awardBadge('first_dhikr');
      }
      // 7 sets in one session → night_warrior badge
      if (_setsCompleted + 1 >= 7) {
        await XpService.instance.awardBadge('night_warrior');
      }
      setState(() {
        _pointsToday   += 20;
        _setsCompleted += 1;
        _count          = 0;
      });
    } catch (_) {} finally {
      setState(() => _saving = false);
    }
  }

  void _showCompleteDialog() {
    final xpEarned = XpReward.dhikrXp(_current.id);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Masha\'Allah!',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: _kText)),
            const SizedBox(height: 8),
            Text('${_current.recommendedCount} counts complete • +20 Noor Points • +$xpEarned XP',
                style: GoogleFonts.outfit(fontSize: 14, color: _kSub),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(context); _completeDhikr(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Claim +20 Points & +$xpEarned XP',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _kWhite)),
            )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () { Navigator.pop(context); setState(() => _count = 0); },
              child: Text('Continue', style: GoogleFonts.outfit(color: _kSub)),
            ),
          ]),
        ),
      ),
    );
  }

  void _switchDhikr(int delta) {
    setState(() {
      _dhikrIdx = (_dhikrIdx + delta + _filtered.length) % _filtered.length;
      _count = 0;
      _rewardExpanded = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _kBg,
        body: const Center(child: CircularProgressIndicator(color: _kPink)),
      );
    }

    final azkar = _current;
    final target = azkar.recommendedCount;
    final pct    = (_count / target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kWhite,
        surfaceTintColor: _kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kText, size: 20),
          onPressed: () => Navigator.pop(context, _pointsToday),
        ),
        title: Text('Count Dhikr',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        centerTitle: true,
      ),
      body: SafeArea(child: Column(children: [

        // ── Points banner ───────────────────────────────────────────────────
        if (_pointsToday > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: _kPinkL, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('🌟', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('+$_pointsToday points earned today!',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _kPink)),
            ]),
          ),

        // ── Category tabs ───────────────────────────────────────────────────
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = cat.id == _selectedCat;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCat = cat.id;
                  _applyFilter();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? _kPink : _kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _kPink : Colors.grey.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cat.icon, size: 13,
                        color: sel ? _kWhite : _kSub),
                    const SizedBox(width: 5),
                    Text(cat.label,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: sel ? _kWhite : _kSub)),
                  ]),
                ),
              );
            },
          ),
        ),

        // ── Scrollable body ─────────────────────────────────────────────────
        Expanded(child: Builder(builder: (ctx) {
          final bottom = MediaQuery.of(ctx).padding.bottom;
          return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
          child: Column(children: [

            // Dhikr navigation row
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _NavBtn(icon: Icons.chevron_left_rounded, onTap: () => _switchDhikr(-1)),
              Text('${_dhikrIdx + 1} / ${_filtered.length}',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSub, fontWeight: FontWeight.w600)),
              _NavBtn(icon: Icons.chevron_right_rounded, onTap: () => _switchDhikr(1)),
            ]),

            const SizedBox(height: 20),

            // Main dhikr card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                // Arabic
                Text(azkar.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                        fontSize: 36, fontWeight: FontWeight.w700, color: _kText, height: 1.7)),
                const SizedBox(height: 10),

                // Transliteration
                Text(azkar.transliteration,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: _kPink, fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),

                // Translation
                Text(azkar.translation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 13, color: _kSub)),

                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Reward expandable
                GestureDetector(
                  onTap: () => setState(() => _rewardExpanded = !_rewardExpanded),
                  child: Row(children: [
                    const Text('📖', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Hadith / Reward',
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _kText))),
                    Icon(
                      _rewardExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _kSub, size: 20),
                  ]),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _rewardExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kPinkL,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(azkar.reward,
                          style: GoogleFonts.outfit(
                              fontSize: 12.5, color: _kText, height: 1.65)),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Count + progress
            Text('$_count',
                style: GoogleFonts.outfit(
                    fontSize: 100, fontWeight: FontWeight.w700,
                    color: _kPink, height: 1.0)),
            Text('/ $target target',
                style: GoogleFonts.outfit(
                    fontSize: 15, color: _kSub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct, minHeight: 8,
                backgroundColor: _kPinkL,
                valueColor: const AlwaysStoppedAnimation(_kPink),
              ),
            ),

            const SizedBox(height: 36),

            // TAP button (original + preserved)
            GestureDetector(
              onTap: _tap,
              child: AnimatedBuilder(
                animation: _tapScale,
                builder: (_, child) => Transform.scale(scale: _tapScale.value, child: child),
                child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF9671)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(
                        color: _kPink.withValues(alpha: 0.40),
                        blurRadius: 32, spreadRadius: 4)],
                  ),
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('TAP',
                        style: GoogleFonts.outfit(
                            fontSize: 24, fontWeight: FontWeight.w800, color: _kWhite)),
                    Text(azkar.transliteration,
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                  ])),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Controls row
            Row(children: [
              _ControlBtn(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                onTap: () => setState(() { _count = 0; _rewardExpanded = false; }),
                color: _kSub,
              ),
              const SizedBox(width: 12),
              _ControlBtn(
                label: _saving ? '...' : 'Complete ✓',
                icon: Icons.check_circle_rounded,
                onTap: _count >= target ? _completeDhikr : null,
                color: _count >= target ? const Color(0xFF2BAE99) : _kSub,
              ),
            ]),

          ]),
        );  // end SingleChildScrollView
        })),  // end Builder
      ])),
    );
  }
}

// ── Nav arrow button ──────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 22, color: _kSub),
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _ControlBtn({required this.label, required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    ));
  }
}
