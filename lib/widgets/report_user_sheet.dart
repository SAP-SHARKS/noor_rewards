// lib/widgets/report_user_sheet.dart
//
// UGC-safety: modal bottom sheet that lets a signed-in user report AND / OR
// block another user (leaderboard row, etc.).
//
// - Report writes a row into public.user_reports; the server enforces the
//   CHECK constraint on `reason` and the `reporter_user_id = auth.uid()`
//   policy — the client only needs to pass a valid reason value. A UNIQUE
//   index (reporter, reported, UTC-day) on user_reports means a second
//   report for the same user on the same day raises unique_violation
//   (23505) — we catch that and show `l.alreadyReported`.
// - Block writes a row into public.blocked_users; unique_violation there
//   means "already blocked" — we surface that as a friendly snackbar.
//
// Migration source of truth:
//   supabase/migrations/20260812_010_block_and_tighten_reports.sql
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

/// Opens the "Report / Block user" modal bottom sheet.
///
/// Returns a Future that resolves to `true` if the user blocked or reported
/// the target (so the caller can refresh a blocklist-filtered view). Resolves
/// to `false` on cancel or on any silent failure. Existing callers that
/// `await` without capturing the value keep working — the `Future<bool>` is
/// assignable to `Future<void>` at the call site.
Future<bool> showReportUserSheet(
  BuildContext context, {
  required String reportedUserId,
  required String reportedDisplayName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportUserSheet(
      reportedUserId: reportedUserId,
      reportedDisplayName: reportedDisplayName,
    ),
  );
  return result ?? false;
}

class _ReportUserSheet extends StatefulWidget {
  final String reportedUserId;
  final String reportedDisplayName;
  const _ReportUserSheet({
    required this.reportedUserId,
    required this.reportedDisplayName,
  });

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  // Values MUST match the CHECK constraint on user_reports.reason in
  // supabase/migrations/20260811_020_ugc_mitigation.sql. Do not change
  // these keys without matching the server list.
  static const _reasonKeys = <String>[
    'offensive_name',
    'impersonation',
    'spam',
    'harassment',
    'other',
  ];

  final _supabase = Supabase.instance.client;
  final _notesCtrl = TextEditingController();

  String _reason = 'offensive_name';
  bool _submitting = false;
  bool _blocking = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'offensive_name':
        return l.reportReasonOffensiveName;
      case 'impersonation':
        return l.reportReasonImpersonation;
      case 'spam':
        return l.reportReasonSpam;
      case 'harassment':
        return l.reportReasonHarassment;
      case 'other':
      default:
        return l.reportReasonOther;
    }
  }

  // Detect the Postgres unique-violation SQLSTATE (23505) from a Supabase
  // PostgrestException. Message text varies across locales / PostgREST
  // versions, so we look for either the SQLSTATE code, the words
  // 'duplicate key' / 'unique_violation', or the exception's `code` field.
  bool _isUniqueViolation(Object err) {
    if (err is PostgrestException) {
      if (err.code == '23505') return true;
      final msg = err.message.toLowerCase();
      if (msg.contains('duplicate key')) return true;
      if (msg.contains('unique_violation')) return true;
      if (msg.contains('23505')) return true;
    }
    final s = err.toString().toLowerCase();
    return s.contains('23505') ||
        s.contains('duplicate key') ||
        s.contains('unique_violation');
  }

  Future<void> _showSnack(String text, {bool error = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _block() async {
    final l = AppLocalizations.of(context)!;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      Navigator.of(context).maybePop(false);
      return;
    }
    if (_submitting || _blocking) return;

    setState(() => _blocking = true);
    try {
      await _supabase.from('blocked_users').insert({
        'blocker_user_id': uid,
        'blocked_user_id': widget.reportedUserId,
      });
      if (!mounted) return;
      Navigator.of(context).maybePop(true);
      await _showSnack(l.userBlocked);
    } catch (e) {
      debugPrint('[ReportUserSheet] block failed: $e');
      if (!mounted) return;
      if (_isUniqueViolation(e)) {
        // Already blocked — treat as success from the user's perspective.
        Navigator.of(context).maybePop(true);
        await _showSnack(l.userAlreadyBlocked);
        return;
      }
      setState(() => _blocking = false);
      await _showSnack(l.reportFailed, error: true);
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      Navigator.of(context).maybePop(false);
      return;
    }

    setState(() => _submitting = true);
    final notes = _notesCtrl.text.trim();
    try {
      await _supabase.from('user_reports').insert({
        'reporter_user_id': uid,
        'reported_user_id': widget.reportedUserId,
        'reason': _reason,
        if (notes.isNotEmpty) 'notes': notes,
      });
      if (!mounted) return;
      Navigator.of(context).maybePop(true);
      await _showSnack(l.reportSubmitted);
    } catch (e) {
      debugPrint('[ReportUserSheet] submit failed: $e');
      if (!mounted) return;
      // Duplicate report for the same user on the same UTC day.
      if (_isUniqueViolation(e)) {
        Navigator.of(context).maybePop(true);
        await _showSnack(l.alreadyReported);
        return;
      }
      Navigator.of(context).maybePop(false);
      await _showSnack(l.reportFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final busy = _submitting || _blocking;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l.reportUser,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.reportUserBody,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Block section (independent from Report) ────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.blockUser,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.blockUserBody,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : _block,
                          icon: _blocking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.block_rounded, size: 18),
                          label: Text(
                            l.blockUser,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.35),
                            ),
                            foregroundColor: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Report section ────────────────────────────────────────
                // Reason dropdown
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.reportReason,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _reason,
                      isExpanded: true,
                      items: [
                        for (final k in _reasonKeys)
                          DropdownMenuItem<String>(
                            value: k,
                            child: Text(
                              _reasonLabel(l, k),
                              style: GoogleFonts.outfit(fontSize: 14),
                            ),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() => _reason = v);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Optional notes
                TextField(
                  controller: _notesCtrl,
                  enabled: !busy,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: l.reportNotes,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.outfit(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).maybePop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                l.reportSubmit,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
}
