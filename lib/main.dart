import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'navigation/bottom_nav.dart';
import 'screens/parent/parent_dashborad_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sfjluqipsfxocaehnzqt.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamx1cWlwc2Z4b2NhZWhuenF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5ODI2NzYsImV4cCI6MjA4OTU1ODY3Nn0.gDoeVfeIb8uDYPNLSUu0Rz6sOL7tlaMPs3MeYo8hE-o',
  );

  runApp(const SafeWalkApp());
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthChecker(),
    );
  }
}

/// 🔐 CHECK LOGIN + ROLE
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    /// ✅ FIX: Delay navigation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUser();
    });
  }

  Future<void> checkUser() async {
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    if (session == null) {
      /// ❌ Not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      /// ✅ Logged in → get role
      final userId = session.user.id;

      try {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        if (!mounted) return;

        String role = data['role'];

        if (role == "User") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BottomNav()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentDashboradScreen(),
            ),
          );
        }
      } catch (e) {
        print("Error fetching role: $e");

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 🔄 Loading screen while checking
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}