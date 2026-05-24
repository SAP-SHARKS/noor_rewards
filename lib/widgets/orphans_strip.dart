// lib/widgets/orphans_strip.dart
// Horizontal "Sponsor an Orphan" strip — placed at the top of the Cause tab.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/orphan.dart';
import '../screens/orphan_detail_screen.dart';
import '../screens/orphans_grid_screen.dart';
import '../theme/y4_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    if (orphans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sponsor an Orphan',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Y4.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openGrid(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'See all →',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Y4.honeyDeep,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: orphans.length > 6 ? 6 : orphans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => SizedBox(
              width: 140,
              child: OrphanCard(
                orphan: orphans[i],
                onTap: () => _openDetail(context, orphans[i]),
              ),
            ),
          ),
        ),
        const Divider(
          height: 24, thickness: 1, color: Color(0xFFEEEEEE),
          indent: 20, endIndent: 20,
        ),
      ],
    );
  }

  Future<void> _openGrid(BuildContext context) async {
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
