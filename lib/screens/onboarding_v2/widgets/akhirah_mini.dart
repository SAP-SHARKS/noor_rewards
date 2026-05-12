// lib/screens/onboarding_v2/widgets/akhirah_mini.dart
//
// Mock phone-in-phone Akhirah Account screen used as fallback for the
// onb_akhirah_7 slot. Renders four "holdings" tiles (trees, palaces,
// freed souls, blessings) on a teal-tinted card.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'onboarding_tokens.dart';

class AkhirahMini extends StatelessWidget {
  final double width;
  final double tilt;
  const AkhirahMini({super.key, this.width = 220, this.tilt = 0});

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = w * 2.0;
    return Transform.rotate(
      angle: tilt * math.pi / 180.0,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: OnbTok.brown.withValues(alpha: 0.35),
              blurRadius: 60,
              offset: const Offset(0, 30),
              spreadRadius: -28,
            ),
          ],
        ),
        padding: EdgeInsets.all(w * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Akhirah',
              style: OnbTok.sans(
                fontSize: w * 0.05,
                fontWeight: FontWeight.w700,
                color: OnbTok.tealDark,
                letterSpacing: w * 0.005,
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              'Authentic hadith — your real ledger',
              style: OnbTok.sans(
                fontSize: w * 0.035,
                color: OnbTok.brownSoft,
                height: 1.3,
              ),
            ),
            SizedBox(height: w * 0.05),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: w * 0.04,
                crossAxisSpacing: w * 0.04,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Tile(width: w, icon: Icons.park_outlined,
                      label: 'Trees', value: '127'),
                  _Tile(width: w, icon: Icons.castle_outlined,
                      label: 'Palaces', value: '3'),
                  _Tile(width: w, icon: Icons.favorite_outline_rounded,
                      label: 'Freed', value: '11'),
                  _Tile(width: w, icon: Icons.auto_awesome_outlined,
                      label: 'Blessings', value: '∞'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  const _Tile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: OnbTok.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OnbTok.teal.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: OnbTok.tealDark, size: width * 0.06),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: OnbTok.serif(
                  fontSize: width * 0.085,
                  fontWeight: FontWeight.w500,
                  color: OnbTok.tealDark,
                  height: 1.0,
                ),
              ),
              SizedBox(height: width * 0.008),
              Text(
                label,
                style: OnbTok.sans(
                  fontSize: width * 0.034,
                  fontWeight: FontWeight.w600,
                  color: OnbTok.brownSoft,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
