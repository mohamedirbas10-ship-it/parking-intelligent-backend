import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'main/parking_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _carController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _carSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _carController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _carSlideAnimation = Tween<double>(begin: -20.0, end: 20.0).animate(
      CurvedAnimation(parent: _carController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    Timer(const Duration(seconds: 10), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isLoggedIn ? const ParkingHomeScreen() : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Car illustration
              AnimatedBuilder(
                animation: _carSlideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_carSlideAnimation.value, 0),
                    child: Image.asset(
                      'assets/images/black-car-vector_800.png',
                      width: 300,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'CAR PARKING',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'This is a Car parking app for Smart car parking station. Here you can find parking slot and book your parking slot from any where with you phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
