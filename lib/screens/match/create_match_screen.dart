import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreen();
}

class _CreateMatchScreen extends State<CreateMatchScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password cannot be empty")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.loginWithEmail(email, password);
    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Check your credentials.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // App logo and title at the top center
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/logo.png', // Your cricket-themed logo
                    height: 60,
                    width: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "CRICKET PRO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Login Card
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email
                      TextField(
                        controller: _email,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email, color: Colors.white),
                          labelText: "Email",
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _password,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock, color: Colors.white),
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Continue button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreenAccent.shade700,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Continue", style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 12),

                      // Sign up redirect
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                text: "Sign up",
                                style: TextStyle(
                                  color: Colors.lightGreenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
