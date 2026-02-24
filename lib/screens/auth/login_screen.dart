import 'package:flutter/material.dart';
import '../../navigation/bottom_nav.dart';
import '../parent/parent_dashborad_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = "User";

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

              /// LOGO ICON
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

              /// APP NAME
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
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /// EMAIL
              _inputField("Email Address", Icons.email_outlined),

              const SizedBox(height: 18),

              /// PASSWORD
              _inputField("Password", Icons.lock_outline,
                  isPassword: true),

              const SizedBox(height: 30),

              /// ROLE SELECTOR
              _roleSelector(),

              const SizedBox(height: 40),

              /// LOGIN BUTTON
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFFF6A00),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    if (role == "User") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const BottomNav(),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ParentDashboradScreen(),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _inputField(String hint, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _roleButton("User"),
          _roleButton("Parent"),
        ],
      ),
    );
  }

  Widget _roleButton(String text) {
    final selected = role == text;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = text),
        child: Container(
          padding:
          const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFF6A00)
                : Colors.transparent,
            borderRadius:
            BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}