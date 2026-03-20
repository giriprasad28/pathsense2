import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../navigation/bottom_nav.dart';
import '../parent/parent_dashborad_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// 🔐 LOGIN FUNCTION (UPDATED)
  Future<void> loginUser() async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null) {
        final userId = response.user!.id;

        /// 🔥 FETCH ROLE FROM DATABASE
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        String roleFromDb = data['role'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login as $roleFromDb")),
        );

        /// 🔀 NAVIGATION BASED ON ROLE
        if (roleFromDb == "User") {
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
      }
    } catch (e) {
      print("Login Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [

              const SizedBox(height: 80),

              /// LOGO
              Center(
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  "Path Sense",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  "Stay Safe. Stay Connected.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 50),

              /// EMAIL
              _inputField(
                "Email Address",
                Icons.email_outlined,
                controller: emailController,
              ),

              const SizedBox(height: 18),

              /// PASSWORD
              _inputField(
                "Password",
                Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),

              const SizedBox(height: 40),

              /// LOGIN BUTTON
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: loginUser,
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// SIGNUP NAVIGATION BUTTON
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// INPUT FIELD
  Widget _inputField(
      String hint,
      IconData icon, {
        bool isPassword = false,
        required TextEditingController controller,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}