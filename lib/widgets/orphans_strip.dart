// lib/widgets/orphans_strip.dart
// Horizontal row of orphan cards. The section header + "See all" CTA is
// owned by the parent (Cause page) — this widget just renders the cards.

import 'package:flutter/material.dart';

import '../models/orphan.dart';
import '../screens/orphan_detail_screen.dart';
import '../screens/orphans_grid_screen.dart';

class OrphansStrip extends StatelessWidget {
  final List<Orphan> orphans;
  final int availablePoints;
  final VoidCallback onChanged;

  const OrphansStrip({
    super.key,
    required this.orphans,
    required this.availablePoints,
    required this.onChanged,
  });

  /// Convenience navigation helper — exposed so the parent's "See all" CTA
  /// can route to the full grid without duplicating the navigation code.
  static Future<void> openGrid(
    BuildContext context, {
    required int availablePoints,
    required VoidCallback onChanged,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrphansGridScreen(
          availablePoints: availablePoints,
          onSponsorshipSuccess: onChanged,
        ),
      ),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (orphans.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: orphans.length > 6 ? 6 : orphans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => SizedBox(
          width: 148,
          child: OrphanCard(
            orphan: orphans[i],
            onTap: () => _openDetail(context, orphans[i]),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, Orphan o) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrphanDetailScreen(
          orphan: o,
          availablePoints: availablePoints,
          onSponsored: (_) => onChanged(),
        ),
      ),
    );
    onChanged();
  }
}
