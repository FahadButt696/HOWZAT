import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _fullText = "HOWZAT!";
  String _displayedText = "";
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTextAnimation();
    _startTimer();
  }

  void _startTextAnimation() {
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startTimer() {
    Timer(const Duration(seconds: 3), () {
      final auth = AuthService();
      if (auth.currentUser != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/wicket.png',
                height: 50,
                width: 50,
              ),
              const SizedBox(height: 20),
              Text(
                _displayedText,
                style: GoogleFonts.bebasNeue(
                  fontSize: 60,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
