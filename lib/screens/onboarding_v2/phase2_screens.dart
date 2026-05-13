// lib/screens/onboarding_v2/phase2_screens.dart
//
// Phase 2 — Personalize (screens 8 and 9). Phase 2 runs AFTER the user has
// signed in. Screen 8 collects the name (same field ProfileSetupScreen
// formerly captured) and Screen 9 collects a preferred cause used for
// engagement signal only — persisted to local SharedPreferences as
// `onboarding_preferred_cause`, not to Supabase.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'widgets/decorations.dart';
import 'widgets/onboarding_components.dart';
import 'widgets/onboarding_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 8 — Name
// ─────────────────────────────────────────────────────────────────────────────
class Phase2Screen8 extends StatefulWidget {
  final void Function(String name) onSubmit;
  final String initialName;
  const Phase2Screen8({
    super.key,
    required this.onSubmit,
    this.initialName = '',
  });

  @override
  State<Phase2Screen8> createState() => _Phase2Screen8State();
}

class _Phase2Screen8State extends State<Phase2Screen8> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasText = _ctrl.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: OnbTok.cream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Wordmark(size: 26),
                    const SizedBox(height: 36),
                    const Center(child: SabiqGardenIcon(size: 88)),
                    const SizedBox(height: 30),
                    OnbHeading(
                      first: l.onbV2_8_TitleA,
                      accent: l.onbV2_8_TitleB,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l.onbV2_8_Sub,
                      textAlign: TextAlign.center,
                      style: OnbTok.sans(),
                    ),
                    const SizedBox(height: 34),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: OnbTok.creamWarm,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _focused ? OnbTok.gold : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _focused
                            ? [
                                BoxShadow(
                                  color: OnbTok.gold.withValues(alpha: 0.18),
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) widget.onSubmit(v.trim());
                        },
                        textInputAction: TextInputAction.done,
                        style: OnbTok.sans(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: OnbTok.brown,
                        ),
                        decoration: InputDecoration(
                          hintText: l.onbV2_8_Placeholder,
                          hintStyle: OnbTok.sans(
                            fontSize: 17,
                            color: OnbTok.greySoft,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: CTA(
                        label: l.onbV2_8_Cta,
                        disabled: !hasText,
                        onPressed: hasText
                            ? () => widget.onSubmit(_ctrl.text.trim())
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 9 — Cause Preference (4 cards, single-select, required)
// ─────────────────────────────────────────────────────────────────────────────

class Phase2Screen9 extends StatefulWidget {
  final VoidCallback onComplete;
  const Phase2Screen9({super.key, required this.onComplete});

  @override
  State<Phase2Screen9> createState() => _Phase2Screen9State();
}

class _Phase2Screen9State extends State<Phase2Screen9> {
  String? _sel;

  Future<void> _saveAndComplete() async {
    if (_sel == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_preferred_cause', _sel!);
    } catch (_) {
      // Non-fatal — engagement signal only.
    }
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final causes = <_Cause>[
      _Cause('orphans', l.onbV2_9_Orphans, l.onbV2_9_OrphansSub,
          'cause_orphans'),
      _Cause('water', l.onbV2_9_Water, l.onbV2_9_WaterSub, 'cause_water'),
      _Cause('war', l.onbV2_9_War, l.onbV2_9_WarSub, 'cause_war'),
      _Cause('disaster', l.onbV2_9_Disaster, l.onbV2_9_DisasterSub,
          'cause_disaster'),
    ];

    return Scaffold(
      backgroundColor: OnbTok.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wordmark(size: 26),
              const SizedBox(height: 18),
              OnbHeading(
                first: l.onbV2_9_TitleA,
                accent: l.onbV2_9_TitleB,
              ),
              const SizedBox(height: 10),
              Text(l.onbV2_9_Sub, style: OnbTok.sans()),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: causes.length,
                  itemBuilder: (_, i) {
                    final c = causes[i];
                    return _CauseCard(
                      cause: c,
                      selected: _sel == c.id,
                      onTap: () => setState(() => _sel = c.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: CTA(
                  label: l.onbV2_9_Cta,
                  disabled: _sel == null,
                  onPressed: _sel == null ? null : _saveAndComplete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cause {
  final String id;
  final String label;
  final String desc;
  final String slotKey;
  _Cause(this.id, this.label, this.desc, this.slotKey);
}

class _CauseCard extends StatelessWidget {
  final _Cause cause;
  final bool selected;
  final VoidCallback onTap;
  const _CauseCard({
    required this.cause,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? OnbTok.gold : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: OnbTok.gold.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: -10,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: OnbTok.brown.withValues(alpha: 0.10),
                    blurRadius: 14,
                    spreadRadius: -10,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 11,
                child: Stack(
                  children: [
                    PhotoSlot(
                      slotKey: cause.slotKey,
                      placeholderText: cause.label.toLowerCase(),
                    ),
                    if (selected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OnbTok.gold,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: OnbTok.brown,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cause.label,
                      style: OnbTok.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: OnbTok.brown,
                        letterSpacing: -0.07,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cause.desc,
                      style: OnbTok.sans(
                        fontSize: 11,
                        color: OnbTok.brownSoft,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
