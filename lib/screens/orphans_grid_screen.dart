// lib/screens/orphans_grid_screen.dart
// Full 2-column grid of all active sponsored orphans.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/orphan.dart';
import '../services/donation_service.dart';
import '../utils/name_localizer.dart';
import '../theme/y4_theme.dart';
import '../widgets/sabiq_coin.dart';
import 'orphan_detail_screen.dart';

class OrphansGridScreen extends StatefulWidget {
  /// User's currently spendable Seeds. Forwarded into the detail screen so the
  /// sponsor sheet shows live balance + can disable the CTA when insufficient.
  final int availablePoints;
  final VoidCallback? onSponsorshipSuccess;

  const OrphansGridScreen({
    super.key,
    required this.availablePoints,
    this.onSponsorshipSuccess,
  });

  @override
  State<OrphansGridScreen> createState() => _OrphansGridScreenState();
}

class _OrphansGridScreenState extends State<OrphansGridScreen> {
  List<Orphan> _orphans = const [];
  bool _loading = true;
  late int _availablePoints;

  @override
  void initState() {
    super.initState();
    _availablePoints = widget.availablePoints;
    _load();
  }

  Future<void> _load() async {
    final list = await DonationService.instance.getOrphans();
    if (!mounted) return;
    setState(() {
      _orphans = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Y4.palette.background,
      appBar: AppBar(
        backgroundColor: Y4.palette.background,
        elevation: 0,
        foregroundColor: Y4.palette.ink,
        title: Text(
          l?.sponsorAnOrphan ?? 'Sponsor an Orphan',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Y4.palette.ink,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Y4.honeyDeep))
          : RefreshIndicator(
              color: Y4.palette.honeyDeep,
              onRefresh: _load,
              child: _orphans.isEmpty ? _emptyState() : _grid(),
            ),
    );
  }

  Widget _emptyState() {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.favorite_rounded, size: 56, color: Y4.palette.muted),
        const SizedBox(height: 16),
        Text(
          l?.noOrphansListed ?? 'No orphans listed yet',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Y4.palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l?.checkBackForOrphans ??
              'Check back soon, new sponsorship opportunities are added regularly.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: Y4.palette.inkSoft,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _grid() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _verseHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => OrphanCard(
                orphan: _orphans[i],
                onTap: () => _openDetail(_orphans[i]),
              ),
              childCount: _orphans.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _verseHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Y4.palette.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Y4.palette.honey.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وَأَمَّا الْيَتِيمَ فَلَا تَقْهَرْ',
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Y4.palette.ink,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)?.orphanVerseTranslation ??
                  '"And as for the orphan, do not oppress him.", Qur’an 93:9',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: Y4.palette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(Orphan o) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrphanDetailScreen(
          orphan: o,
          availablePoints: _availablePoints,
          onSponsored: (amount) {
            setState(() => _availablePoints -= amount);
            widget.onSponsorshipSuccess?.call();
          },
        ),
      ),
    );
    // Refresh stats on return — sponsorships may have changed the progress bar.
    _load();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orphan card (used in both the grid screen + the Impact tab horizontal strip)
// ─────────────────────────────────────────────────────────────────────────────
class OrphanCard extends StatelessWidget {
  final Orphan orphan;
  final VoidCallback onTap;

  const OrphanCard({super.key, required this.orphan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = orphan.progressRatio;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Y4.palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Y4.palette.border),
          boxShadow: [
            BoxShadow(
              color: Y4.palette.ink.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo with grade-pill overlay — flex 11
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _photo(context),
                  if (orphan.grade != null && orphan.grade!.isNotEmpty)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Y4.palette.ink.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          orphan.grade!,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Y4.palette.honeyDeep,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info — flex 11 (slightly bigger to fit story snippet)
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizeName(context, orphan.firstName)} · ${orphan.age}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Y4.palette.ink,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (orphan.displayLocation != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            orphan.displayLocation!,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Y4.palette.inkSoft,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (orphan.story != null && orphan.story!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            orphan.story!,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Y4.palette.inkSoft,
                              fontStyle: FontStyle.italic,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Y4.palette.track,
                            valueColor:
                                const AlwaysStoppedAnimation(Y4.honeyDeep),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${orphan.currentSeeds}/${orphan.targetSeeds}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Y4.palette.ink,
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const SabiqCoin(size: 18),
                                ],
                              ),
                            ),
                            Text(
                              orphan.sponsorCount == 0
                                  ? (AppLocalizations.of(
                                          context,
                                        )?.orphanCardOpen ??
                                      'Open')
                                  : '${orphan.sponsorCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Y4.palette.primary,
                                height: 1.1,
                              ),
                            ),
                            if (orphan.sponsorCount > 0) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.favorite_rounded,
                                size: 10,
                                color: Y4.palette.primary,
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _photo(BuildContext context) {
    if (orphan.photoUrl == null || orphan.photoUrl!.isEmpty) {
      return Container(
        color: Y4.palette.butter,
        alignment: Alignment.center,
        child: Text(
          (() {
            final n = localizeName(context, orphan.firstName);
            return n.isNotEmpty ? n[0].toUpperCase() : '?';
          })(),
          style: GoogleFonts.fraunces(
            fontSize: 42,
            fontWeight: FontWeight.w500,
            color: Y4.palette.honeyDeep,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: orphan.photoUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Y4.palette.butter),
      errorWidget: (_, __, ___) => Container(
        color: Y4.palette.butter,
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: Y4.honeyDeep, size: 36),
      ),
    );
  }
}
