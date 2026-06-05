import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartshelf/view/navigation_screen.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Wait 2 seconds then navigate (reduced from 3 for better UX)
    Timer(const Duration(seconds: 2), () {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isLoggedIn = prefs.getBool('isLoggedIn');

    if (isLoggedIn == true) {
      // User is already logged in - go to dashboard
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen())
      );
    } else {
      // User not logged in - go to login screen
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColor.primary, AppColor.primary.withValues(alpha: 0.8)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // OPTION 1: Use a logo image (recommended)
            // Place your logo at: assets/images/logo.png
            // Image.asset(
            //   "assets/images/logo.png",
            //   width: 150,
            //   height: 150,
            // ),

            // OPTION 2: Use an icon (if no image available)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store,
                size: 80,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "SmartShelf",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Smart Inventory Management",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 48),

            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

