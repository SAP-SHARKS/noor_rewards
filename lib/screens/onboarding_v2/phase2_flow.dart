// lib/screens/onboarding_v2/phase2_flow.dart
//
// Phase 2 controller — Screen 8 (name) → Screen 9 (cause) → onComplete(name).
// This replaces ProfileSetupScreen in the post-login auth flow.

import 'package:flutter/material.dart';

import 'phase2_screens.dart';
import 'widgets/onboarding_tokens.dart';

class Phase2Flow extends StatefulWidget {
  final void Function(String name) onComplete;
  final String initialName;
  const Phase2Flow({
    super.key,
    required this.onComplete,
    this.initialName = '',
  });

  @override
  State<Phase2Flow> createState() => _Phase2FlowState();
}

class _Phase2FlowState extends State<Phase2Flow> {
  String _name = '';
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnbTok.cream,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: _step == 0
            ? Phase2Screen8(
                key: const ValueKey('phase2-s8'),
                initialName: _name,
                onSubmit: (n) {
                  setState(() {
                    _name = n;
                    _step = 1;
                  });
                },
              )
            : Phase2Screen9(
                key: const ValueKey('phase2-s9'),
                onComplete: () => widget.onComplete(_name),
              ),
      ),
    );
  }
}
