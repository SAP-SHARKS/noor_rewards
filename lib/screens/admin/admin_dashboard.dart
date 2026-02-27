// lib/screens/admin/admin_dashboard.dart
// Full admin panel — sidebar nav + 6 sections

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/settings_service.dart';
import 'sponsor_analytics_section.dart';

// ── palette ─────────────────────────────────────────────────────────────────
const _kSideBg  = Color(0xFF0F172A);
const _kAccent  = Color(0xFF2BAE99);
const _kBg      = Color(0xFFF8FAFC);
const _kWhite   = Colors.white;
const _kText    = Color(0xFF1E293B);
const _kSub     = Color(0xFF64748B);
const _kBorder  = Color(0xFFE2E8F0);
const _kDanger  = Color(0xFFEF4444);
const _kGold    = Color(0xFFF59E0B);

// ── nav items ────────────────────────────────────────────────────────────────
const _navItems = [
  (icon: Icons.dashboard_rounded,        label: 'Overview'),
  (icon: Icons.monetization_on_rounded,  label: 'Economy'),
  (icon: Icons.palette_rounded,          label: 'Theme'),
  (icon: Icons.volunteer_activism,       label: 'Projects'),
  (icon: Icons.people_rounded,           label: 'Users'),
  (icon: Icons.flag_rounded,             label: 'Feature Flags'),
  (icon: Icons.campaign_rounded,         label: 'Banners'),
  (icon: Icons.settings_rounded,         label: 'All Config'),
  (icon: Icons.bar_chart_rounded,        label: 'Sponsor Report'),
];

// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _section = 0;
  final String _adminEmail =
      Supabase.instance.client.auth.currentUser?.email ?? '';

  static const _titles = [
    'Overview', 'Economy Controls', 'Theme & Colors',
    'Project Manager', 'User Management', 'Feature Flags',
    'Banners & Messages', 'Raw Config', 'Sponsor Report',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: _kBg,
      // SafeArea on the BODY so Scaffold handles the status bar correctly
      body: SafeArea(
        bottom: false,
        child: Row(children: [
          // ── Sidebar ────────────────────────────────────────────────────────
          if (isWide) _Sidebar(section: _section, onSelect: (i) => setState(() => _section = i)),
          // ── Content ────────────────────────────────────────────────────────
          Expanded(child: Column(children: [
            _TopBar(title: _titles[_section], section: _section,
                onNav: isWide ? null : (i) => setState(() => _section = i)),
            Expanded(child: _body()),
          ])),
        ]),
      ),
    );
  }

  Widget _body() {
    switch (_section) {
      case 0: return const _OverviewSection();
      case 1: return _EconomySection(adminEmail: _adminEmail);
      case 2: return _ThemeSection(adminEmail: _adminEmail);
      case 3: return const _ProjectsSection();
      case 4: return const _UsersSection();
      case 5: return _FeatureFlagsSection(adminEmail: _adminEmail);
      case 6: return _BannersSection(adminEmail: _adminEmail);
      case 7: return _RawConfigSection(adminEmail: _adminEmail);
      case 8: return const SponsorAnalyticsSection();
      default: return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int section;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.section, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: 220,
      color: _kSideBg,
      child: Column(children: [
        SizedBox(height: topPad + 16),
        // Logo
        Row(children: [
          const SizedBox(width: 20),
          const Text('🌙', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Text('NoorAdmin',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _kWhite)),
        ]),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Admin Panel', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38))),
        const SizedBox(height: 24),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(itemCount: _navItems.length, itemBuilder: (_, i) {
            final item = _navItems[i];
            final active = section == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? _kAccent.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(item.icon, size: 18,
                      color: active ? _kAccent : Colors.white54),
                  const SizedBox(width: 12),
                  Text(item.label,
                      style: GoogleFonts.outfit(fontSize: 13,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? _kAccent : Colors.white70)),
                ]),
              ),
            );
          }),
        ),
        const Divider(color: Colors.white12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(children: [
            const Icon(Icons.shield_rounded, color: _kAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              Supabase.instance.client.auth.currentUser?.email ?? '',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final int section;
  final ValueChanged<int>? onNav;
  const _TopBar({required this.title, required this.section, this.onNav});

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: _kWhite,
      border: Border(bottom: BorderSide(color: _kBorder)),
    ),
    child: Row(children: [
      if (onNav != null)
        PopupMenuButton<int>(
          icon: const Icon(Icons.menu_rounded, color: _kText),
          onSelected: onNav!,
          itemBuilder: (_) => List.generate(_navItems.length, (i) =>
            PopupMenuItem(value: i,
                child: Row(children: [
                  Icon(_navItems[i].icon, size: 18, color: _kAccent),
                  const SizedBox(width: 10),
                  Text(_navItems[i].label),
                ]))),
        )
      else
        const SizedBox(width: 8),
      Flexible(
        child: Text(title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
      ),
      const Spacer(),
      // Back button — always present on phone
      if (onNav != null) ...[
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kSub, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _kDanger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.verified_user_rounded, color: _kDanger, size: 16),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 0 — Overview
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewSection extends StatefulWidget {
  const _OverviewSection();
  @override State<_OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<_OverviewSection> {
  final _sb = Supabase.instance.client;
  int _totalUsers = 0, _totalXp = 0, _totalProjects = 0, _totalBadges = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final profiles  = await _sb.from('profiles').select('total_xp').count(CountOption.exact);
      final projects  = await _sb.from('community_projects').select('id').count(CountOption.exact);
      final badges    = await _sb.from('user_badges').select('id').count(CountOption.exact);
      _totalUsers    = profiles.count;
      _totalXp       = (profiles.data as List).fold(0, (s, r) => s + ((r['total_xp'] as num?)?.toInt() ?? 0));
      _totalProjects = projects.count;
      _totalBadges   = badges.count;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<SettingsService>().config;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Platform at a Glance',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _kSub)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _StatCard('👥', 'Total Users',    _loading ? '…' : '$_totalUsers',    _kAccent),
          _StatCard('⭐', 'Total XP Earned', _loading ? '…' : '$_totalXp',      const Color(0xFF6B4EBB)),
          _StatCard('🕌', 'Projects',         _loading ? '…' : '$_totalProjects', _kGold),
          _StatCard('🏅', 'Badges Earned',    _loading ? '…' : '$_totalBadges',  const Color(0xFFE05C6A)),
        ]),
        const SizedBox(height: 32),
        Text('Active Config Snapshot',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 12, children: [
          _ConfigChip('Coins/Ayah',    '${cfg.coinsPerAyah}'),
          _ConfigChip('Coins/Dhikr',   '${cfg.coinsPerDhikr}'),
          _ConfigChip('Daily Cap',     '${cfg.dailyFreeCap}'),
          _ConfigChip('XP/Ayah',       '${cfg.xpPerAyah}'),
          _ConfigChip('XP/Dhikr',      '${cfg.xpPerDhikr}'),
          _ConfigChip('Maintenance',   cfg.maintenanceMode ? 'ON 🔴' : 'Off'),
          _ConfigChip('Banner',        cfg.bannerEnabled ? 'LIVE 🟢' : 'Off'),
        ]),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatCard(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 80) / 2;
    return Container(
      width: w.clamp(130.0, 200.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(
            fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
      ]),
    );
  }
}

class _ConfigChip extends StatelessWidget {
  final String label, value;
  const _ConfigChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _kAccent.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: GoogleFonts.outfit(fontSize: 13, color: _kSub)),
      Text(value, style: GoogleFonts.outfit(
          fontSize: 13, fontWeight: FontWeight.w800, color: _kAccent)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 1 — Economy Controls
// ─────────────────────────────────────────────────────────────────────────────
class _EconomySection extends StatefulWidget {
  final String adminEmail;
  const _EconomySection({required this.adminEmail});
  @override State<_EconomySection> createState() => _EconomySectionState();
}

class _EconomySectionState extends State<_EconomySection> {
  late Map<String, TextEditingController> _ctrl;
  bool _saving = false;

  static const _fields = [
    (key: 'coins_per_ayah',         label: 'Coins per Ayah',            icon: '📖'),
    (key: 'coins_per_dhikr',        label: 'Coins per Dhikr Set',       icon: '📿'),
    (key: 'coins_per_tafsir_10min', label: 'Coins per 10min Tafsir',    icon: '🎧'),
    (key: 'coins_per_dua',          label: 'Coins per Dua',             icon: '🤲'),
    (key: 'xp_per_ayah',            label: 'XP per Ayah',               icon: '⭐'),
    (key: 'xp_per_dhikr',           label: 'XP per Dhikr Set',          icon: '✨'),
    (key: 'xp_per_tafsir_10min',    label: 'XP per 10min Tafsir',       icon: '🌟'),
    (key: 'xp_daily_login',         label: 'XP Daily Login',            icon: '☀️'),
    (key: 'xp_validate_coins',      label: 'XP for Validation',         icon: '✅'),
    (key: 'daily_free_cap',         label: 'Daily Free Coins Cap',      icon: '🔒'),
    (key: 'weekly_xp_cap',          label: 'Weekly XP Cap',             icon: '📅'),
  ];

  @override
  void initState() {
    super.initState();
    final cfg = SettingsService.instance.config;
    _ctrl = {
      for (final f in _fields) f.key: TextEditingController(text: cfg.rawValue(f.key))
    };
  }

  @override
  void dispose() { for (final c in _ctrl.values) {
    c.dispose();
  } super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updates = {for (final f in _fields) f.key: _ctrl[f.key]!.text.trim()};
    await SettingsService.instance.updateKeys(updates, adminEmail: widget.adminEmail);
    if (mounted) {
      setState(() => _saving = false);
      _snack('Economy config saved ✅');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _kAccent));

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader('Earning Rates', '💰',
          'Changes take effect immediately in the app for all users.'),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 520 ? 2 : 1;
        final itemW = (constraints.maxWidth - (cols - 1) * 16) / cols;
        return Wrap(spacing: 16, runSpacing: 16,
          children: _fields.map((f) => SizedBox(
            width: itemW,
            child: _NumField(
              label: '${f.icon}  ${f.label}',
              controller: _ctrl[f.key]!,
            ),
          )).toList(),
        );
      }),
      const SizedBox(height: 28),
      _SaveButton(saving: _saving, onTap: _save),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 2 — Theme & Colors
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeSection extends StatefulWidget {
  final String adminEmail;
  const _ThemeSection({required this.adminEmail});
  @override State<_ThemeSection> createState() => _ThemeSectionState();
}

class _ThemeSectionState extends State<_ThemeSection> {
  late Color _primary, _secondary, _donation, _bannerColor;
  bool _saving = false;

  // ── Quick-theme presets ───────────────────────────────────────────────────
  static const _kPresets = [
    (name: 'Noor Classic', emoji: '🌿',
      primary: Color(0xFF00897B), secondary: Color(0xFF546E7A),
      donation: Color(0xFFF59E0B), banner: Color(0xFF00695C)),
    (name: 'Midnight',     emoji: '🌙',
      primary: Color(0xFF5C6BC0), secondary: Color(0xFF3949AB),
      donation: Color(0xFFFFCA28), banner: Color(0xFF283593)),
    (name: 'Rose Garden',  emoji: '🌸',
      primary: Color(0xFFE91E8C), secondary: Color(0xFF9C27B0),
      donation: Color(0xFFFFC107), banner: Color(0xFFC2185B)),
    (name: 'Ocean',        emoji: '🌊',
      primary: Color(0xFF0097A7), secondary: Color(0xFF1976D2),
      donation: Color(0xFFFFB300), banner: Color(0xFF00838F)),
    (name: 'Autumn',       emoji: '🍂',
      primary: Color(0xFFE64A19), secondary: Color(0xFF5D4037),
      donation: Color(0xFFFF8F00), banner: Color(0xFFBF360C)),
    (name: 'Monochrome',   emoji: '🖤',
      primary: Color(0xFF455A64), secondary: Color(0xFF607D8B),
      donation: Color(0xFF90A4AE), banner: Color(0xFF263238)),
  ];

  int? _activePreset; // index of the selected preset (null = custom)

  void _applyPreset(int i) {
    final p = _kPresets[i];
    setState(() {
      _activePreset = i;
      _primary     = p.primary;
      _secondary   = p.secondary;
      _donation    = p.donation;
      _bannerColor = p.banner;
    });
  }



  @override
  void initState() {
    super.initState();
    final cfg = SettingsService.instance.config;
    _primary    = cfg.primaryColor;
    _secondary  = cfg.secondaryColor;
    _donation   = cfg.donationColor;
    _bannerColor = cfg.bannerColor;
  }

  String _toHex(Color c) =>
      c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');

  Future<void> _save() async {
    setState(() => _saving = true);
    await SettingsService.instance.updateKeys({
      'primary_color':   _toHex(_primary),
      'secondary_color': _toHex(_secondary),
      'donation_color':  _toHex(_donation),
      'banner_color':    _toHex(_bannerColor),
    }, adminEmail: widget.adminEmail);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme updated — app recolors instantly ✅'),
              backgroundColor: _kAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Live preview using the CURRENTLY saved config (Provider)
    final liveCfg = context.watch<SettingsService>().config;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Quick Theme Presets ─────────────────────────────────────────────
        Text('⚡ Quick Themes', style: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 6),
        Text('One tap to load a preset — then fine-tune with the colour pickers below.',
            style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final p = _kPresets[i];
              final selected = _activePreset == i;
              return GestureDetector(
                onTap: () => _applyPreset(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 130,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? p.primary : _kBorder,
                      width: selected ? 2.5 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: p.primary.withValues(alpha: 0.22),
                            blurRadius: 12, offset: const Offset(0, 4))]
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    // 4-colour swatch row
                    Row(children: [
                      for (final c in [p.primary, p.secondary, p.donation, p.banner])
                        Expanded(child: Container(
                          height: 26,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p.name,
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: _kText),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: p.primary),
                          const SizedBox(width: 4),
                          Text('Selected', style: GoogleFonts.outfit(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: p.primary)),
                        ]),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 28),
        Container(height: 1, color: _kBorder),
        const SizedBox(height: 28),

        // ── Manual colour pickers ────────────────────────────────────────────
        _SectionHeader('App Colors', '🎨',
            'Tap a color to open the picker. Changes push to all users in real-time.'),
        const SizedBox(height: 24),
        Wrap(spacing: 20, runSpacing: 20, children: [
          _ColorTile('Primary Color',   _primary,    (c) => setState(() { _primary    = c; _activePreset = null; })),
          _ColorTile('Secondary Color', _secondary,  (c) => setState(() { _secondary  = c; _activePreset = null; })),
          _ColorTile('Donation/Gold',   _donation,   (c) => setState(() { _donation   = c; _activePreset = null; })),
          _ColorTile('Banner Color',    _bannerColor,(c) => setState(() { _bannerColor = c; _activePreset = null; })),
        ]),
        const SizedBox(height: 28),
        // Live preview strip
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kWhite, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live App Preview', style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _PreviewChip('Primary',   liveCfg.primaryColor),
              _PreviewChip('Secondary', liveCfg.secondaryColor),
              _PreviewChip('Gold',      liveCfg.donationColor),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        _SaveButton(saving: _saving, onTap: _save),
      ]),
    );
  }
}

class _ColorTile extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChange;
  const _ColorTile(this.label, this.color, this.onChange);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      Color? picked = color;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 340,
            child: ColorPicker(
              color: color,
              onColorChanged: (c) => picked = c,
              heading: Text('Select Color', style: GoogleFonts.outfit()),
              subheading: Text('Choose shade', style: GoogleFonts.outfit()),
              pickersEnabled: const {
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.custom: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () { if (picked != null) onChange(picked!); Navigator.pop(context); },
              child: const Text('Apply'),
            ),
          ],
        ),
      );
    },
    child: Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        Container(
          height: 64, width: double.infinity,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
        const SizedBox(height: 4),
        Text('#${color.toARGB32().toRadixString(16).toUpperCase()}',
            style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
      ]),
    ),
  );
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PreviewChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
      Text('#${color.toARGB32().toRadixString(16).toUpperCase().substring(2)}',
          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 3 — Projects Manager
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectsSection extends StatefulWidget {
  const _ProjectsSection();
  @override State<_ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<_ProjectsSection> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await _sb.from('community_projects')
        .select().order('sort_order');
    setState(() { _projects = List.from(res); _loading = false; });
  }

  Future<void> _toggle(String id, bool current, String field) async {
    await _sb.from('community_projects').update({field: !current}).eq('id', id);
    _load();
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _kDanger),
              onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: _kWhite))),
        ],
      ));
    if (confirm == true) { await _sb.from('community_projects').delete().eq('id', id); _load(); }
  }

  Future<void> _editDialog([Map<String, dynamic>? existing]) async {
    final titleCtrl  = TextEditingController(text: existing?['title']  ?? '');
    final emojiCtrl  = TextEditingController(text: existing?['emoji']  ?? '🕌');
    final targetCtrl = TextEditingController(text: '${existing?['target_points'] ?? 10000000}');
    final usdCtrl    = TextEditingController(text: '${existing?['estimated_usd'] ?? 0}');
    final sponsorCtrl= TextEditingController(text: existing?['sponsor'] ?? 'Islamic Relief');

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Add Project' : 'Edit Project',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _Field('Title',         titleCtrl),
                  const SizedBox(height: 12),
                  _Field('Emoji',         emojiCtrl),
                  const SizedBox(height: 12),
                  _Field('Sponsor',       sponsorCtrl),
                  const SizedBox(height: 12),
                  _Field('Target Points', targetCtrl, numeric: true),
                  const SizedBox(height: 12),
                  _Field('Est. USD',      usdCtrl,     numeric: true),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
                  onPressed: () async {
                    final payload = {
                      'title': titleCtrl.text, 'emoji': emojiCtrl.text,
                      'sponsor': sponsorCtrl.text,
                      'target_points': int.tryParse(targetCtrl.text) ?? 10000000,
                      'estimated_usd': double.tryParse(usdCtrl.text) ?? 0,
                    };
                    if (existing == null) {
                      await _sb.from('community_projects').insert(payload);
                    } else {
                      await _sb.from('community_projects').update(payload).eq('id', existing['id']);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    _load();
                  },
                  child: const Text('Save', style: TextStyle(color: _kWhite)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _SectionHeader('Charity Projects', '🕌', 'Manage community projects.')),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, color: _kWhite, size: 16),
          label: const Text('Add', style: TextStyle(color: _kWhite, fontSize: 13)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          onPressed: _editDialog,
        ),
      ]),
      const SizedBox(height: 14),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAccent))
            : ListView.separated(
                itemCount: _projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final p = _projects[idx];
                  final isActive = p['is_active']    == true;
                  final isDone   = p['is_completed'] == true;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Title row
                      Row(children: [
                        Text(p['emoji'] ?? '🕌', style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p['title'] ?? '',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700, color: _kText))),
                        GestureDetector(
                            onTap: () => _editDialog(p),
                            child: const Icon(Icons.edit_rounded, size: 18, color: _kAccent)),
                        const SizedBox(width: 14),
                        GestureDetector(
                            onTap: () => _delete(p['id']),
                            child: const Icon(Icons.delete_rounded, size: 18, color: _kDanger)),
                      ]),
                      const SizedBox(height: 8),
                      // Stats chips
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        _ProjChip('Target', _fmt(p['target_points'])),
                        _ProjChip('USD', '\$${p['estimated_usd'] ?? 0}'),
                        if ((p['sponsor'] ?? '').isNotEmpty)
                          _ProjChip('Sponsor', p['sponsor']),
                      ]),
                      const SizedBox(height: 8),
                      // Toggle row
                      Row(children: [
                        Text('Active', style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
                        Switch(
                            value: isActive,
                            onChanged: (_) => _toggle(p['id'], isActive, 'is_active'),
                            activeThumbColor: _kAccent,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        const SizedBox(width: 10),
                        Text('Done', style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
                        Switch(
                            value: isDone,
                            onChanged: (_) => _toggle(p['id'], isDone, 'is_completed'),
                            activeThumbColor: _kGold,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    ]),
  );

  String _fmt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

class _ProjChip extends StatelessWidget {
  final String label, value;
  const _ProjChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _kAccent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('$label: $value',
        style: GoogleFonts.outfit(
            fontSize: 11, fontWeight: FontWeight.w600, color: _kAccent)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 4 — User Management
// ─────────────────────────────────────────────────────────────────────────────
class _UsersSection extends StatefulWidget {
  const _UsersSection();
  @override State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await _sb.from('profiles')
        .select('id, display_name, noor_points, total_xp, level, day_streak, country, created_at')
        .order('total_xp', ascending: false).limit(100);
    setState(() { _users = List.from(res); _loading = false; });
  }

  Future<void> _grantXp(String uid, String name) async {
    final ctrl = TextEditingController();
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Grant XP to $name'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount of XP')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
            child: const Text('Grant')),
      ],
    ));
    if (confirm == true && ctrl.text.isNotEmpty) {
      final amt = int.tryParse(ctrl.text) ?? 0;
      if (amt > 0) await _sb.rpc('earn_xp', params: {'p_user_id': uid, 'p_amount': amt});
      _load();
    }
  }

  List<Map<String, dynamic>> get _filtered => _search.isEmpty ? _users
      : _users.where((u) => (u['display_name'] ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      _SectionHeader('Users', '👥', 'Top 100 users by XP.'),
      const SizedBox(height: 10),
      // Full-width search field on its own row
      TextField(
        decoration: InputDecoration(
          hintText: 'Search name…',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          filled: true, fillColor: _kWhite,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
      const SizedBox(height: 14),
      // User card list
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAccent))
            : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, idx) {
                  final u = _filtered[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _kBorder),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
                    ),
                    child: Row(children: [
                      // Rank badge
                      Container(
                        width: 30, height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${idx + 1}',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w800, color: _kAccent)),
                      ),
                      const SizedBox(width: 10),
                      // Name + level
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u['display_name'] ?? 'Unknown',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
                        Text('Lv ${u['level'] ?? 1}',
                            style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
                      ])),
                      // XP pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4EBB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${u['total_xp'] ?? 0} XP',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B4EBB))),
                      ),
                      // Grant XP button
                      GestureDetector(
                        onTap: () => _grantXp(u['id'], u['display_name'] ?? ''),
                        child: const Icon(Icons.add_circle_rounded,
                            color: _kAccent, size: 26),
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 5 — Feature Flags
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureFlagsSection extends StatefulWidget {
  final String adminEmail;
  const _FeatureFlagsSection({required this.adminEmail});
  @override State<_FeatureFlagsSection> createState() => _FeatureFlagsSectionState();
}

class _FeatureFlagsSectionState extends State<_FeatureFlagsSection> {
  static const _flags = [
    (key: 'feature_leaderboard', label: 'Leaderboard Tab',    desc: 'Show rankings screen'),
    (key: 'feature_challenges',  label: 'Challenges System',  desc: 'Enable weekly/seasonal challenges'),
    (key: 'feature_badges',      label: 'Badges & Achievements', desc: 'Show badges/XP achievements'),
    (key: 'feature_tafsir',      label: 'Tafsir Screen',      desc: 'Enable Tafsir audio screen'),
    (key: 'feature_invite',      label: 'Friend Invites',     desc: 'Enable invite-a-friend flow'),
    (key: 'maintenance_mode',    label: 'Maintenance Mode 🔴', desc: 'Block all users from using app'),
  ];

  Future<void> _toggle(String key, bool current) async {
    await SettingsService.instance.updateKey(
        key, (!current).toString(), adminEmail: widget.adminEmail);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<SettingsService>().config;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader('Feature Flags', '🚩', 'Toggle features on/off for all users instantly.'),
        const SizedBox(height: 20),
        ..._flags.map((f) {
          final active = cfg.rawValue(f.key) == 'true';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _kWhite, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active && f.key == 'maintenance_mode'
                  ? _kDanger : _kBorder),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.label, style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                Text(f.desc,  style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
              ])),
              Switch(value: active, onChanged: (_) => _toggle(f.key, active),
                  activeThumbColor: f.key == 'maintenance_mode' ? _kDanger : _kAccent),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 6 — Banners & Messages
// ─────────────────────────────────────────────────────────────────────────────
class _BannersSection extends StatefulWidget {
  final String adminEmail;
  const _BannersSection({required this.adminEmail});
  @override State<_BannersSection> createState() => _BannersSectionState();
}

class _BannersSectionState extends State<_BannersSection> {
  late TextEditingController _textCtrl, _emailCtrl, _iosCtrl, _androidCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cfg = SettingsService.instance.config;
    _textCtrl    = TextEditingController(text: cfg.bannerText);
    _emailCtrl   = TextEditingController(text: cfg.supportEmail);
    _iosCtrl     = TextEditingController(text: cfg.appStoreUrl);
    _androidCtrl = TextEditingController(text: cfg.playStoreUrl);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await SettingsService.instance.updateKeys({
      'banner_text':   _textCtrl.text,
      'support_email': _emailCtrl.text,
      'app_store_url': _iosCtrl.text,
      'play_store_url': _androidCtrl.text,
    }, adminEmail: widget.adminEmail);
    if (mounted) { setState(() => _saving = false); _snack('Messages saved ✅'); }
  }

  Future<void> _toggleBanner(bool current) async =>
      SettingsService.instance.updateKey('banner_enabled', (!current).toString(),
          adminEmail: widget.adminEmail);

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: _kAccent));

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<SettingsService>().config;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader('Banners & Messages', '📢', 'Control in-app announcements and contact info.'),
        const SizedBox(height: 20),
        // Banner toggle
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Home Screen Banner', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
              Text('Shows an announcement strip below the points card', style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
            ])),
            Switch(value: cfg.bannerEnabled, onChanged: (_) => _toggleBanner(cfg.bannerEnabled), activeThumbColor: _kAccent),
          ]),
        ),
        const SizedBox(height: 16),
        _Field('Banner Text (shown to all users)', _textCtrl),
        const SizedBox(height: 16),
        _Field('Support Email', _emailCtrl),
        const SizedBox(height: 16),
        _Field('iOS App Store URL', _iosCtrl),
        const SizedBox(height: 16),
        _Field('Android Play Store URL', _androidCtrl),
        const SizedBox(height: 24),
        _SaveButton(saving: _saving, onTap: _save),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 7 — Raw Config (all rows, editable inline)
// ─────────────────────────────────────────────────────────────────────────────
class _RawConfigSection extends StatefulWidget {
  final String adminEmail;
  const _RawConfigSection({required this.adminEmail});
  @override State<_RawConfigSection> createState() => _RawConfigSectionState();
}

class _RawConfigSectionState extends State<_RawConfigSection> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _editingKey;
  final _editCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await _sb.from('app_config')
        .select('key, value, description, category, updated_at, updated_by')
        .order('category').order('key');
    setState(() { _rows = List.from(res); _loading = false; });
  }

  Future<void> _save(String key) async {
    await SettingsService.instance.updateKey(key, _editCtrl.text.trim(),
        adminEmail: widget.adminEmail);
    setState(() => _editingKey = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in _rows) {
      final cat = r['category'] as String? ?? 'general';
      (grouped[cat] ??= []).add(r);
    }
    return _loading
        ? const Center(child: CircularProgressIndicator(color: _kAccent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHeader('All Config Keys', '⚙️', 'Click the edit icon to change any value directly.'),
              const SizedBox(height: 20),
              ...grouped.entries.map((e) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(bottom: 8, top: 12),
                    child: Text(e.key.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800,
                            color: _kAccent, letterSpacing: 1.2))),
                Container(
                  decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                  child: Column(children: e.value.asMap().entries.map((me) {
                    final i = me.key; final r = me.value;
                    final key = r['key'] as String;
                    final isEditing = _editingKey == key;
                    if (isEditing) _editCtrl.text = r['value'] ?? '';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: i < e.value.length - 1
                            ? const Border(bottom: BorderSide(color: _kBorder)) : null,
                        color: isEditing ? _kAccent.withValues(alpha: 0.04) : null,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Key row: name + edit icon
                        Row(children: [
                          Expanded(child: Text(key,
                              style: GoogleFonts.outfit(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: _kText))),
                          if (!isEditing)
                            GestureDetector(
                              onTap: () => setState(() => _editingKey = key),
                              child: const Icon(Icons.edit_outlined, size: 15, color: _kSub),
                            ),
                        ]),
                        // Description
                        if ((r['description'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(r['description'] ?? '',
                                style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
                          ),
                        // Value / edit field
                        if (isEditing)
                          Row(children: [
                            Expanded(child: TextField(
                              controller: _editCtrl, autofocus: true,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onSubmitted: (_) => _save(key),
                            )),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _save(key),
                              child: const Icon(Icons.check_rounded, color: _kAccent, size: 22)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _editingKey = null),
                              child: const Icon(Icons.close_rounded, color: _kDanger, size: 22)),
                          ])
                        else
                          Row(children: [
                            Flexible(child: Text(r['value'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: _kAccent))),
                            const Spacer(),
                            Text(_fmtDate(r['updated_at']),
                                style: GoogleFonts.outfit(fontSize: 10, color: _kSub)),
                          ]),
                      ]),
                    );
                  }).toList()),
                ),
              ])),
            ]),
          );
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts as String);
    if (dt == null) return '';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, emoji, desc;
  const _SectionHeader(this.title, this.emoji, this.desc);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
      ),
    ]),
    const SizedBox(height: 4),
    Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
  ]);
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _NumField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
    const SizedBox(height: 6),
    TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true, fillColor: _kWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kAccent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  ]);
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool numeric;
  const _Field(this.label, this.controller, {this.numeric = false});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
    const SizedBox(height: 6),
    TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        filled: true, fillColor: _kWhite, isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kAccent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  ]);
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  const _SaveButton({required this.saving, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: ElevatedButton(
      onPressed: saving ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kAccent, elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: saving
          ? const SizedBox(height: 18, width: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Save Changes', style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
    ),
  );
}
