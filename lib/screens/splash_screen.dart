import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/order_provider.dart';
import '../providers/subscription_provider.dart';
import 'onboarding_screen.dart';

import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load providers data
    await context.read<AuthProvider>().loadUsers();
    await context.read<LocationProvider>().getCurrentLocation();
    await context.read<OrderProvider>().loadData();
    await context.read<SubscriptionProvider>().loadSubscriptions();

    // Wait for 1 second delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Navy blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show launcher icon only
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
