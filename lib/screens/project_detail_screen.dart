// lib/screens/project_detail_screen.dart
// LaunchGood-inspired campaign article view — v2

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../utils/project_l10n.dart' as proj_l10n;
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
import '../widgets/sabiq_coin.dart';

AppConfig get _pdcfg => SettingsService.instance.config;

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _PD {
  static Color get teal => _pdcfg.dashTeal;
  static Color get tealDark =>
      HSLColor.fromColor(_pdcfg.dashTeal)
          .withLightness(
            (HSLColor.fromColor(_pdcfg.dashTeal).lightness - 0.05).clamp(
              0.0,
              1.0,
            ),
          )
          .toColor();
  static const tealBg = Color(0xFFE8F8F5);
  static const tealText = Color(0xFF0D6E64);
  static const amber = Color(0xFFEA9C24);
  static const amberBg = Color(0xFFFFF3D4);
  static Color get text => _pdcfg.dashText;
  static const sub = Color(0xFF6B7280);
  static const bg = Color(0xFFF8FAFB);
  static const border = Color(0xFFEEEEF2);
  static const card = Color(0xFFFFFFFF);
  static const danger = Color(0xFFE53935);
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
    createdAt:
        j['created_at'] != null
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
  List<ProjectMedia> _media = [];
  List<ProjectUpdate> _updates = [];
  List<ProjectDonation> _donors = const [];
  int _donorCount = 0;
  bool _loading = true;
  bool _aboutExpanded = false;
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
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final results = await Future.wait([
      DonationService.instance.getProjectMedia(id),
      _loadUpdates(id),
      DonationService.instance.getProjectDonors(id, limit: 50),
      DonationService.instance.getProjectDonorCounts(),
    ]);
    if (!mounted) return;
    setState(() {
      _media = results[0] as List<ProjectMedia>;
      _updates = results[1] as List<ProjectUpdate>;
      _donors = results[2] as List<ProjectDonation>;
      final counts = results[3] as Map<String, int>;
      _donorCount = counts[id] ?? _donors.length;
      _loading = false;
    });
    // Warm the image cache for this project's media so the carousel is
    // instant once the user scrolls to it. Fire-and-forget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final m in _media) {
        if (m.isVideo) continue;
        precacheImage(
          CachedNetworkImageProvider(m.url),
          context,
          onError: (_, __) {},
        );
      }
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
    } catch (_) {
      return [];
    }
  }

  // ── Share helpers ─────────────────────────────────────────────────────────
  String _shareText(BuildContext ctx) {
    final l = AppLocalizations.of(ctx);
    final p = widget.project;
    final title = p['title'] as String? ?? '';
    final sponsor = p['sponsor'] as String? ?? '';
    // Header line kept hardcoded — has embedded double quotes around `$title`
    // which the codemod couldn't flag; a translator can localise via a
    // future manual key add if needed.
    final header = '🤲 Support "$title"\n\n';
    final org = l?.projectDetailScreen_organisedBy_8b317a(sponsor) ??
        'Organised by $sponsor\n\n';
    final funded = l?.projectDetailScreen_fundedSoFarEvery_dab3fd ??
        'Funded so far, every Seed counts!\n\n';
    final cta = l?.projectDetailScreen_openSabiqRewardsApp_cdda14 ??
        'Open Sabiq Rewards app to donate your Seeds and earn reward.\n';
    final tags = l?.projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5 ??
        '#SabiqRewards #Sadaqah #IslamicCharity';
    return '$header$org$funded$cta$tags';
  }

  Future<void> _shareGeneric() async {
    HapticFeedback.lightImpact();
    await SharePlus.instance.share(ShareParams(text: _shareText(context)));
  }

  Future<void> _shareWhatsApp() async {
    HapticFeedback.mediumImpact();
    final encoded = Uri.encodeComponent(_shareText(context));
    // wa.me deep-link works on Android & iOS (opens WhatsApp directly)
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: generic share if WhatsApp not installed
      await SharePlus.instance.share(ShareParams(text: _shareText(context)));
    }
  }

  // ── Share bottom sheet ────────────────────────────────────────────────────
  void _openShareSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)?.shareCampaign ??
                      'Share Campaign',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _PD.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)?.spreadTheWord ??
                      'Spread the word and help this cause reach its goal.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: _PD.sub),
                ),
                const SizedBox(height: 24),

                // WhatsApp button
                _ShareBtn(
                  icon: Icons.chat_rounded,
                  label:
                      AppLocalizations.of(context)?.shareViaWhatsApp ??
                      'Share via WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    _shareWhatsApp();
                  },
                ),
                const SizedBox(height: 12),

                // Other apps
                _ShareBtn(
                  icon: Icons.share_rounded,
                  label:
                      AppLocalizations.of(context)?.moreSharingOptions ??
                      'More sharing options…',
                  color: _PD.teal,
                  onTap: () {
                    Navigator.pop(context);
                    _shareGeneric();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmtN(num n) =>
      n >= 1000000
          ? '${(n / 1000000).toStringAsFixed(1)}M'
          : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)}k'
          : '$n';

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
    final p = widget.project;
    final title = proj_l10n.projectTitle(context, p);
    final localizedDesc = proj_l10n.projectDescription(context, p);
    final story =
        (p['story'] as String?)?.isNotEmpty == true
            ? p['story'] as String
            : (localizedDesc.isNotEmpty
                ? localizedDesc
                : (AppLocalizations.of(context)?.projectDetailScreen_donateToProvideUrgent_246035 ??
                    'Donate to provide urgent, life-saving aid to Palestinians facing critical shortages of food, water, and medical supplies...'));
    final current = (p['current_points'] as num?)?.toInt() ?? 0;
    final target = (p['target_points'] as num?)?.toInt() ?? 1;
    final pct = (current / target).clamp(0.0, 1.0);
    final dpUrl = p['dp_url'] as String?;
    final isCompleted = p['is_completed'] == true;

    // TODO: fetch actual user contribution, mock for now
    final userPoints = 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Y4.palette.amberY,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)?.everyRecitationCanChangeLife ??
              'Every Recitation Can\nChange a Life',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Image Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          dpUrl != null && dpUrl.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: dpUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                                ),
                              )
                              : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade200,
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _PD.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Carousel
                ProjectMediaCarousel(media: _media, height: 220),
                const SizedBox(height: 24),

                // ── Given / Goal split header ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.givenLabel ?? 'GIVEN',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _PD.sub,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SabiqCoin(size: 24),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  AppLocalizations.of(context)?.projectDetailScreen_seeds_47387f(_fmtN(current)) ?? '${_fmtN(current)} Seeds',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Y4.display(
                                    fontSize: 26,
                                    color: Y4.palette.honeyDeep,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.goalUpper ?? 'GOAL',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _PD.sub,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SabiqCoin(size: 24),
                            const SizedBox(width: 5),
                            Text(
                              AppLocalizations.of(context)?.projectDetailScreen_seeds_801ec7(_fmtN(target)) ?? '${_fmtN(target)} Seeds',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _PD.text,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Bigger honey gradient progress bar with % on the right.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 12,
                          color: Y4.palette.honey.withValues(alpha: 0.18),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Y4.honey, Y4.honeyDeep],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(pct * 100).round()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _PD.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── About this Cause (with Read more / Show less) ───────
                Text(
                  AppLocalizations.of(context)?.aboutThisCause ??
                      'About this Cause',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _PD.text,
                  ),
                ),
                const SizedBox(height: 8),
                _AboutText(
                  text: story,
                  expanded: _aboutExpanded,
                  onToggle: () => setState(
                    () => _aboutExpanded = !_aboutExpanded,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Donors / Contributors section ───────────────────────
                _DonorsSection(donors: _donors, donorCount: _donorCount),
                const SizedBox(height: 24),

                // My Contribution Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Y4.palette.amberY.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Y4.palette.amberY.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: Y4.amberY,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)
                                ?.myContributionSeeds(userPoints) ??
                            'My contribution: ${_fmtN(userPoints)} ${userPoints == 1 ? 'Seed' : 'Seeds'}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Y4.palette.amberY,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky donate bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DonateBar(
              project: widget.project,
              availablePoints: _availablePoints,
              onDonated: (amount) {
                setState(() => _availablePoints -= amount);
                widget.onDonationSuccess?.call();
                // Re-fetch the donor list + contributor count so the
                // user's freshly-recorded donation appears immediately on
                // the same screen instead of only after re-opening it.
                _loadData();
              },
            ),
          ),
        ],
      ),
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
      // Use the root navigator so the sheet renders above the dashboard's
      // bottom navigation bar — otherwise, when reached via the Cause tab,
      // the nested tab navigator clips the sheet and the CTA button hides
      // behind the bottom nav.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetCtx) => _DonateSheet(
            project: project,
            availablePoints: availablePoints,
            onSuccess: (amount) {
              onDonated(amount);
              Navigator.of(sheetCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                                  ?.jazakAllahKhayranDonated(amount) ??
                              'JazakAllah Khayran! $amount ${amount == 1 ? 'Seed' : 'Seeds'} donated.',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Y4.palette.amberY,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = project['is_completed'] == true;
    final hasPoints = availablePoints > 0;
    final canDonate = !isCompleted && hasPoints;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: canDonate ? () => _open(context) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: canDonate ? Y4.palette.honey : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.workspace_premium_rounded,
                color: canDonate ? Y4.palette.ink : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCompleted
                    ? AppLocalizations.of(context)?.fullyFunded ??
                        'Fully Funded ✓'
                    : !hasPoints
                    ? AppLocalizations.of(context)?.noPointsAvailable ??
                        'No Seeds Available'
                    : AppLocalizations.of(context)?.donateAndEarnReward ??
                        'Donate & Earn Reward',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: canDonate ? Y4.palette.ink : Colors.grey.shade500,
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
    setState(() {
      _donating = true;
      _error = null;
    });
    final err = await DonationService.instance.donate(
      widget.project['id'] as String,
      _amount,
    );
    if (!mounted) return;
    if (err == null) {
      widget.onSuccess(_amount);
    } else {
      setState(() {
        _donating = false;
        _error = err;
      });
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
      builder:
          (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.supportThisCause ??
                              'Support this Cause',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _PD.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          proj_l10n.projectTitle(context, widget.project),
                          style: proj_l10n.localeAwareStyle(
                            context,
                            GoogleFonts.outfit(
                              fontSize: 13,
                              color: _PD.sub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Balance
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _PD.tealBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _PD.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)?.yourBalanceLabel ??
                                    'Your balance:',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: _PD.sub,
                                ),
                              ),
                              const Spacer(),
                              const SabiqCoin(size: 22),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.availablePoints} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _PD.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick presets
                        Row(
                          children: [
                            for (final preset in [50, 100, 500]) ...[
                              _Preset(
                                preset,
                                _amount,
                                maxPts,
                                () => setState(
                                  () => _amount = preset.clamp(1, maxPts),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            _Preset(
                              maxPts,
                              _amount,
                              maxPts,
                              () => setState(() => _amount = maxPts),
                              label: 'MAX',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Big amount
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SabiqCoin(size: 38),
                              const SizedBox(width: 10),
                              Text(
                                '$_amount ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: _PD.teal,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            AppLocalizations.of(context)?.slideToAdjust ??
                                'Slide to adjust',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _PD.sub,
                            ),
                          ),
                        ),

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
                          Text(
                            _error!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _PD.danger,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _donating ? null : _donate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _PD.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _donating
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFC9921A),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      AppLocalizations.of(context)
                                              ?.donateAmountSeeds(
                                                _amount.toString(),
                                              ) ??
                                          'Donate $_amount ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About-this-Cause body with Read more / Show less toggle.
// Collapsed = first 4 lines + ellipsis. Toggle is inline, in honey-deep.
// ─────────────────────────────────────────────────────────────────────────────
class _AboutText extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  const _AboutText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.outfit(
      fontSize: 14.5,
      color: _PD.text,
      height: 1.6,
      fontWeight: FontWeight.w500,
    );

    // Decide whether the text actually needs a toggle by measuring it
    // against the available width at 4 lines.
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 4,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topLeft,
              curve: Curves.easeOut,
              child: Text(
                text,
                style: style,
                maxLines: expanded ? null : 4,
                overflow: expanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ),
            if (overflows) ...[
              const SizedBox(height: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Text(
                  expanded
                      ? (AppLocalizations.of(context)?.showLess ?? 'Show less')
                      : (AppLocalizations.of(context)?.readMore ?? 'Read more'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Y4.palette.honeyDeep,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donors section — "X contributors" heading + recent donations list.
// Honey-tinted amount pills, soft cream avatar fallback, relative time.
// ─────────────────────────────────────────────────────────────────────────────
class _DonorsSection extends StatefulWidget {
  final List<ProjectDonation> donors;
  final int donorCount;
  const _DonorsSection({required this.donors, required this.donorCount});

  @override
  State<_DonorsSection> createState() => _DonorsSectionState();
}

class _DonorsSectionState extends State<_DonorsSection> {
  static const int _kPreview = 5;
  bool _expanded = false;

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _timeAgo(BuildContext ctx, DateTime d) {
    final l = AppLocalizations.of(ctx);
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      return l?.projectDetailScreen_ago_71107c(diff.inMinutes.toString()) ??
          '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return l?.projectDetailScreen_ago_c25b44(diff.inHours.toString()) ??
          '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return l?.projectDetailScreen_ago_e160e3(w.toString()) ?? '${w}w ago';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return l?.projectDetailScreen_moAgo_325a71(mo.toString()) ?? '${mo}mo ago';
    }
    final y = (diff.inDays / 365).floor();
    return l?.projectDetailScreen_ago_65f0ec(y.toString()) ?? '${y}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final donors = widget.donors;
    final count = widget.donorCount > 0 ? widget.donorCount : donors.length;
    final visible = _expanded ? donors : donors.take(_kPreview).toList();
    final hasMore = donors.length > _kPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_rounded, size: 18, color: Y4.honeyDeep),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)?.contributorCount(count) ??
                  '${_fmtCount(count)} ${count == 1 ? 'contributor' : 'contributors'}',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _PD.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (donors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Y4.palette.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _PD.border),
            ),
            child: Text(
              AppLocalizations.of(context)?.beFirstToContribute ??
                  'Be the first to contribute.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _PD.sub,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _PD.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 16,
                      color: Color(0xFFF1EFE6),
                    ),
                  _DonorRow(
                    donor: visible[i],
                    timeAgo: _timeAgo(context, visible[i].donatedAt),
                  ),
                ],
              ],
            ),
          ),
        if (hasMore) ...[
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  _expanded
                      ? (AppLocalizations.of(context)?.showFewer ?? 'Show fewer ↑')
                      : (AppLocalizations.of(context)
                              ?.viewAllN(donors.length.toString()) ??
                          'View all ${donors.length} →'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Y4.palette.honeyDeep,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DonorRow extends StatelessWidget {
  final ProjectDonation donor;
  final String timeAgo;
  const _DonorRow({required this.donor, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final initials = donor.displayName.trim().isEmpty
        ? '?'
        : donor.displayName.trim().substring(0, 1).toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar (cached network image with cream initial fallback)
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: donor.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: donor.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _AvatarFallback(initial: initials),
                      errorWidget: (_, __, ___) =>
                          _AvatarFallback(initial: initials),
                    )
                  : _AvatarFallback(initial: initials),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  donor.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _PD.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _PD.sub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Y4.palette.honey.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Y4.palette.honeyDeep.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SabiqCoin(size: 18),
                const SizedBox(width: 4),
                Text(
                  donor.amount.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Y4.palette.honeyDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initial;
  const _AvatarFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Y4.palette.cream,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Y4.palette.honeyDeep,
        ),
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final Color textColor;
  const _Pill({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    ),
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
      Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      if (sub.isNotEmpty)
        Text(
          sub,
          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white60),
        ),
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
    final isSel = amount == selected;
    final disabled = amount > max && label == null;
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color:
                isSel
                    ? _PD.teal
                    : (disabled ? Colors.grey.shade50 : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? _PD.teal : _PD.border,
              width: isSel ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label ?? '$amount',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isSel
                        ? Colors.white
                        : (disabled ? Colors.grey.shade300 : _PD.text),
              ),
            ),
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
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SliverPersistentHeaderDelegate for the tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _TabBarDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.child != child;
}
