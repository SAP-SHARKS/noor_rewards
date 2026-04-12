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

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});
  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _supabase = Supabase.instance.client;

  // ── State ────────────────────────────────────────────────────────────────
  bool   _loading      = true;
  bool   _saving       = false;
  bool   _uploadingPhoto = false;
  String _displayName  = '';
  String _email        = '';
  String _country      = '';
  int    _level        = 1;
  String _levelTitle   = 'Seeker';
  String? _avatarUrl;

  final _nameCtrl    = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _picker      = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    _email = user.email ?? '';

    try {
      final profile = await _supabase
          .from('profiles')
          .select('display_name, country, level, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      _displayName = (profile?['display_name'] as String?) ?? '';
      _country     = (profile?['country']      as String?) ?? '';
      _level       = (profile?['level']        as num?)?.toInt() ?? 1;
      _avatarUrl   = profile?['avatar_url']    as String?;

      final lvlRow = await _supabase
          .from('xp_levels')
          .select('title')
          .eq('level', _level)
          .maybeSingle();
      _levelTitle = (lvlRow?['title'] as String?) ?? _fallbackTitle(_level);

      _nameCtrl.text    = _displayName;
      _countryCtrl.text = _country;
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  String _fallbackTitle(int lv) {
    if (lv >= 51) return 'Legend';
    if (lv >= 21) return 'Champion';
    if (lv >= 11) return 'Devoted';
    if (lv >= 6)  return 'Believer';
    return 'Seeker';
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final name    = _nameCtrl.text.trim();
    final country = _countryCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Name cannot be empty', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _supabase.from('profiles').upsert({
        'id':           user.id,
        'display_name': name,
        'country':      country,
      });
      await _supabase.auth.updateUser(
        UserAttributes(data: {'noor_name': name}),
      );
      _displayName = name;
      _country     = country;
      _showSnack('Profile updated ✓');
      HapticFeedback.lightImpact();
    } catch (e) {
      _showSnack('Could not save — please try again', isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── Photo Upload ─────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
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

      final bytes    = await File(xf.path).readAsBytes();
      final ext      = xf.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final filePath = '${user.id}/avatar.$ext';

      await _supabase.storage.from('avatars').uploadBinary(
        filePath, bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );

      final url = _supabase.storage.from('avatars').getPublicUrl(filePath);
      // Bust cache by appending timestamp
      final bustUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('profiles').update({'avatar_url': bustUrl}).eq('id', user.id);

      setState(() => _avatarUrl = bustUrl);
      _showSnack('Photo updated ✓');
      HapticFeedback.lightImpact();
    } catch (e) {
      _showSnack('Could not upload photo — please try again', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Change Profile Photo',
              style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
          const SizedBox(height: 20),
          _photoOption(Icons.camera_alt_rounded, 'Take a Photo', const Color(0xFF2BAE99),
              () => _pickAndUploadPhoto(ImageSource.camera)),
          const SizedBox(height: 12),
          _photoOption(Icons.photo_library_rounded, 'Choose from Library', const Color(0xFF5856D6),
              () => _pickAndUploadPhoto(ImageSource.gallery)),
          if (_avatarUrl != null) ...[
            const SizedBox(height: 12),
            _photoOption(Icons.delete_outline_rounded, 'Remove Photo', const Color(0xFFD32F2F),
                _removePhoto),
          ],
        ])),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );

  Future<void> _removePhoto() async {
    Navigator.pop(context);
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      await _supabase.from('profiles').update({'avatar_url': null}).eq('id', user.id);
      setState(() => _avatarUrl = null);
      _showSnack('Photo removed');
    } catch (_) {
      _showSnack('Could not remove photo', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Snack ─────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2BAE99),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 22)),
        content: Text('Your progress is safely stored. You can sign back in anytime.',
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF8E8E93))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF8E8E93)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Sign Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) await _supabase.auth.signOut();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2BAE99)))
          : CustomScrollView(slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildAvatarCard(),
                      const SizedBox(height: 28),
                      _sectionLabel('Account Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard(),
                      const SizedBox(height: 28),
                      _sectionLabel('Help & Support'),
                      const SizedBox(height: 12),
                      _buildSupportCard(),
                      const SizedBox(height: 28),
                      _buildSignOutButton(),
                      const SizedBox(height: 16),
                      Center(
                        child: Text('Noor Rewards • v1.0',
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFB0A898))),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() => SliverAppBar(
        pinned: true,
        expandedHeight: 180,
        backgroundColor: const Color(0xFF0A2318),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Color(0xFF2BAE99), strokeWidth: 2.5)),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: GoogleFonts.outfit(
                  color: const Color(0xFF2BAE99), fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A2318), Color(0xFF133828), Color(0xFF1A4731)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Row(children: [
                  _bigAvatarCircle(),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_displayName.isNotEmpty ? _displayName : 'Your Name',
                          style: GoogleFonts.rajdhani(
                            fontSize: 24, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 0.5,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(_email,
                          style: GoogleFonts.outfit(fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        _badgePill('LV $_level', const Color(0xFF5856D6)),
                        const SizedBox(width: 6),
                        _badgePill(_levelTitle, const Color(0xFF2BAE99)),
                      ]),
                    ],
                  )),
                ]),
              ),
            ),
          ),
        ),
      );

  // ── Avatar helpers ──────────────────────────────────────────────────────
  Widget _bigAvatarCircle() {
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase()
        : _email.isNotEmpty ? _email[0].toUpperCase() : 'N';
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          boxShadow: [BoxShadow(
            color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
            blurRadius: 16, offset: const Offset(0, 4),
          )],
          image: _avatarUrl != null
              ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: _avatarUrl == null
          ? Center(child: Text(initial,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)))
          : null,
      ),
      if (_uploadingPhoto)
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
          child: const Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
        )),
      if (_avatarUrl != null && !_uploadingPhoto)
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: _removePhoto,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
    ]);
  }

  Widget _avatarCircle({double radius = 36, double fontSize = 24}) {
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase()
        : _email.isNotEmpty ? _email[0].toUpperCase() : 'N';
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: radius * 2, height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          boxShadow: [BoxShadow(
            color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
            blurRadius: 16, offset: const Offset(0, 4),
          )],
          image: _avatarUrl != null
              ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: _avatarUrl == null
          ? Center(child: Text(initial,
              style: GoogleFonts.outfit(fontSize: fontSize, fontWeight: FontWeight.w800, color: Colors.white)))
          : null,
      ),
      if (_uploadingPhoto)
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
          child: const Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
        )),
      if (_avatarUrl != null && !_uploadingPhoto)
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: _removePhoto,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.close_rounded, size: radius * 0.4, color: Colors.white),
            ),
          ),
        ),
    ]);
  }

  Widget _badgePill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label, style: GoogleFonts.rajdhani(
        fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
  );

  // ── Avatar Card ───────────────────────────────────────────────────────────
  Widget _buildAvatarCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12, offset: const Offset(0, 4),
      )],
    ),
    child: Row(children: [
      _avatarCircle(radius: 36, fontSize: 24),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile Photo', style: GoogleFonts.outfit(
              fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
          const SizedBox(height: 3),
          Text(_avatarUrl != null ? 'Tap Edit to change your photo' : 'Tap Edit to add a photo',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8E8E93))),
        ],
      )),
      GestureDetector(
        onTap: _showPhotoSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2BAE99).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2BAE99).withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF2BAE99)),
            const SizedBox(width: 5),
            Text('Edit', style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2BAE99))),
          ]),
        ),
      ),
    ]),
  );

  // ── Info Card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12, offset: const Offset(0, 4),
      )],
    ),
    child: Column(children: [
      _editableRow(
        icon: Icons.person_outline_rounded,
        label: 'Display Name',
        controller: _nameCtrl,
        hint: 'Your name',
        isFirst: true,
      ),
      _divider(),
      _readOnlyRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: _email,
      ),
      _divider(),
      _editableRow(
        icon: Icons.public_rounded,
        label: 'Country',
        controller: _countryCtrl,
        hint: 'e.g. Pakistan, UK…',
        isLast: true,
      ),
    ]),
  );

  Widget _editableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isFirst = false,
    bool isLast = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2BAE99).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2BAE99), size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.outfit(
            fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8E8E93))),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1C1E)),
          cursorColor: const Color(0xFF2BAE99),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFFB0A898)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
        ),
      ])),
      const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFB0A898)),
    ]),
  );

  Widget _readOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF8E8E93).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF8E8E93), size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.outfit(
            fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8E8E93))),
        const SizedBox(height: 2),
        Text(value.isNotEmpty ? value : '\u2014', style: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1C1C1E)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF8E8E93).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Verified', style: GoogleFonts.outfit(
            fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8E8E93))),
      ),
    ]),
  );

  Widget _divider() => const Divider(height: 0, indent: 66, endIndent: 16, color: Color(0xFFF0EDE8));

  // ── Support Card ──────────────────────────────────────────────────────────
  Widget _buildSupportCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12, offset: const Offset(0, 4),
      )],
    ),
    child: Column(children: [
      _supportRow(Icons.help_outline_rounded, 'Help Center',
          'Guides, FAQs and how-tos', const Color(0xFF3B82F6), isFirst: true,
          onTap: () => _showHelpSheet()),
      _divider(),
      _supportRow(Icons.bug_report_outlined, 'Report a Bug',
          'Something not working? Tell us', const Color(0xFFEF4444),
          onTap: () => _showReportSheet()),
      _divider(),
      _supportRow(Icons.info_outline_rounded, 'About Noor Rewards',
          'Version 1.0 • Built with ❤️ for the Ummah', const Color(0xFFFFAA00),
          onTap: () => _showAboutSheet()),
      _divider(),
      _supportRow(Icons.privacy_tip_outlined, 'Privacy Policy',
          'How we protect your data', const Color(0xFF8E8E93), isLast: true,
          onTap: () {}),
    ]),
  );

  Widget _supportRow(IconData icon, String title, String sub, Color color, {
    bool isFirst = false, bool isLast = false, VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.vertical(
      top: isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: isLast ? const Radius.circular(20) : Radius.zero,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF8E8E93))),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0A898), size: 20),
      ]),
    ),
  );

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Widget _buildSignOutButton() => GestureDetector(
    onTap: _signOut,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECEC)),
        boxShadow: [BoxShadow(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.06),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 20),
        const SizedBox(width: 10),
        Text('Sign Out', style: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFD32F2F))),
      ]),
    ),
  );

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(text.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: const Color(0xFF8E8E93), letterSpacing: 1));

  // ── Help Sheet ────────────────────────────────────────────────────────────
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetCard(
        title: 'Help Center',
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF3B82F6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _helpItem('How to earn Noor Points?',
              'Complete Quran reading, Dhikr sets, and daily login to earn points.'),
          _helpItem('What is Validate Coins?',
              'Press the Validate button on the home page once per day to seal your coins.'),
          _helpItem('How do streaks work?',
              'Complete your daily activities consecutively to build your streak.'),
          _helpItem('Can I donate my Noor Points?',
              'Yes! Visit the Akhirah tab to donate your points to active community projects.'),
        ]),
      ),
    );
  }

  Widget _helpItem(String q, String a) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
          color: const Color(0xFF1C1C1E))),
      const SizedBox(height: 4),
      Text(a, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF8E8E93), height: 1.5)),
      const SizedBox(height: 8),
      const Divider(color: Color(0xFFF0EDE8), height: 0),
    ]),
  );

  // ── Report Sheet ──────────────────────────────────────────────────────────
  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetCard(
        title: 'Report a Bug',
        icon: Icons.bug_report_outlined,
        color: const Color(0xFFEF4444),
        child: Column(children: [
          Text(
            'Found something wrong? Please email us and we\'ll fix it as soon as possible.',
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF8E8E93), height: 1.6),
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
            child: Center(child: Text('support@noorapp.co',
                style: GoogleFonts.outfit(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15))),
          ),
        ]),
      ),
    );
  }

  // ── About Sheet ───────────────────────────────────────────────────────────
  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetCard(
        title: 'About Noor Rewards',
        icon: Icons.info_outline_rounded,
        color: const Color(0xFFFFAA00),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFFFFEE88), Color(0xFFFFAA00)]),
            ),
            child: Center(child: Text('N',
                style: GoogleFonts.rajdhani(fontSize: 32, fontWeight: FontWeight.w900,
                    color: Colors.black87))),
          ),
          const SizedBox(height: 16),
          Text('Noor Rewards',
              style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w900,
                  color: const Color(0xFF1C1C1E))),
          const SizedBox(height: 6),
          Text('Version 1.0.0',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF8E8E93))),
          const SizedBox(height: 16),
          Text(
            'Built with love for the global Muslim Ummah.\nEarn Noor Points by building Islamic habits.\nDonate points to support real community projects.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF8E8E93), height: 1.6),
          ),
        ]),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.rajdhani(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1C1E))),
            ]),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
