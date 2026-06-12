// lib/screens/orphan_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/orphan.dart';
import '../services/donation_service.dart';
import '../theme/y4_theme.dart';
import '../widgets/sabiq_coin.dart';

class OrphanDetailScreen extends StatefulWidget {
  final Orphan orphan;
  final int availablePoints;

  /// Fired after a successful sponsorship — the parent screen uses this to
  /// decrement its local cached seed balance.
  final void Function(int amount)? onSponsored;

  const OrphanDetailScreen({
    super.key,
    required this.orphan,
    required this.availablePoints,
    this.onSponsored,
  });

  @override
  State<OrphanDetailScreen> createState() => _OrphanDetailScreenState();
}

class _OrphanDetailScreenState extends State<OrphanDetailScreen> {
  late Orphan _orphan;
  late int _availablePoints;
  List<ProjectDonation> _recent = const [];
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    _orphan = widget.orphan;
    _availablePoints = widget.availablePoints;
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final list = await DonationService.instance.getOrphanRecentSponsors(_orphan.id);
    if (!mounted) return;
    setState(() {
      _recent = list;
      _loadingRecent = false;
    });
  }

  Future<void> _refreshStats() async {
    final s = await DonationService.instance.getOrphanStats(_orphan.id);
    if (s != null && mounted) {
      setState(() {
        _orphan.currentSeeds = s.currentSeeds;
        _orphan.sponsorCount = s.sponsorCount;
      });
    }
    _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Y4.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _heroAppBar(),
              SliverToBoxAdapter(child: _identity()),
              SliverToBoxAdapter(child: _sponsorshipCard()),
              SliverToBoxAdapter(child: _familySection()),
              SliverToBoxAdapter(child: _educationSection()),
              SliverToBoxAdapter(child: _storySection()),
              SliverToBoxAdapter(child: _verseCard()),
              SliverToBoxAdapter(child: _recentSponsorsSection()),
              // Bottom spacer = sticky sponsor bar height + device safe-area.
              // Without this the last visible content sits under the bar.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
          // Sticky sponsor CTA
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _stickySponsorBar(),
          ),
        ],
      ),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _heroAppBar() {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 320,
      backgroundColor: Y4.bg,
      foregroundColor: Y4.ink,
      iconTheme: const IconThemeData(color: Y4.ink),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _orphan.photoUrl != null && _orphan.photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _orphan.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Y4.butter),
                    errorWidget: (_, __, ___) => Container(
                      color: Y4.butter,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: Y4.honeyDeep,
                      ),
                    ),
                  )
                : Container(
                    color: Y4.butter,
                    alignment: Alignment.center,
                    child: Text(
                      _orphan.firstName.isNotEmpty
                          ? _orphan.firstName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.fraunces(
                        fontSize: 120,
                        color: Y4.honeyDeep,
                      ),
                    ),
                  ),
            // Soft cream gradient at the bottom so the hero blends into the page
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.55, 1.0],
                  colors: [Colors.transparent, Y4.bg],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _orphan.displayName,
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Y4.ink,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('${_orphan.age} years'),
              if (_orphan.gender != null && _orphan.gender!.isNotEmpty)
                _chip(_orphan.gender == 'female' ? 'Girl' : 'Boy'),
              if (_orphan.displayLocation != null)
                _chip(_orphan.displayLocation!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sponsorshipCard() {
    final progress = _orphan.progressRatio;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Y4.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Y4.honey.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_orphan.currentSeeds} of ${_orphan.targetSeeds} Seeds',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Y4.ink,
                  ),
                ),
                Text(
                  _orphan.sponsorCount == 0
                      ? 'Open'
                      : '${_orphan.sponsorCount} sponsor${_orphan.sponsorCount == 1 ? '' : 's'}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Y4.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Y4.track,
                valueColor: const AlwaysStoppedAnimation(Y4.honeyDeep),
              ),
            ),
            if (_orphan.partnerOrg != null && _orphan.partnerOrg!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Through ${_orphan.partnerOrg!}',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: Y4.inkSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _familySection() {
    final l = AppLocalizations.of(context);
    final items = <Widget>[];
    if (_orphan.fatherPassedCause != null &&
        _orphan.fatherPassedCause!.isNotEmpty) {
      items.add(_familyRow(
        l?.fatherLabel ?? 'Father',
        _orphan.fatherPassedCause!,
      ));
    }
    if (_orphan.motherStatus != null && _orphan.motherStatus!.isNotEmpty) {
      items.add(_familyRow(
        l?.motherLabel ?? 'Mother',
        _orphan.motherStatus!,
      ));
    }
    if (_orphan.siblingsCount > 0) {
      items.add(_familyRow(
        l?.siblingsLabel ?? 'Siblings',
        '${_orphan.siblingsCount} ${_orphan.siblingsCount == 1 ? 'brother or sister' : 'brothers & sisters'}',
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return _section(l?.familySection ?? 'Family', Column(children: items));
  }

  Widget _familyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Y4.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: Y4.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationSection() {
    if ((_orphan.grade == null || _orphan.grade!.isEmpty) &&
        (_orphan.school == null || _orphan.school!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    return _section(
      l?.educationSection ?? 'Education',
      Column(
        children: [
          if (_orphan.grade != null && _orphan.grade!.isNotEmpty)
            _familyRow(l?.gradeLabel ?? 'Grade', _orphan.grade!),
          if (_orphan.school != null && _orphan.school!.isNotEmpty)
            _familyRow(l?.schoolLabel ?? 'School', _orphan.school!),
        ],
      ),
    );
  }

  Widget _storySection() {
    if (_orphan.story == null || _orphan.story!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _section(
      AppLocalizations.of(context)?.theirStorySection ?? 'Their story',
      Text(
        _orphan.story!,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: Y4.ink,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _verseCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Y4.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Y4.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وَيُطْعِمُونَ الطَّعَامَ عَلَىٰ حُبِّهِ مِسْكِينًا وَيَتِيمًا وَأَسِيرًا',
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Y4.ink,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"And they give food, despite their love for it, to the needy, the orphan, and the captive.", Qur’an 76:8',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Y4.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentSponsorsSection() {
    if (_loadingRecent) return const SizedBox.shrink();
    if (_recent.isEmpty) return const SizedBox.shrink();
    return _section(
      'Sponsored by',
      Column(
        children: _recent
            .map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Y4.butter,
                      backgroundImage: s.avatarUrl != null && s.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(s.avatarUrl!)
                          : null,
                      child: s.avatarUrl == null || s.avatarUrl!.isEmpty
                          ? Text(
                              s.displayName.isNotEmpty
                                  ? s.displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Y4.honeyDeep,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color: Y4.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _timeAgo(s.donatedAt),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Y4.inkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${s.amount}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Y4.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const SabiqCoin(size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Y4.inkSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Y4.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Y4.border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Y4.butter,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Y4.honeyDeep,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _stickySponsorBar() {
    final hasEnough = _availablePoints >= _orphan.minSponsorship;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Y4.bg,
          boxShadow: [
            BoxShadow(
              color: Y4.ink.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)?.yourBalanceLabel ??
                        'Your balance',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Y4.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$_availablePoints Seeds',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Y4.ink,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: hasEnough ? _openSponsorSheet : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Y4.honeyDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Y4.muted,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                hasEnough
                    ? (AppLocalizations.of(
                            context,
                          )?.sponsorCta(_orphan.firstName) ??
                        'Sponsor ${_orphan.firstName}')
                    : (AppLocalizations.of(context)?.notEnoughSeeds ??
                        'Not enough Seeds'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSponsorSheet() async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SponsorSheet(
        orphan: _orphan,
        availablePoints: _availablePoints,
        onSuccess: (amount) {
          setState(() => _availablePoints -= amount);
          widget.onSponsored?.call(amount);
          Navigator.of(ctx).pop();
          _refreshStats();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Y4.amberY,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              content: Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'JazakAllah Khayran! $amount Seeds sponsored.',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sponsor sheet — amount picker + confirm
// ─────────────────────────────────────────────────────────────────────────────
class _SponsorSheet extends StatefulWidget {
  final Orphan orphan;
  final int availablePoints;
  final void Function(int amount) onSuccess;

  const _SponsorSheet({
    required this.orphan,
    required this.availablePoints,
    required this.onSuccess,
  });

  @override
  State<_SponsorSheet> createState() => _SponsorSheetState();
}

class _SponsorSheetState extends State<_SponsorSheet> {
  late int _amount;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amount = widget.orphan.minSponsorship;
  }

  List<int> get _presets {
    final min = widget.orphan.minSponsorship;
    return [min, min * 2, min * 5, min * 10];
  }

  Future<void> _submit() async {
    if (_amount < widget.orphan.minSponsorship) return;
    if (_amount > widget.availablePoints) return;
    setState(() => _submitting = true);
    final err = await DonationService.instance
        .sponsorOrphan(widget.orphan.id, _amount);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err == null) {
      widget.onSuccess(_amount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Text(err, style: GoogleFonts.outfit(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _amount >= widget.orphan.minSponsorship &&
        _amount <= widget.availablePoints &&
        !_submitting;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Y4.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sponsor ${widget.orphan.firstName}',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Y4.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how many Seeds to give. Minimum ${widget.orphan.minSponsorship}.',
            style: GoogleFonts.outfit(fontSize: 13, color: Y4.inkSoft),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _presets.map((p) {
              final selected = _amount == p;
              final disabled = p > widget.availablePoints;
              return GestureDetector(
                onTap: disabled ? null : () => setState(() => _amount = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: disabled
                        ? Y4.track.withValues(alpha: 0.4)
                        : selected
                            ? Y4.honey
                            : Y4.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Y4.honeyDeep : Y4.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: disabled ? 0.4 : 1,
                        child: const SabiqCoin(size: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$p',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: disabled ? Y4.muted : Y4.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.customLabel ?? 'Custom',
              suffixText: AppLocalizations.of(context)?.seedsSuffix ?? 'Seeds',
              filled: true, fillColor: Y4.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Y4.border),
              ),
            ),
            onChanged: (v) => setState(() => _amount = int.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SabiqCoin(size: 14),
              const SizedBox(width: 5),
              Text(
                'Your balance: ${widget.availablePoints} Seeds',
                style: GoogleFonts.outfit(fontSize: 12, color: Y4.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Y4.honeyDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Y4.muted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? Text(
                      'Sponsoring…',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm $_amount',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SabiqCoin(size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
