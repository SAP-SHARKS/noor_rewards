import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';

class _GoalItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String reward;
  const _GoalItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.reward,
  });
}

class ProfileSetupScreen extends StatefulWidget {
  final void Function(String name) onComplete;
  const ProfileSetupScreen({super.key, required this.onComplete});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final Set<int> _selected = {};
  late AnimationController _glowCtrl;

  static const _goals = [
    _GoalItem(
      icon: Icons.menu_book_rounded,
      color: Color(0xFF00C875),
      title: 'Read the Quran Daily',
      description:
          'Build a radiant habit of reciting and reflecting on Allah\'s words every single day',
      reward: '+10 per ayah',
    ),
    _GoalItem(
      icon: Icons.blur_circular_rounded,
      color: Color(0xFFFFAA00),
      title: 'Maintain Daily Azkar',
      description:
          'Keep your heart alive, SubhanAllah, Alhamdulillah, AllahuAkbar, 99 times each',
      reward: '+20 per set',
    ),
    _GoalItem(
      icon: Icons.self_improvement_rounded,
      color: Color(0xFFDD88FF),
      title: 'Purify My Soul',
      description:
          'Seek nearness to Allah through sincere Tawbah, dhikr and conscious worship',
      reward: '+30 per act',
    ),
    _GoalItem(
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF4FC3F7),
      title: 'Give Sadaqah Generously',
      description:
          'Every dirham given sincerely extinguishes sin as water does fire, give and grow',
      reward: '+50 per gift',
    ),
    _GoalItem(
      icon: Icons.school_rounded,
      color: Color(0xFFFF8A65),
      title: 'Deepen Islamic Knowledge',
      description:
          'Explore seerah, fiqh and tafseer, the Prophet ﷺ said: "Seek knowledge from the cradle"',
      reward: '+25 per lesson',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _nameCtrl.addListener(() => setState(() {}));
    _countryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_step == 0) return _nameCtrl.text.trim().isNotEmpty;
    if (_step == 1) return _countryCtrl.text.trim().isNotEmpty;
    return _selected.isNotEmpty;
  }

  Color get _accent =>
      [
        const Color(0xFF00C875),
        const Color(0xFFFFAA00),
        const Color(0xFFDD88FF),
      ][_step];

  void _next() async {
    if (!_canProceed) return;
    if (_step < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      setState(() => _loading = true);
      await _saveProfile();
      widget.onComplete(_nameCtrl.text.trim());
    }
  }

  Future<void> _saveProfile() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final name = _nameCtrl.text.trim();
    final country = _countryCtrl.text.trim();
    final goals = _selected.map((i) => _goals[i].title).toList();
    try {
      // ── 1. Upsert into profiles table (primary persistent store) ──────────
      await Supabase.instance.client.from('profiles').upsert({
        'id': uid,
        'display_name': name,
        'country': country,
        'goals': goals,
        'setup_done': true,
      });

      // ── 2. Cache a lightweight flag in auth metadata (fast app-start reads)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'noor_setup_complete': true,
            'noor_name':
                name, // cached for greeting without extra DB round-trip
          },
        ),
      );
    } catch (_) {
      // Fail silently — app flow continues regardless
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GeoBgPainter())),
          AnimatedBuilder(
            animation: _glowCtrl,
            builder:
                (_, _) => Positioned(
                  top: -120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _accent.withValues(
                              alpha: 0.12 + _glowCtrl.value * 0.06,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildStepIndicator(),
                const SizedBox(height: 28),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _step = i),
                    children: [
                      _buildNameStep(),
                      _buildCountryStep(),
                      _buildGoalsStep(),
                    ],
                  ),
                ),
                _buildNextButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 36 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color:
                isDone
                    ? const Color(0xFF00C875)
                    : isActive
                    ? _accent
                    : Colors.white12,
          ),
          child:
              isDone
                  ? const Icon(Icons.check, size: 8, color: Colors.black87)
                  : null,
        );
      }),
    );
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مَا اسْمُكَ؟',
            style: GoogleFonts.amiri(
              fontSize: 28,
              color: const Color(0xFF00C875),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)?.callYou ??
                'What should we\ncall you?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)?.personaliseJourney ??
                'Personalise your spiritual journey with your name',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          _InputField(
            ctrl: _nameCtrl,
            hint: 'Ahmad, Fatima, Yusuf…',
            icon: Icons.person_outline_rounded,
            accent: const Color(0xFF00C875),
            onSubmit: _next,
          ),
        ],
      ),
    );
  }

  Widget _buildCountryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مِنْ أَيْنَ أَنْتَ؟',
            style: GoogleFonts.amiri(
              fontSize: 28,
              color: const Color(0xFFFFAA00),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)?.whereFrom ?? 'Where are\nyou from?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)?.joinMuslims ??
                'Join Muslims from around the world on this journey',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          _InputField(
            ctrl: _countryCtrl,
            hint: 'Pakistan, Egypt, Malaysia…',
            icon: Icons.public_rounded,
            accent: const Color(0xFFFFAA00),
            onSubmit: _next,
          ),
          const SizedBox(height: 20),
          // Country chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                [
                  '🇵🇰 Pakistan',
                  '🇸🇦 Saudi Arabia',
                  '🇪🇬 Egypt',
                  '🇲🇾 Malaysia',
                  '🇧🇩 Bangladesh',
                  '🇬🇧 UK',
                ].map((c) {
                  return GestureDetector(
                    onTap: () {
                      _countryCtrl.text = c.substring(c.indexOf(' ') + 1);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        c,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لِمَاذَا أَنْتَ هُنَا؟',
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  color: const Color(0xFFDD88FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)?.whatBringsYou ??
                    'What brings\nyou here?',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)?.chooseGoals ??
                    'Choose your spiritual goals, you can select multiple',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            itemCount: _goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final g = _goals[i];
              final sel = _selected.contains(i);
              return GestureDetector(
                onTap:
                    () => setState(() {
                      if (sel) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color:
                        sel
                            ? g.color.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color:
                          sel
                              ? g.color.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.1),
                      width: sel ? 1.5 : 1,
                    ),
                    boxShadow:
                        sel
                            ? [
                              BoxShadow(
                                color: g.color.withValues(alpha: 0.2),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                            : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: g.color.withValues(alpha: 0.18),
                        ),
                        child: Icon(g.icon, color: g.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sel ? g.color : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              g.description,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white54,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? g.color : Colors.transparent,
                          border: Border.all(
                            color: sel ? g.color : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child:
                            sel
                                ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.black87,
                                )
                                : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: GestureDetector(
        onTap: _canProceed ? _next : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: _canProceed ? _accent : Colors.white12,
            boxShadow:
                _canProceed
                    ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : [],
          ),
          child: Center(
            child:
                _loading
                    ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _step == 2 ? 'Begin My Journey' : 'Continue',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color:
                                _canProceed ? Colors.black87 : Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _step == 2
                              ? Icons.explore_rounded
                              : Icons.arrow_forward_rounded,
                          color: _canProceed ? Colors.black87 : Colors.white38,
                          size: 20,
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final Color accent;
  final VoidCallback onSubmit;
  const _InputField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color:
              ctrl.text.isNotEmpty
                  ? accent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow:
            ctrl.text.isNotEmpty
                ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
                : [],
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.outfit(
          fontSize: 17,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: accent,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 15, color: Colors.white30),
          prefixIcon: Icon(
            icon,
            color: ctrl.text.isNotEmpty ? accent : Colors.white30,
            size: 22,
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _GeoBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7;
    const sp = 88.0;
    for (double y = 0; y < size.height + sp; y += sp) {
      for (double x = 0; x < size.width + sp; x += sp) {
        final path = Path();
        for (int i = 0; i < 16; i++) {
          final a = (i * math.pi / 8) - math.pi / 2;
          final r = i.isEven ? 26.0 : 11.0;
          final p = Offset(x + r * math.cos(a), y + r * math.sin(a));
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
