// lib/screens/admin/sponsor_analytics_section.dart
//
// Admin Dashboard — Sponsor Report screen.
// Uses fl_chart for bar charts. Reads from the analytics aggregate views.

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Palette (mirrors admin_dashboard.dart) ─────────────────────────────────
const _kBg      = Color(0xFFF8FAFC);
const _kWhite   = Colors.white;
const _kText    = Color(0xFF1E293B);
const _kSub     = Color(0xFF64748B);
const _kBorder  = Color(0xFFE2E8F0);
const _kAccent  = Color(0xFF2BAE99);
const _kPurple  = Color(0xFF6B4EBB);
const _kGold    = Color(0xFFF59E0B);
const _kRose    = Color(0xFFE05C6A);

class SponsorAnalyticsSection extends StatefulWidget {
  const SponsorAnalyticsSection({super.key});
  @override
  State<SponsorAnalyticsSection> createState() => _SponsorAnalyticsSectionState();
}

class _SponsorAnalyticsSectionState extends State<SponsorAnalyticsSection> {
  final _sb = Supabase.instance.client;

  List<Map<String, dynamic>> _countryData  = [];
  List<Map<String, dynamic>> _deviceData   = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _sb.from('analytics_country_summary').select().limit(10),
        _sb.from('analytics_device_summary').select(),
      ]);
      _countryData = List<Map<String, dynamic>>.from(results[0] as List);
      _deviceData  = List<Map<String, dynamic>>.from(results[1] as List);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 24),
        _summaryRow(),
        const SizedBox(height: 24),
        _countryChart(),
        const SizedBox(height: 20),
        _deviceChart(),
        const SizedBox(height: 20),
        _coinsTable(),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('🌍', style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 8),
      Flexible(child: Text('Sponsor Impact Report',
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _kText))),
    ]),
    const SizedBox(height: 4),
    Text('Live 30-day aggregated data. No personal information is shown.',
        style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
  ]);

  // ── Summary chips ──────────────────────────────────────────────────────────
  Widget _summaryRow() {
    final totalUsers = _countryData.fold<int>(
        0, (s, r) => s + ((r['active_users'] as num?)?.toInt() ?? 0));
    final totalCoins = _countryData.fold<int>(
        0, (s, r) => s + ((r['total_coins'] as num?)?.toInt() ?? 0));
    final avgSession = _countryData.isEmpty ? 0 :
        _countryData.fold<int>(0, (s, r) =>
            s + ((r['avg_session_sec'] as num?)?.toInt() ?? 0)) ~/ _countryData.length;

    return Wrap(spacing: 12, runSpacing: 12, children: [
      _SummaryChip('👥', 'Active Users', _fmtNum(totalUsers), _kAccent),
      _SummaryChip('🪙', 'Total Coins', _fmtNum(totalCoins), _kGold),
      _SummaryChip('⏱️', 'Avg Session', _fmtDur(avgSession), _kPurple),
      _SummaryChip('🌐', 'Countries', '${_countryData.length}', _kRose),
    ]);
  }

  // ── Country bar chart ──────────────────────────────────────────────────────
  Widget _countryChart() {
    if (_countryData.isEmpty) return _empty('No country data yet');

    final max = _countryData
        .map((r) => (r['active_users'] as num?)?.toDouble() ?? 0)
        .fold(0.0, math.max);

    return _ChartCard(
      title: '📍 Active Users by Country',
      subtitle: 'Top 10 countries (last 30 days)',
      child: BarChart(
        BarChartData(
          maxY: max * 1.3,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final country = _countryData[group.x]['country_code'] ?? '?';
                return BarTooltipItem(
                  '$country\n${rod.toY.toInt()} users',
                  GoogleFonts.outfit(fontSize: 12, color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= _countryData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    (_countryData[i]['country_code'] ?? '?') as String,
                    style: GoogleFonts.outfit(fontSize: 10, color: _kSub),
                  ),
                );
              },
            )),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: _kBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _countryData.asMap().entries.map((e) {
            final users = (e.value['active_users'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: users,
                width: 20,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_kAccent, _kAccent.withValues(alpha: 0.6)],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ── Device session chart ───────────────────────────────────────────────────
  Widget _deviceChart() {
    if (_deviceData.isEmpty) return _empty('No device data yet');

    final sections = _deviceData.asMap().entries.map((e) {
      final label = (e.value['device_type'] ?? 'Other') as String;
      final users = (e.value['active_users'] as num?)?.toDouble() ?? 1;
      final colors = [_kAccent, _kPurple, _kGold, _kRose];
      final color  = colors[e.key % colors.length];
      return PieChartSectionData(
        value: users,
        title: label,
        color: color,
        radius: 80,
        titleStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return _ChartCard(
      title: '📱 Users by Device Type',
      subtitle: 'Average session time per platform',
      child: SizedBox(
        height: 220,
        child: Row(children: [
          Expanded(
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 3,
            )),
          ),
          const SizedBox(width: 16),
          // Legend + avg session — constrained so long names don't overflow
          SizedBox(
            width: 110,
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _deviceData.asMap().entries.map((e) {
              final label   = (e.value['device_type'] ?? 'Other') as String;
              final avgSec  = (e.value['avg_session_sec'] as num?)?.toInt() ?? 0;
              final colors  = [_kAccent, _kPurple, _kGold, _kRose];
              final color   = colors[e.key % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(width: 12, height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
                    Text(_fmtDur(avgSec),
                        style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
                  ])),
                ]),
              );
            }).toList()),
          ),
        ]),
      ),
    );
  }

  // ── Coins-by-region table ──────────────────────────────────────────────────
  Widget _coinsTable() {
    if (_countryData.isEmpty) return const SizedBox();

    return _ChartCard(
      title: '🪙 Noor Coins by Region',
      subtitle: 'Total coins generated in the last 30 days',
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: _kBg, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: _tHead('Country')),
            _tHead('Users'),
            const SizedBox(width: 16),
            _tHead('Coins'),
            const SizedBox(width: 16),
            _tHead('Avg Session'),
          ]),
        ),
        const SizedBox(height: 4),
        ..._countryData.map((r) {
          final country = (r['country_code'] ?? '—') as String;
          final users   = (r['active_users'] as num?)?.toInt() ?? 0;
          final coins   = (r['total_coins'] as num?)?.toInt() ?? 0;
          final avgSec  = (r['avg_session_sec'] as num?)?.toInt() ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder))),
            child: Row(children: [
              Expanded(child: Row(children: [
                Text(_countryFlag(country), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(country, style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
              ])),
              Text('$users', style: GoogleFonts.outfit(fontSize: 13, color: _kSub)),
              const SizedBox(width: 16),
              Text(_fmtNum(coins), style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kGold)),
              const SizedBox(width: 16),
              Text(_fmtDur(avgSec), style: GoogleFonts.outfit(fontSize: 13, color: _kPurple)),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _empty(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Text(msg, style: GoogleFonts.outfit(color: _kSub)),
    ),
  );

  Widget _tHead(String t) => Text(t,
      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: _kSub));

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _fmtDur(int sec) {
    if (sec <= 0) return '—';
    final m = sec ~/ 60;
    final h = m  ~/ 60;
    if (h > 0) return '${h}h ${m % 60}m';
    return '${m}m';
  }

  String _countryFlag(String code) {
    if (code.length != 2) return '🌐';
    final base = 0x1F1E6;
    final first = code.codeUnitAt(0) - 0x41;
    final second = code.codeUnitAt(1) - 0x41;
    return String.fromCharCodes([base + first, base + second]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _SummaryChip(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
    ]),
  );
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _kWhite,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
      Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
      const SizedBox(height: 20),
      SizedBox(height: 240, child: child),
    ]),
  );
}
