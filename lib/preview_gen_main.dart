// preview_gen_main.dart
//
// Standalone entry point for the Animation Preview Generator. Run with:
//
//   flutter run -t lib/preview_gen_main.dart
//
// Tiny bootstrap: WidgetsBinding → Hive → Supabase → quick email-password
// sign-in form so the upload has an authenticated session. After signing in
// you land on AnimationPreviewGeneratorScreen which has the Generate &
// Upload button.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin/animation_preview_generator_screen.dart';

const String _supabaseUrl = 'https://fwjzhtcxfiendofnhyzp.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3anpodGN4ZmllbmRvZm5oeXpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzkwNDksImV4cCI6MjA4NjkxNTA0OX0.gspfVlCH-S2Cs8_fhOeDWNZN2XH1NC53CJ8riyvJ5nw';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const _PreviewGenApp());
}

class _PreviewGenApp extends StatelessWidget {
  const _PreviewGenApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabiq — Preview Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const _Gate(),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final _sb = Supabase.instance.client;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _signingIn = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final session = _sb.auth.currentSession;
    if (session != null) return const AnimationPreviewGeneratorScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to upload previews')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Use any account with write access to the '
                'animation-previews storage bucket (typically the admin '
                'account, e.g. pak.zakn@gmail.com).',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                onPressed: _signingIn ? null : _signIn,
                child: Text(_signingIn ? 'Signing in…' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await _sb.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }
}
