import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/parking_home_screen.dart';
import 'theme/app_theme.dart';
import 'services/booking_provider.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().initialize();

  // Load saved JWT token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🚀 APP STARTUP - Token Check');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print(
    '🔍 Token from SharedPreferences: ${token != null ? "EXISTS" : "NULL"}',
  );

  if (token != null) {
    print('🔑 Token length: ${token.length}');
    print('🔑 Token preview: ${token.substring(0, 20)}...');
    ApiService.setToken(token);
    print('✅ Token loaded and set in ApiService');
    print('✅ isAuthenticated: ${ApiService.isAuthenticated}');
  } else {
    print('❌ No token found in SharedPreferences');
    print('❌ User will need to login');
  }
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  runApp(const ParkingApp());
}

class ParkingApp extends StatefulWidget {
  const ParkingApp({super.key});

  @override
  State<ParkingApp> createState() => _ParkingAppState();
}

class _ParkingAppState extends State<ParkingApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🎯 App lifecycle observer added');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 APP LIFECYCLE CHANGE: $state');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (state == AppLifecycleState.resumed) {
      // App came back from background (laptop opened, app reopened, etc.)
      print('✅ App resumed - Reloading token from storage...');
      _reloadToken();
    } else if (state == AppLifecycleState.paused) {
      print('⏸️ App paused - Going to background');
    } else if (state == AppLifecycleState.inactive) {
      print('💤 App inactive');
    } else if (state == AppLifecycleState.detached) {
      print('🔌 App detached');
    }
  }

  Future<void> _reloadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        print('🔑 Token found in storage: ${token.substring(0, 20)}...');
        ApiService.setToken(token);
        print('✅ Token reloaded successfully');
        print('✅ isAuthenticated: ${ApiService.isAuthenticated}');
      } else {
        print('❌ No token found in storage');
      }
    } catch (e) {
      print('❌ Error reloading token: $e');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingProvider(),
      child: MaterialApp(
        title: 'Smart Car Parking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

//fix
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Check if we have a valid token
    if (token != null) {
      ApiService.setToken(token);
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? const ParkingHomeScreen() : const LoginScreen();
  }
}
