// lib/screens/profile_settings_screen.dart
//
// ProfileSettingsScreen — full profile & settings page
// • Display name editable
// • Email (read-only from auth)
// • Country editable
// • Avatar: real photo upload via image_picker → Supabase Storage
// • Help & Support section
// • Sign Out
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_name_notifier.dart';
import 'package:provider/provider.dart';
import '../features/auth/data/qf_auth_service.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../theme/y4_theme.dart';
import '../widgets/noor_offline.dart';
import '../widgets/notifications_sheet.dart';
import '../services/notification_center.dart';
import '../l10n/app_localizations.dart';

AppConfig get _pcfg => SettingsService.instance.config;
Color get _pTeal => _pcfg.dashTeal;
Color get _pText => _pcfg.dashText;
Color get _pBg => _pcfg.dashBg;
Color get _pSub =>
    _pcfg.dashBg.computeLuminance() > 0.5
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);
Color get _pPurple => _pcfg.secondaryColor;

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});
  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _supabase = Supabase.instance.client;

  // ── State ────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String _displayName = '';
  String _email = '';
  String _country = '';
  String _provider = 'email'; // 'email' | 'google' | 'quran_com'
  int _level = 1;
  String _levelTitle = 'Seeker';
  String? _avatarUrl;

  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // ── Detect sign-in provider ──────────────────────────────────────────────
    // Google sets appMetadata.provider = 'google'
    // QF sets userMetadata.provider = 'quran_com' (we write this after userinfo)
    final appProvider = user.appMetadata['provider'] as String? ?? '';
    final userProvider = user.userMetadata?['provider'] as String? ?? '';
    if (userProvider == 'quran_com') {
      _provider = 'quran_com';
      // For QF users the real email lives in user metadata (not user.email)
      _email = (user.userMetadata?['qf_email'] as String?) ?? '';
    } else if (appProvider == 'google') {
      _provider = 'google';
      _email = user.email ?? '';
    } else {
      _provider = 'email';
      _email = user.email ?? '';
    }

    try {
      final profile =
          await _supabase
              .from('profiles')
              .select('display_name, country, level, avatar_url, email')
              .eq('id', user.id)
              .maybeSingle();

      _displayName = (profile?['display_name'] as String?) ?? '';
      _country = (profile?['country'] as String?) ?? '';
      _level = (profile?['level'] as num?)?.toInt() ?? 1;
      _avatarUrl = profile?['avatar_url'] as String?;

      // For QF users: qf_email in userMetadata may be empty if the QF server
      // only grants openid scope. Fall back to profiles.email which is always
      // populated from the AuthGate email upsert.
      if (_provider == 'quran_com' && _email.isEmpty) {
        _email = (profile?['email'] as String?) ?? '';
      }

      final lvlRow =
          await _supabase
              .from('xp_levels')
              .select('title')
              .eq('level', _level)
              .maybeSingle();
      _levelTitle = (lvlRow?['title'] as String?) ?? _fallbackTitle(_level);

      _nameCtrl.text = _displayName;
      _countryCtrl.text = _country;
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  String _fallbackTitle(int lv) {
    if (lv >= 51) return 'Legend';
    if (lv >= 21) return 'Champion';
    if (lv >= 11) return 'Devoted';
    if (lv >= 6) return 'Believer';
    return 'Seeker';
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final country = _countryCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Name cannot be empty', isError: true);
      return;
    }

    setState(() => _saving = true);
    final l = AppLocalizations.of(context)!;
    try {
      // Try the safe SECURITY DEFINER RPC first (no risk of users editing
      // sensitive columns like noor_points). If the RPC isn't deployed
      // yet (older DB) or fails for any reason, fall back to a direct
      // update on the row — protected by the existing RLS auth.uid()
      // policy. Either path requires only display_name + country.
      try {
        await _supabase.rpc('update_my_profile', params: {
          'p_display_name': name,
          'p_country': country,
        });
      } on PostgrestException catch (rpcErr) {
        debugPrint('[Profile] update_my_profile RPC failed: ${rpcErr.code} ${rpcErr.message} — falling back to direct update');
        // Fallback: direct update gated by RLS (id = auth.uid()).
        await _supabase
            .from('profiles')
            .update({'display_name': name, 'country': country})
            .eq('id', user.id);
      }
      await _supabase.auth.updateUser(
        UserAttributes(data: {'noor_name': name}),
      );
      // Broadcast to the rest of the app instantly. Even if the auth
      // stream's userUpdated event is missed for any reason, every
      // listener (AuthGate → Dashboard greeting / Profile tab / etc.)
      // will see the new name within one frame.
      ProfileNameNotifier.instance.set(name);
      _displayName = name;
      _country = country;
      _showSnack(l.profileUpdated);
      HapticFeedback.lightImpact();
    } catch (e) {
      // Surface the actual error so the user can report what's wrong.
      final detail = e is PostgrestException
          ? '${e.code ?? ''} ${e.message}'.trim()
          : e.toString();
      debugPrint('[Profile] _saveProfile error: $detail');
      _showSnack('${l.couldNotSave}: $detail', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── Photo Upload ─────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    final l = AppLocalizations.of(context)!;
    try {
      final xf = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (xf == null) return;

      setState(() => _uploadingPhoto = true);

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bytes = await File(xf.path).readAsBytes();
      final ext = xf.name.split('.').last.toLowerCase();
      final mimeType =
          ext == 'png'
              ? 'image/png'
              : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final filePath = '${user.id}/avatar.$ext';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final url = _supabase.storage.from('avatars').getPublicUrl(filePath);
      // Bust cache by appending timestamp
      final bustUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('profiles')
          .update({'avatar_url': bustUrl})
          .eq('id', user.id);

      setState(() => _avatarUrl = bustUrl);
      _showSnack(l.photoUpdated);
      HapticFeedback.lightImpact();
    } catch (e) {
      _showSnack(l.couldNotUploadPhoto, isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Y4.palette.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.changeProfilePhoto,
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _pText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _photoOption(
                    Icons.camera_alt_rounded,
                    l.takeAPhoto,
                    _pTeal,
                    () => _pickAndUploadPhoto(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),
                  _photoOption(
                    Icons.photo_library_rounded,
                    l.chooseFromLibrary,
                    Y4.palette.primaryDeep,
                    () => _pickAndUploadPhoto(ImageSource.gallery),
                  ),
                  if (_avatarUrl != null) ...[
                    const SizedBox(height: 12),
                    _photoOption(
                      Icons.delete_outline_rounded,
                      l.removePhoto,
                      const Color(0xFFD32F2F),
                      _removePhoto,
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _photoOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _removePhoto() async {
    Navigator.pop(context);
    final l = AppLocalizations.of(context)!;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      await _supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);
      setState(() => _avatarUrl = null);
      _showSnack(l.photoRemoved);
    } catch (_) {
      _showSnack(l.couldNotRemovePhoto, isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Snack ─────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : _pTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              l.signOutQuestion,
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            content: Text(
              l.progressSafelyStored,
              style: GoogleFonts.outfit(fontSize: 14, color: _pSub),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel, style: GoogleFonts.outfit(color: _pSub)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l.signOut,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await QfAuthService.performSignOut(_supabase);
      // Pop all pushed routes so AuthGate surfaces and shows the login screen.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _pBg,
      body:
          _loading
              ? const Center(child: NoorInlineLoader(height: 120))
              : CustomScrollView(
                slivers: [
                  _buildAppBar(l),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildAvatarCard(l),
                          const SizedBox(height: 28),
                          _sectionLabel(l.accountInformation),
                          const SizedBox(height: 12),
                          _buildInfoCard(l),
                          const SizedBox(height: 28),
                          _sectionLabel(l.preferences),
                          const SizedBox(height: 12),
                          _buildNotificationsCard(l),
                          const SizedBox(height: 28),
                          _sectionLabel(
                            AppLocalizations.of(context)?.pointsGoals ??
                                'POINTS GOALS',
                          ),
                          const SizedBox(height: 12),
                          _buildGoalsCard(l),
                          const SizedBox(height: 28),
                          _sectionLabel(l.helpAndSupport),
                          const SizedBox(height: 12),
                          _buildSupportCard(l),
                          const SizedBox(height: 28),
                          _buildSignOutButton(l),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              l?.profileSettingsScreen_sabiqRewards ?? 'Sabiq Rewards • v1.0',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFFB0A898),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // ── App Bar ─ honey wash hero matching dashboard ─────────────────────────
  SliverAppBar _buildAppBar(AppLocalizations l) => SliverAppBar(
    pinned: true,
    expandedHeight: 180,
    backgroundColor: Y4.palette.background,
    surfaceTintColor: Y4.palette.background,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Y4.ink,
        size: 20,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    actions: [
      if (_saving)
        const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9921A)),
            ),
          ),
        )
      else
        TextButton(
          onPressed: _saveProfile,
          child: Text(
            l.save,
            style: GoogleFonts.outfit(
              color: Y4.palette.honeyDeep,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Y4.palette.cream, Y4.palette.honey.withValues(alpha: 0.30), Y4.palette.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
            child: Row(
              children: [
                _bigAvatarCircle(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _displayName.isNotEmpty ? _displayName : l.yourName,
                        style: Y4.display(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Y4.palette.ink,
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Y4.palette.inkSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _badgePill('LV $_level', Y4.palette.primaryDeep),
                          const SizedBox(width: 6),
                          _badgePill(_levelTitle, Y4.palette.honeyDeep),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // ── Avatar helpers ──────────────────────────────────────────────────────
  Widget _bigAvatarCircle() {
    final initial =
        _displayName.isNotEmpty
            ? _displayName[0].toUpperCase()
            : _email.isNotEmpty
            ? _email[0].toUpperCase()
            : 'N';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Y4.honey, Y4.honeyDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Y4.palette.honeyDeep.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            image:
                _avatarUrl != null
                    ? DecorationImage(
                      image: NetworkImage(_avatarUrl!),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              _avatarUrl == null
                  ? Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                  : null,
        ),
        if (_uploadingPhoto)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black38,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFC9921A),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_avatarUrl != null && !_uploadingPhoto)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _removePhoto,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarCircle({double radius = 36, double fontSize = 24}) {
    final initial =
        _displayName.isNotEmpty
            ? _displayName[0].toUpperCase()
            : _email.isNotEmpty
            ? _email[0].toUpperCase()
            : 'N';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Y4.honey, Y4.honeyDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Y4.palette.honeyDeep.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            image:
                _avatarUrl != null
                    ? DecorationImage(
                      image: NetworkImage(_avatarUrl!),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              _avatarUrl == null
                  ? Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.outfit(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                  : null,
        ),
        if (_uploadingPhoto)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black38,
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFC9921A),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_avatarUrl != null && !_uploadingPhoto)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _removePhoto,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _badgePill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: GoogleFonts.rajdhani(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
  );

  /// Small pill showing which provider the user signed in with.
  Widget _providerBadge() {
    switch (_provider) {
      case 'google':
        return _badgePillWithIcon(
          'Google',
          const Color(0xFF4285F4),
          icon: Icons.g_mobiledata_rounded,
        );
      case 'quran_com':
        return _badgePillWithIcon(
          'Quran.com',
          const Color(0xFF00C875),
          icon: Icons.menu_book_rounded,
        );
      default:
        return _badgePillWithIcon(
          'Email',
          const Color(0xFFFFAA00),
          icon: Icons.email_outlined,
        );
    }
  }

  Widget _badgePillWithIcon(
    String label,
    Color color, {
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  // ── Avatar Card ───────────────────────────────────────────────────────────
  Widget _buildAvatarCard(AppLocalizations l) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Y4.palette.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        _avatarCircle(radius: 36, fontSize: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.profilePhoto,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _pText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _avatarUrl != null ? l.tapEditToChange : l.tapEditToAdd,
                style: GoogleFonts.outfit(fontSize: 12, color: _pSub),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showPhotoSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _pTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pTeal.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Color(0xFF2BAE99),
                ),
                const SizedBox(width: 5),
                Text(
                  l.edit,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _pTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Info Card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard(AppLocalizations l) => Container(
    decoration: BoxDecoration(
      color: Y4.palette.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _editableRow(
          icon: Icons.person_outline_rounded,
          label: l.displayName,
          controller: _nameCtrl,
          hint: l.yourName,
        ),
        _divider(),
        _readOnlyRow(icon: Icons.email_outlined, label: l.email, value: _email),
        _divider(),
        // Connected account row — shows provider with icon
        _connectedAccountRow(l),
        _divider(),
        _countryRow(l),
      ],
    ),
  );

  Widget _editableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) => Padding(
    // Flat inline row — the field text sits directly under the label,
    // matching the read-only rows. (Removed the nested honey box that
    // produced a "container inside a container" look.)
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Y4.palette.honey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Y4.palette.honeyDeep, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _pSub,
                ),
              ),
              const SizedBox(height: 2),
              TextField(
                controller: controller,
                focusNode: _nameFocus,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _pText,
                ),
                cursorColor: Y4.palette.honeyDeep,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB0A898),
                  ),
                  // filled:false overrides the global InputDecorationTheme
                  // (filled:true + cream fill) which otherwise paints a
                  // box behind the field — the "extra container".
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        // "Edit" pill — same style as the "Verified" badge on the email
        // row. Tapping it focuses the field.
        GestureDetector(
          onTap: () => _nameFocus.requestFocus(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Y4.palette.honey.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_rounded,
                  size: 11,
                  color: Y4.honeyDeep,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)?.editLabel ?? 'Edit',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Y4.palette.honeyDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Country list (alphabetical) ───────────────────────────────────────────
  static const List<String> _kCountries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina',
    'Armenia', 'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain',
    'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin',
    'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil',
    'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon',
    'Canada', 'Cape Verde', 'Central African Republic', 'Chad', 'Chile',
    'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba',
    'Cyprus', 'Czechia', 'Denmark', 'Djibouti', 'Dominica',
    'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador',
    'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji',
    'Finland', 'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana',
    'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
    'Haiti', 'Honduras', 'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran',
    'Iraq', 'Ireland', 'Israel', 'Italy', 'Ivory Coast', 'Jamaica', 'Japan',
    'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Kosovo', 'Kuwait',
    'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya',
    'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi',
    'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania',
    'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia',
    'Montenegro', 'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru',
    'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria',
    'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau',
    'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru',
    'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia',
    'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia',
    'Saint Vincent and the Grenadines', 'Samoa', 'San Marino',
    'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia',
    'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia',
    'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'South Sudan',
    'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland',
    'Syria', 'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste',
    'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey',
    'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu',
    'Vatican City', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
  ];

  // ── Country selector row — opens a searchable picker bottom sheet ─────────
  Widget _countryRow(AppLocalizations l) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _showCountryPicker,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Y4.palette.honey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.public_rounded,
                color: Y4.honeyDeep,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.country,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _pSub,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _countryCtrl.text.isNotEmpty
                        ? _countryCtrl.text
                        : l.countryHint,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _countryCtrl.text.isNotEmpty
                          ? _pText
                          : const Color(0xFFB0A898),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.unfold_more_rounded, size: 18, color: _pSub),
          ],
        ),
      ),
    ),
  );

  void _showCountryPicker() {
    var query = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final filtered = _kCountries
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(sheetCtx).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DCD2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Text(
                      'Select Country',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _pText,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      cursorColor: Y4.palette.honeyDeep,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: _pText,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)?.searchHint ??
                                'Search…',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFFB0A898),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFB0A898),
                        ),
                        filled: true,
                        fillColor: Y4.palette.background,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setSheet(() => query = v),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No match',
                              style: GoogleFonts.outfit(color: _pSub),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              final selected = c == _countryCtrl.text;
                              return ListTile(
                                title: Text(
                                  c,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _pText,
                                  ),
                                ),
                                trailing: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Y4.honeyDeep,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() => _countryCtrl.text = c);
                                  Navigator.pop(sheetCtx);
                                },
                              );
                            },
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

  Widget _readOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _pSub.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _pSub, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _pSub,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '\u2014',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _pText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _pSub.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l.verified,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _pSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 0,
    indent: 66,
    endIndent: 16,
    color: Color(0xFFF0EDE8),
  );

  /// Row in the info card showing how the user signed in.
  Widget _connectedAccountRow(AppLocalizations l) {
    final IconData icon;
    final String sub;
    final Color color;
    switch (_provider) {
      case 'google':
        icon = Icons.g_mobiledata_rounded;
        sub = 'Signed in with Google';
        color = const Color(0xFF4285F4);
        break;
      case 'quran_com':
        icon = Icons.menu_book_rounded;
        sub = 'Signed in with Quran.com';
        color = const Color(0xFF00C875);
        break;
      default:
        icon = Icons.email_outlined;
        sub = 'Signed in with Email';
        color = const Color(0xFFFFAA00);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.connectedAccount,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _pSub,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _pText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              l.active,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notifications Card ────────────────────────────────────────────────────
  // Master on/off + a shortcut to view the inbox. Lives under "Preferences"
  // so it sits naturally between account info and help/support.
  Widget _buildNotificationsCard(AppLocalizations l) => Container(
    decoration: BoxDecoration(
      color: Y4.palette.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        // Master toggle row
        ValueListenableBuilder<bool>(
          valueListenable: NotificationCenter.instance.enabled,
          builder:
              (_, on, __) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Y4.butter, Y4.honey],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Y4.palette.honeyDeep.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        on
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 20,
                        color: Y4.palette.honeyDeep,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.notifications,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Y4.palette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            on ? l.notifOnDesc : l.notifOffDesc,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Y4.palette.inkSoft,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: on,
                      onChanged: NotificationCenter.instance.setEnabled,
                      activeThumbColor: Y4.palette.honey,
                      activeTrackColor: Y4.palette.honeyDeep,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Y4.palette.track,
                    ),
                  ],
                ),
              ),
        ),
        // View inbox row
        const Divider(height: 1, thickness: 1, color: Y4.border),
        InkWell(
          onTap: () => showNotificationsSheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.inbox_rounded, size: 20, color: Y4.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l.viewNotificationsInbox,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Y4.palette.ink,
                    ),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: NotificationCenter.instance.unreadCount,
                  builder:
                      (_, n, __) =>
                          n == 0
                              ? const SizedBox.shrink()
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Y4.palette.honeyDeep,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$n new',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Y4.muted,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Y4.border),
        // Language Option
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, size: 20, color: Y4.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.languageLabel ?? 'Language',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Y4.palette.ink,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: context.watch<SettingsService>().localeCode ?? 'system',
                underline: const SizedBox.shrink(),
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Y4.muted,
                ),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Y4.palette.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                alignment: Alignment.centerRight,
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(
                      AppLocalizations.of(context)?.systemDefault ??
                          'System Default',
                    ),
                  ),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'ur', child: Text('اردو')),
                  DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'ms', child: Text('Bahasa Melayu')),
                  DropdownMenuItem(
                    value: 'id',
                    child: Text('Bahasa Indonesia'),
                  ),
                  DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                ],
                onChanged: (val) {
                  final code = val == 'system' ? null : val;
                  context.read<SettingsService>().setLocaleOverride(code);
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Goals Card ───────────────────────────────────────────────────────────
  Widget _buildGoalsCard(AppLocalizations l) {
    final ss = context.watch<SettingsService>();
    return Container(
      decoration: BoxDecoration(
        color: Y4.palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _goalRow(
            icon: Icons.wb_sunny_rounded,
            label: AppLocalizations.of(context)?.dailyGoal ?? 'Daily Goal',
            value: '${ss.dayGoal} Seeds',
            color: const Color(0xFF00897B),
            isFirst: true,
            onTap: () => _showGoalEditor(
              title: AppLocalizations.of(context)?.dailyGoal ?? 'Daily Goal',
              current: ss.dayGoal,
              defaultVal: SettingsService.defaultDayGoal,
              onSave: (v) => ss.setGoals(day: v),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Y4.border),
          _goalRow(
            icon: Icons.date_range_rounded,
            label: AppLocalizations.of(context)?.weeklyGoal ?? 'Weekly Goal',
            value: '${ss.weekGoal} Seeds',
            color: const Color(0xFF5C6BC0),
            onTap: () => _showGoalEditor(
              title: AppLocalizations.of(context)?.weeklyGoal ?? 'Weekly Goal',
              current: ss.weekGoal,
              defaultVal: SettingsService.defaultWeekGoal,
              onSave: (v) => ss.setGoals(week: v),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Y4.border),
          _goalRow(
            icon: Icons.calendar_month_rounded,
            label: AppLocalizations.of(context)?.monthlyGoal ?? 'Monthly Goal',
            value: '${ss.monthGoal} Seeds',
            color: const Color(0xFFE91E8C),
            isLast: true,
            onTap: () => _showGoalEditor(
              title:
                  AppLocalizations.of(context)?.monthlyGoal ?? 'Monthly Goal',
              current: ss.monthGoal,
              defaultVal: SettingsService.defaultMonthGoal,
              onSave: (v) => ss.setGoals(month: v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.vertical(
      top: isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: isLast ? const Radius.circular(20) : Radius.zero,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _pText,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pSub,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB0A898),
            size: 20,
          ),
        ],
      ),
    ),
  );

  void _showGoalEditor({
    required String title,
    required int current,
    required int defaultVal,
    required ValueChanged<int> onSave,
  }) {
    final ctrl = TextEditingController(text: current.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: BoxDecoration(
            color: Y4.palette.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _pText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)?.setTargetSeeds(defaultVal) ??
                      'Set your target Seeds (default: $defaultVal)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _pSub,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Y4.palette.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Y4.palette.honey.withValues(alpha: 0.5),
                    ),
                  ),
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _pText,
                    ),
                    cursorColor: Y4.palette.honeyDeep,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ctrl.text = defaultVal.toString();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _pSub.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _pSub.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Reset',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _pSub,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final val = int.tryParse(ctrl.text.trim());
                          if (val != null && val > 0) {
                            onSave(val);
                            Navigator.pop(ctx);
                            _showSnack('Goal updated');
                            HapticFeedback.lightImpact();
                          } else {
                            _showSnack(
                              'Enter a valid number',
                              isError: true,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Y4.honey, Y4.honeyDeep],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'Save',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Support Card ──────────────────────────────────────────────────────────
  Widget _buildSupportCard(AppLocalizations l) => Container(
    decoration: BoxDecoration(
      color: Y4.palette.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _supportRow(
          Icons.help_outline_rounded,
          l.helpCenter,
          'Guides, FAQs and how-tos',
          const Color(0xFF3B82F6),
          isFirst: true,
          onTap: () => _showHelpSheet(),
        ),
        _divider(),
        _supportRow(
          Icons.bug_report_outlined,
          l.reportABug,
          'Something not working? Tell us',
          const Color(0xFFEF4444),
          onTap: () => _showReportSheet(),
        ),
        _divider(),
        _supportRow(
          Icons.info_outline_rounded,
          l.aboutNoorRewards,
          'Version 1.0 • ${l.builtWithLove}',
          const Color(0xFFFFAA00),
          onTap: () => _showAboutSheet(),
        ),
        _divider(),
        _supportRow(
          Icons.privacy_tip_outlined,
          l.privacyPolicy,
          l.howWeProtectData,
          _pSub,
          isLast: true,
          onTap: () {},
        ),
      ],
    ),
  );

  Widget _supportRow(
    IconData icon,
    String title,
    String sub,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.vertical(
      top: isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: isLast ? const Radius.circular(20) : Radius.zero,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _pText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.outfit(fontSize: 11, color: _pSub),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB0A898),
            size: 20,
          ),
        ],
      ),
    ),
  );

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Widget _buildSignOutButton(AppLocalizations l) => GestureDetector(
    onTap: _signOut,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Y4.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECEC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 10),
          Text(
            l.signOut,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _pSub,
      letterSpacing: 1,
    ),
  );

  // ── Help Sheet ────────────────────────────────────────────────────────────
  void _showHelpSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _BottomSheetCard(
            title: l.helpCenter,
            icon: Icons.help_outline_rounded,
            color: const Color(0xFF3B82F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _helpItem(l.howToEarnQuestion, l.howToEarnAnswer),
                _helpItem(l.whatIsValidateQuestion, l.whatIsValidateAnswer),
                _helpItem(l.howStreaksWorkQuestion, l.howStreaksWorkAnswer),
                _helpItem(l.canDonatQuestion, l.canDonateAnswer),
              ],
            ),
          ),
    );
  }

  Widget _helpItem(String q, String a) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _pText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          a,
          style: GoogleFonts.outfit(fontSize: 13, color: _pSub, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFFF0EDE8), height: 0),
      ],
    ),
  );

  // ── Report Sheet ──────────────────────────────────────────────────────────
  void _showReportSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _BottomSheetCard(
            title: l.reportABug,
            icon: Icons.bug_report_outlined,
            color: const Color(0xFFEF4444),
            child: Column(
              children: [
                Text(
                  l.bugReportBody,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: _pSub,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'support@noorapp.co',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // ── About Sheet ───────────────────────────────────────────────────────────
  void _showAboutSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _BottomSheetCard(
            title: l.aboutNoorRewards,
            icon: Icons.info_outline_rounded,
            color: const Color(0xFFFFAA00),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFEE88), Color(0xFFFFAA00)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'N',
                      style: GoogleFonts.rajdhani(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.noorRewards,
                  style: GoogleFonts.rajdhani(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _pText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.outfit(fontSize: 13, color: _pSub),
                ),
                const SizedBox(height: 16),
                Text(
                  l.aboutBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _pSub,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ── Reusable bottom sheet wrapper ─────────────────────────────────────────────
class _BottomSheetCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _BottomSheetCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsService>();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Y4.palette.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _pText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
