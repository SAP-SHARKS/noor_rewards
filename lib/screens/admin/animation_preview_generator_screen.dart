// animation_preview_generator_screen.dart
//
// A one-time admin tool. Iterates every animation key in azkar_animations,
// renders each illustration into an offscreen RepaintBoundary, captures the
// rendered frame as a PNG, and uploads to the public Supabase Storage bucket
// `animation-previews/<key>.png`.
//
// The admin web AnimationCardPicker reads from those URLs so you can pick
// rotation pools by sight instead of by emoji.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dhikr_screen.dart' show buildIllustrationForPreview;

class AnimationPreviewGeneratorScreen extends StatefulWidget {
  const AnimationPreviewGeneratorScreen({super.key});

  @override
  State<AnimationPreviewGeneratorScreen> createState() =>
      _AnimationPreviewGeneratorScreenState();
}

class _AnimationPreviewGeneratorScreenState
    extends State<AnimationPreviewGeneratorScreen> {
  final _sb = Supabase.instance.client;

  List<_AnimationRow> _animations = const [];
  bool _loading = true;
  bool _generating = false;
  String _status = '';
  final List<String> _log = [];

  int _doneCount = 0;
  int _failCount = 0;

  // We render each illustration into this offstage RepaintBoundary by
  // swapping the child each iteration. A GlobalKey lets us grab the
  // boundary's render object once the frame paints.
  final GlobalKey _boundaryKey = GlobalKey();
  Widget? _currentChild;

  @override
  void initState() {
    super.initState();
    _loadAnimations();
  }

  Future<void> _loadAnimations() async {
    setState(() => _loading = true);
    try {
      final rows = await _sb
          .from('azkar_animations')
          .select('id, key, name, is_active')
          .eq('is_active', true)
          .order('sort_order');
      _animations = (rows as List)
          .map((r) => _AnimationRow(
                id: r['id'] as String,
                key: r['key'] as String,
                name: (r['name'] as String?) ?? r['key'] as String,
              ))
          .toList();
    } catch (e) {
      _animations = const [];
      _log.add('Failed to load azkar_animations: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Sets the next illustration child, waits a couple of frames so animation
  /// controllers have a chance to settle, then captures the boundary as PNG.
  Future<Uint8List> _captureKey(String key) async {
    setState(() {
      _currentChild = SizedBox(
        width: 320,
        height: 320,
        child: RepaintBoundary(
          key: _boundaryKey,
          child: buildIllustrationForPreview(key: key),
        ),
      );
    });

    // Wait several frames so animation controllers init + paint at least once.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('RepaintBoundary not yet attached for key=$key');
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('toByteData returned null for $key');
    return byteData.buffer.asUint8List();
  }

  Future<void> _generateAll() async {
    if (_animations.isEmpty) return;
    setState(() {
      _generating = true;
      _doneCount = 0;
      _failCount = 0;
      _log.clear();
      _status = 'Starting…';
    });

    for (var i = 0; i < _animations.length; i++) {
      final a = _animations[i];
      setState(() => _status = '${i + 1}/${_animations.length}: ${a.key}');
      try {
        final png = await _captureKey(a.key);
        await _sb.storage.from('animation-previews').uploadBinary(
              '${a.key}.png',
              png,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
                cacheControl: '3600',
              ),
            );
        _doneCount++;
        _log.add('✅ ${a.key}');
      } catch (e) {
        _failCount++;
        _log.add('❌ ${a.key}: $e');
      }
      if (mounted) setState(() {});
    }

    setState(() {
      _generating = false;
      _status =
          'Done. $_doneCount uploaded, $_failCount failed (of ${_animations.length}).';
      _currentChild = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _sb.auth.currentSession;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Preview Generator'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Text(
                    'Not signed in. Storage uploads require an authenticated '
                    'session — open the regular app, sign in, then come back '
                    'and tap Generate.',
                    style: TextStyle(color: Colors.amber.shade900),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _loading
                    ? 'Loading animation catalog…'
                    : '${_animations.length} animation${_animations.length == 1 ? "" : "s"} ready to capture.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: (_loading || _generating || _animations.isEmpty)
                        ? null
                        : _generateAll,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(_generating ? 'Working…' : 'Generate & upload'),
                  ),
                  const SizedBox(width: 12),
                  if (_generating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_status.isNotEmpty)
                Text(_status,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              if (_animations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(
                    value: _animations.isEmpty
                        ? 0
                        : (_doneCount + _failCount) / _animations.length,
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(),
              // Live "now capturing" panel — must be visibly painted by the
              // engine, otherwise toImage() throws !debugNeedsPaint. Centering
              // it in the screen also gives you visual confirmation of what's
              // being uploaded.
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _currentChild ?? const SizedBox(
                      width: 320,
                      height: 320,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      _log.isEmpty ? 'No activity yet.' : _log.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimationRow {
  final String id;
  final String key;
  final String name;
  const _AnimationRow({required this.id, required this.key, required this.name});
}

