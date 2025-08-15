import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showCustomSnackbar(String message, {bool isError = true}) {
    final background = isError ? Colors.redAccent.shade200 : Colors.greenAccent.shade200;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.warning_amber_rounded : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showCustomSnackbar("Email and password cannot be empty");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showCustomSnackbar("Please enter a valid email address");
      return;
    }

    if (password.length < 6) {
      _showCustomSnackbar("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.loginWithEmail(email, password);
    setState(() => _isLoading = false);

    if (user != null) {
      _showCustomSnackbar("Login successful", isError: false);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _showCustomSnackbar("Login failed. Check your credentials.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: keyboardSpace),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - keyboardSpace,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Image.asset('assets/icons/wicket.png', height: 60, width: 60),
                    const SizedBox(height: 8),
                    Text(
                      "HOWZAT!",
                      style: GoogleFonts.balooBhai2(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Login",
                              style: GoogleFonts.balooBhai2(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: _email,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email, color: Colors.white),
                                labelText: "Email",
                                labelStyle: GoogleFonts.balooBhai2(color: Colors.white70),
                                hintText: "Enter your email",
                                hintStyle: const TextStyle(color: Colors.white38),
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

                            TextField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: Colors.white),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                labelText: "Password",
                                labelStyle: GoogleFonts.balooBhai2(color: Colors.white70),
                                hintText: "Enter your password",
                                hintStyle: const TextStyle(color: Colors.white38),
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
                            const SizedBox(height: 24), // Space where "Remember Me" was

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
                                  : Text("Submit", style: GoogleFonts.balooBhai2(color: Colors.white,fontSize: 16)),
                            ),
                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.balooBhai2(
                                    fontSize: 14,
                                    color: Colors.white, // default color for non-bold part
                                  ),
                                  children: [
                                    const TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: "SignUp",
                                      style: GoogleFonts.balooBhai2(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.lightGreenAccent.shade100,
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

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
