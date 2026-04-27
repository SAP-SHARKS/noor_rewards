// lib/screens/project_detail_screen.dart
// LaunchGood-inspired campaign article view — v2

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/donation_service.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../theme/y4_theme.dart';
import '../widgets/project_media_carousel.dart';
import '../widgets/noor_offline.dart';

AppConfig get _pdcfg => SettingsService.instance.config;

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _PD {
  static Color get teal      => _pdcfg.dashTeal;
  static Color get tealDark  => HSLColor.fromColor(_pdcfg.dashTeal).withLightness(
      (HSLColor.fromColor(_pdcfg.dashTeal).lightness - 0.05).clamp(0.0, 1.0)).toColor();
  static const tealBg    = Color(0xFFE8F8F5);
  static const tealText  = Color(0xFF0D6E64);
  static const amber     = Color(0xFFEA9C24);
  static const amberBg   = Color(0xFFFFF3D4);
  static Color get text      => _pdcfg.dashText;
  static const sub       = Color(0xFF6B7280);
  static const bg        = Color(0xFFF8FAFB);
  static const border    = Color(0xFFEEEEF2);
  static const card      = Color(0xFFFFFFFF);
  static const danger    = Color(0xFFE53935);
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class ProjectUpdate {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  const ProjectUpdate({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> j) => ProjectUpdate(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    content: j['content'] as String? ?? '',
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final int availablePoints;
  final VoidCallback? onDonationSuccess;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.availablePoints,
    this.onDonationSuccess,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  List<ProjectMedia>  _media   = [];
  List<ProjectUpdate> _updates = [];
  bool _loading = true;
  late TabController _tabCtrl;
  int _availablePoints = 0;

  @override
  void initState() {
    super.initState();
    _availablePoints = widget.availablePoints;
    _tabCtrl = TabController(length: 2, vsync: this);
    // Rebuild when tab index changes
    _tabCtrl.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final id = widget.project['id'] as String?;
    if (id == null) { if (mounted) setState(() => _loading = false); return; }

    final results = await Future.wait([
      DonationService.instance.getProjectMedia(id),
      _loadUpdates(id),
    ]);
    if (!mounted) return;
    setState(() {
      _media   = results[0] as List<ProjectMedia>;
      _updates = results[1] as List<ProjectUpdate>;
      _loading = false;
    });
  }

  Future<List<ProjectUpdate>> _loadUpdates(String pid) async {
    try {
      final res = await Supabase.instance.client
          .from('community_project_updates')
          .select()
          .eq('project_id', pid)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => ProjectUpdate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) { return []; }
  }

  // ── Share helpers ─────────────────────────────────────────────────────────
  String get _shareText {
    final p = widget.project;
    final title   = p['title'] as String? ?? '';
    final sponsor = p['sponsor'] as String? ?? '';
    final current = (p['current_points'] as num?)?.toInt() ?? 0;
    final target  = (p['target_points']  as num?)?.toInt() ?? 1;
    final pct     = ((current / target) * 100).toStringAsFixed(0);
    return '🤲 Support "$title"\n\n'
        'Organised by $sponsor\n\n'
        '$pct% funded so far — every point counts!\n\n'
        'Open Noor Rewards app to donate your points and earn reward.\n'
        '#NoorRewards #Sadaqah #IslamicCharity';
  }

  Future<void> _shareGeneric() async {
    HapticFeedback.lightImpact();
    await SharePlus.instance.share(ShareParams(text: _shareText));
  }

  Future<void> _shareWhatsApp() async {
    HapticFeedback.mediumImpact();
    final encoded = Uri.encodeComponent(_shareText);
    // wa.me deep-link works on Android & iOS (opens WhatsApp directly)
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: generic share if WhatsApp not installed
      await SharePlus.instance.share(ShareParams(text: _shareText));
    }
  }

  // ── Share bottom sheet ────────────────────────────────────────────────────
  void _openShareSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Share Campaign',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _PD.text)),
          const SizedBox(height: 6),
          Text('Spread the word and help this cause reach its goal.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: _PD.sub)),
          const SizedBox(height: 24),

          // WhatsApp button
          _ShareBtn(
            icon: Icons.chat_rounded,
            label: 'Share via WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () { Navigator.pop(context); _shareWhatsApp(); },
          ),
          const SizedBox(height: 12),

          // Other apps
          _ShareBtn(
            icon: Icons.share_rounded,
            label: 'More sharing options…',
            color: _PD.teal,
            onTap: () { Navigator.pop(context); _shareGeneric(); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmtN(num n) =>
      n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M'
      : n >= 1000  ? '${(n / 1000).toStringAsFixed(1)}k'
      : '$n';

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int _daysLeft(String? endDate) {
    if (endDate == null) return -1;
    final d = DateTime.tryParse(endDate);
    if (d == null) return -1;
    return d.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p           = widget.project;
    final title       = p['title']        as String? ?? '';
    final story       = (p['story']       as String?)?.isNotEmpty == true
        ? p['story'] as String
        : (p['description'] as String? ?? '');
    final location    = p['location']     as String?;
    final category    = p['category']     as String?;
    final sponsor     = p['sponsor']      as String? ?? '';
    final impactQuote = p['impact_quote'] as String?;
    final endDate     = p['end_date']     as String?;
    final estUsd      = (p['estimated_usd'] as num?)?.toDouble() ?? 0;
    final current     = (p['current_points'] as num?)?.toInt() ?? 0;
    final target      = (p['target_points']  as num?)?.toInt() ?? 1;
    final pct         = (current / target).clamp(0.0, 1.0);
    final dpUrl       = p['dp_url']       as String?;
    final isCompleted = p['is_completed'] == true;
    final daysLeft    = _daysLeft(endDate);

    return Scaffold(
      backgroundColor: _PD.bg,
      body: Stack(children: [
        CustomScrollView(slivers: [

          // ── Hero ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: _PD.tealDark,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _loading
                  ? Container(color: _PD.tealDark,
                      child: const Center(child: NoorInlineLoader()))
                  : _media.isNotEmpty
                      ? ProjectMediaCarousel(media: _media, height: 300)
                      : dpUrl != null && dpUrl.isNotEmpty
                          ? Stack(fit: StackFit.expand, children: [
                              Image.network(dpUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _HeroPlaceholder()),
                              Container(decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xCC000000)],
                                  stops: [0.45, 1.0],
                                ),
                              )),
                            ])
                          : _HeroPlaceholder(),
            ),
            // Overlay buttons
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(children: [
                _CircleBtn(icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context)),
                const Spacer(),
                _CircleBtn(icon: Icons.share_rounded, onTap: _openShareSheet),
              ]),
            ),
            titleSpacing: 8,
          ),

          // ── Category + Title ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: _PD.card,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Badges row
                if ((category != null && category.isNotEmpty) ||
                    (location != null && location.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(spacing: 8, children: [
                      if (category != null && category.isNotEmpty)
                        _Pill(text: category, color: _PD.teal, textColor: Colors.white),
                      if (location != null && location.isNotEmpty)
                        _Pill(icon: Icons.location_on_rounded, text: location,
                            color: _PD.amberBg, textColor: _PD.amber),
                    ]),
                  ),

                Text(title,
                  style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: _PD.text, height: 1.25)),
                const SizedBox(height: 10),

                // Organizer
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                        color: _PD.tealBg, shape: BoxShape.circle),
                    child: Center(child: Icon(Icons.business_rounded,
                        color: _PD.teal, size: 16)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Organised by $sponsor',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: _PD.sub, fontWeight: FontWeight.w500))),
                  if (isCompleted)
                    _Pill(icon: Icons.check_circle_rounded, text: 'Completed',
                        color: _PD.tealBg, textColor: _PD.tealText),
                ]),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // ── Progress card ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: _PD.card,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_PD.teal, _PD.tealDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: _PD.teal.withValues(alpha: 0.30),
                    blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmtN(current),
                      style: GoogleFonts.outfit(
                          fontSize: 38, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('pts raised',
                        style: GoogleFonts.outfit(
                            fontSize: 14, color: Colors.white70)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10)),
                      child: Text('≈ \$${estUsd.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('of ${_fmtN(target)} pts goal',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatChip(
                        label: '${(pct * 100).toStringAsFixed(0)}%',
                        sub: 'funded'),
                    if (daysLeft >= 0) ...[
                      const SizedBox(width: 14),
                      _StatChip(
                          label: daysLeft == 0 ? 'Last day!' : '$daysLeft',
                          sub: daysLeft == 0 ? '' : 'days left'),
                    ],
                    if (endDate != null) ...[
                      const SizedBox(width: 14),
                      _StatChip(label: _fmtDate(endDate), sub: 'deadline'),
                    ],
                  ]),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Impact quote ──────────────────────────────────────────────────
          if (impactQuote != null && impactQuote.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _PD.amberBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _PD.amber.withValues(alpha: 0.25))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 4, height: 50,
                    decoration: BoxDecoration(
                        color: _PD.amber, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 14),
                  Expanded(child: Text('"$impactQuote"',
                    style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: _PD.text, height: 1.55,
                      fontStyle: FontStyle.italic))),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],

          // ── Sticky tab bar ────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: _PD.teal,
                  unselectedLabelColor: _PD.sub,
                  indicatorColor: _PD.teal,
                  indicatorWeight: 2.5,
                  labelStyle: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(text: 'Campaign Story'),
                    Tab(text: 'Updates (${_updates.length})'),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab content (index-driven, rebuild on setState) ───────────────
          SliverToBoxAdapter(
            child: _tabCtrl.index == 0
                ? _StoryTab(story: story)
                : _UpdatesTab(updates: _updates),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ]),

        // ── Sticky donate bar ─────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _DonateBar(
            project: widget.project,
            availablePoints: _availablePoints,
            onDonated: (amount) {
              setState(() => _availablePoints -= amount);
              widget.onDonationSuccess?.call();
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero placeholder (gradient + icon)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_PD.teal, _PD.tealDark],
        begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.volunteer_activism_rounded,
          color: Colors.white.withValues(alpha: 0.5), size: 80),
      const SizedBox(height: 12),
      Text('Campaign', style: GoogleFonts.outfit(
          color: Colors.white54, fontSize: 14)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Story tab
// ─────────────────────────────────────────────────────────────────────────────
class _StoryTab extends StatelessWidget {
  final String story;
  const _StoryTab({required this.story});

  @override
  Widget build(BuildContext context) {
    if (story.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Column(children: [
          Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No story added yet.',
              style: GoogleFonts.outfit(fontSize: 14, color: _PD.sub)),
          const SizedBox(height: 4),
          Text('Check the admin panel to add a campaign story.',
              style: GoogleFonts.outfit(fontSize: 12, color: _PD.sub)),
        ])),
      );
    }
    final paragraphs = story
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final para in paragraphs) ...[
          Text(para,
            style: GoogleFonts.outfit(
              fontSize: 15.5, color: _PD.text,
              height: 1.8, fontWeight: FontWeight.w400)),
          const SizedBox(height: 14),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Updates tab
// ─────────────────────────────────────────────────────────────────────────────
class _UpdatesTab extends StatelessWidget {
  final List<ProjectUpdate> updates;
  const _UpdatesTab({required this.updates});

  String _rel(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays} days ago';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Column(children: [
          Icon(Icons.notifications_none_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No updates yet.',
              style: GoogleFonts.outfit(fontSize: 14, color: _PD.sub)),
          const SizedBox(height: 4),
          Text('Check back soon for campaign news.',
              style: GoogleFonts.outfit(fontSize: 12, color: _PD.sub)),
        ])),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(children: [
        for (int i = 0; i < updates.length; i++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Timeline column
              Column(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: i == 0 ? _PD.teal : _PD.border,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: i == 0 ? _PD.tealDark : _PD.sub.withValues(alpha: 0.3),
                        width: 2)),
                ),
                if (i < updates.length - 1)
                  Expanded(child: Container(
                    width: 2, color: _PD.border,
                    margin: const EdgeInsets.symmetric(vertical: 4))),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_rel(updates[i].createdAt),
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: _PD.sub,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    if (updates[i].title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(updates[i].title,
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: _PD.text)),
                    ],
                    const SizedBox(height: 6),
                    Text(updates[i].content,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: _PD.sub, height: 1.6)),
                  ]),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky donate bar
// ─────────────────────────────────────────────────────────────────────────────
class _DonateBar extends StatelessWidget {
  final Map<String, dynamic> project;
  final int availablePoints;
  final void Function(int) onDonated;

  const _DonateBar({
    required this.project,
    required this.availablePoints,
    required this.onDonated,
  });

  void _open(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DonateSheet(
        project: project,
        availablePoints: availablePoints,
        onSuccess: (amount) {
          onDonated(amount);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('JazakAllah Khayran! $amount points donated.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
            ]),
            backgroundColor: _PD.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = project['is_completed'] == true;
    final hasPoints   = availablePoints > 0;
    final canDonate   = !isCompleted && hasPoints;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20, offset: const Offset(0, -4))]),
      child: Row(children: [
        // Balance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: _PD.tealBg, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Balance',
                style: GoogleFonts.outfit(fontSize: 10, color: _PD.sub)),
            Text('$availablePoints pts',
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w800, color: _PD.teal)),
          ]),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: GestureDetector(
            onTap: canDonate ? () => _open(context) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: canDonate
                    ? LinearGradient(
                        colors: [Y4.butter, Y4.honey],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight)
                    : null,
                color: canDonate ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                boxShadow: canDonate
                    ? [BoxShadow(
                        color: Y4.honeyDeep.withValues(alpha: 0.35),
                        blurRadius: 16, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded
                      : Icons.volunteer_activism_rounded,
                  color: canDonate ? Y4.ink : Colors.grey.shade400,
                  size: 20),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Fully Funded ✓'
                      : !hasPoints ? 'No Points Available'
                      : 'Donate & Earn Reward',
                  style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: canDonate ? Y4.ink : Colors.grey.shade500)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donate modal sheet
// ─────────────────────────────────────────────────────────────────────────────
class _DonateSheet extends StatefulWidget {
  final Map<String, dynamic> project;
  final int availablePoints;
  final void Function(int) onSuccess;

  const _DonateSheet({
    required this.project,
    required this.availablePoints,
    required this.onSuccess,
  });

  @override
  State<_DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<_DonateSheet> {
  int _amount = 50;
  bool _donating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.availablePoints < 50) {
      _amount = widget.availablePoints.clamp(1, 50);
    }
  }

  Future<void> _donate() async {
    setState(() { _donating = true; _error = null; });
    final err = await DonationService.instance.donate(
        widget.project['id'] as String, _amount);
    if (!mounted) return;
    if (err == null) {
      widget.onSuccess(_amount);
    } else {
      setState(() { _donating = false; _error = err; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxPts = widget.availablePoints.clamp(1, 99999);

    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Support this Cause',
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _PD.text)),
                const SizedBox(height: 4),
                Text(widget.project['title'] ?? '',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: _PD.sub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),

                // Balance
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: _PD.tealBg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: _PD.teal, size: 20),
                    const SizedBox(width: 10),
                    Text('Your balance:',
                        style: GoogleFonts.outfit(fontSize: 13, color: _PD.sub)),
                    const Spacer(),
                    Text('${widget.availablePoints} pts',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w800, color: _PD.teal)),
                  ]),
                ),
                const SizedBox(height: 24),

                // Quick presets
                Row(children: [
                  for (final preset in [50, 100, 500]) ...[
                    _Preset(preset, _amount, maxPts,
                        () => setState(() => _amount = preset.clamp(1, maxPts))),
                    const SizedBox(width: 8),
                  ],
                  _Preset(maxPts, _amount, maxPts,
                      () => setState(() => _amount = maxPts), label: 'MAX'),
                ]),
                const SizedBox(height: 24),

                // Big amount
                Center(child: Text('$_amount pts',
                  style: GoogleFonts.outfit(
                      fontSize: 42, fontWeight: FontWeight.w900,
                      color: _PD.teal, height: 1))),
                const SizedBox(height: 4),
                Center(child: Text('Slide to adjust',
                    style: GoogleFonts.outfit(fontSize: 12, color: _PD.sub))),

                Slider(
                  value: _amount.toDouble(),
                  min: 1,
                  max: maxPts.toDouble(),
                  activeColor: _PD.teal,
                  inactiveColor: _PD.teal.withValues(alpha: 0.15),
                  onChanged: (v) => setState(() => _amount = v.round()),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: GoogleFonts.outfit(
                      fontSize: 13, color: _PD.danger)),
                ],
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _donating ? null : _donate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _PD.teal, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                    child: _donating
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFC9921A))))
                        : Text('Donate $_amount pts',
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18)),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final Color textColor;
  const _Pill({required this.text, this.icon, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: 12, color: textColor),
        const SizedBox(width: 4),
      ],
      Text(text, style: GoogleFonts.outfit(
          fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sub;
  const _StatChip({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      if (sub.isNotEmpty)
        Text(sub, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white60)),
    ],
  );
}

class _Preset extends StatelessWidget {
  final int amount;
  final int selected;
  final int max;
  final VoidCallback onTap;
  final String? label;
  const _Preset(this.amount, this.selected, this.max, this.onTap, {this.label});

  @override
  Widget build(BuildContext context) {
    final isSel    = amount == selected;
    final disabled = amount > max && label == null;
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSel ? _PD.teal : (disabled ? Colors.grey.shade50 : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? _PD.teal : _PD.border, width: isSel ? 2 : 1)),
          child: Center(
            child: Text(label ?? '$amount',
              style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isSel ? Colors.white
                    : (disabled ? Colors.grey.shade300 : _PD.text))),
          ),
        ),
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SliverPersistentHeaderDelegate for the tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _TabBarDelegate({required this.child});

  @override double get minExtent => 48;
  @override double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.child != child;
}
