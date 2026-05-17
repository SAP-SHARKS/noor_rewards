// lib/screens/onboarding_v2/widgets/onboarding_components.dart
//
// Shared onboarding UI primitives — Wordmark, Skip button, CTA, ScreenFooter
// with dots, PhotoSlot (admin-uploaded image + fallback).

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/onboarding_assets_service.dart';
import 'onboarding_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Wordmark — "sabiq" with the dot replaced by a small gold leaf.
// ─────────────────────────────────────────────────────────────────────────────
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'sabiq',
          style: GoogleFonts.newsreader(
            fontSize: size,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: OnbTok.brown,
            letterSpacing: -0.005 * size,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 3),
        CustomPaint(
          size: Size(size * 0.32, size * 0.32),
          painter: _LeafPainter(),
        ),
      ],
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = OnbTok.goldDeep;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width, size.height * 0.3,
          size.width * 0.7, size.height)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.7,
          size.width * 0.5, 0)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Skip button — top right.
// ─────────────────────────────────────────────────────────────────────────────
class SkipBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const SkipBtn({super.key, required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 14,
      right: 20,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 36),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          foregroundColor: OnbTok.brownSoft,
        ),
        child: Text(
          label,
          style: OnbTok.sans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: OnbTok.brownSoft,
            letterSpacing: 0.14, // 0.01em on 14px
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA — gold pill primary button.
// ─────────────────────────────────────────────────────────────────────────────
class CTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool disabled;
  const CTA({
    super.key,
    required this.label,
    this.onPressed,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: OnbTok.goldDeep.withValues(alpha: 0.55),
                    blurRadius: 22,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? OnbTok.creamWarm : OnbTok.gold,
            foregroundColor:
                isDisabled ? OnbTok.greySoft : OnbTok.brown,
            disabledBackgroundColor: OnbTok.creamWarm,
            disabledForegroundColor: OnbTok.greySoft,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            label,
            style: OnbTok.sans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDisabled ? OnbTok.greySoft : OnbTok.brown,
              letterSpacing: 0.16, // 0.01em
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 1 footer — dots above CTA. Dot styles match the design:
// inactive 6px circle (creamWarm), active 22×6 pill (gold), teal pill for S7.
// ─────────────────────────────────────────────────────────────────────────────
class ScreenFooter extends StatelessWidget {
  final Widget child;
  final int dotsIdx;
  final int dotsTotal;
  final bool teal;
  const ScreenFooter({
    super.key,
    required this.child,
    required this.dotsIdx,
    this.dotsTotal = 8,
    this.teal = false,
  });
  @override
  Widget build(BuildContext context) {
    final activeColor = teal ? OnbTok.teal : OnbTok.gold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(dotsTotal, (i) {
              final isActive = i == dotsIdx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : OnbTok.creamWarm,
                  borderRadius:
                      BorderRadius.circular(isActive ? 3 : 999),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhotoSlot — reads admin-uploaded URL for [slotKey]. Falls back to either
// a tasteful placeholder (default) or a caller-supplied [fallback] widget.
//
// Use [fallback] when an SVG illustration (e.g. QuranMini) should render
// while the admin hasn't uploaded a real screenshot yet.
// ─────────────────────────────────────────────────────────────────────────────
class PhotoSlot extends StatelessWidget {
  final String slotKey;
  final String? placeholderText;
  final Widget? fallback;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  const PhotoSlot({
    super.key,
    required this.slotKey,
    this.placeholderText,
    this.fallback,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, OnbImage>>(
      valueListenable: OnboardingAssetsService.instance.images,
      builder: (_, map, __) {
        final entry = map[slotKey];
        final url = entry?.url;
        // Admin-chosen crop wins; otherwise fall back to the fit the
        // calling screen requested.
        final resolved = resolveOnbFit(entry?.fit, fit);
        final body = (url != null && url.isNotEmpty)
            ? Container(
                color: OnbTok.creamWarm,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred cover backdrop fills any letterbox area
                    // with a soft, color-matched version of the image.
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 28,
                        sigmaY: 28,
                        tileMode: TileMode.decal,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    // Foreground: actual photo at the resolved fit +
                    // alignment (admin crop control).
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: resolved.fit,
                      alignment: resolved.alignment,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) =>
                          _Placeholder(text: placeholderText),
                      errorWidget: (_, __, ___) =>
                          fallback ?? _Placeholder(text: placeholderText),
                    ),
                  ],
                ),
              )
            : (fallback ?? _Placeholder(text: placeholderText));
        return borderRadius != null
            ? ClipRRect(borderRadius: borderRadius!, child: body)
            : body;
      },
    );
  }
}

/// Maps an admin crop/fit token to a concrete ([BoxFit], [Alignment]) pair.
/// Unknown / null tokens fall back to [fallback] at center alignment, so a
/// slot with no admin override keeps the screen's intended behaviour.
({BoxFit fit, Alignment alignment}) resolveOnbFit(
  String? token,
  BoxFit fallback,
) {
  switch (token) {
    case 'cover_center':
      return (fit: BoxFit.cover, alignment: Alignment.center);
    case 'cover_top':
      return (fit: BoxFit.cover, alignment: Alignment.topCenter);
    case 'cover_bottom':
      return (fit: BoxFit.cover, alignment: Alignment.bottomCenter);
    case 'contain':
      return (fit: BoxFit.contain, alignment: Alignment.center);
    case 'fill':
      return (fit: BoxFit.fill, alignment: Alignment.center);
    default:
      return (fit: fallback, alignment: Alignment.center);
  }
}

class _Placeholder extends StatelessWidget {
  final String? text;
  const _Placeholder({this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: OnbTok.creamWarm,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, color: OnbTok.greySoft, size: 22),
          if (text != null && text!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                text!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnbTok.sans(
                  fontSize: 10.5,
                  color: OnbTok.greySoft,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heading helper — renders a two-part title where the second clause is in
// italic gold (or italic teal for S7).
// ─────────────────────────────────────────────────────────────────────────────
class OnbHeading extends StatelessWidget {
  final String first;
  final String accent;
  final String? trailing; // optional 3rd clause for S6
  final double fontSize;
  final Color accentColor;
  final TextAlign align;
  const OnbHeading({
    super.key,
    required this.first,
    required this.accent,
    this.trailing,
    this.fontSize = 30,
    this.accentColor = OnbTok.goldDeep,
    this.align = TextAlign.start,
  });
  @override
  Widget build(BuildContext context) {
    final base = OnbTok.serif(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.01 * fontSize,
      height: 1.15,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$first ', style: base),
          TextSpan(
            text: accent,
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              color: accentColor,
            ),
          ),
          if (trailing != null && trailing!.isNotEmpty)
            TextSpan(text: ' $trailing', style: base),
        ],
      ),
      textAlign: align,
    );
  }
}
