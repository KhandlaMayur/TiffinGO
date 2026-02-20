import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54); // navy blue for the button

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top curved image/header
            SizedBox(
              height: 340,
              width: double.infinity,
              child: ClipPath(
                clipper: _BottomArcClipper(),
                child: Container(
                  color: navy,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Try to load an asset image if available; fallback to icon
                      Image.asset(
                        'assets/images/tiffine.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 120,
                              color: Colors.white70,
                            ),
                          );
                        },
                      ),
                      // Slight overlay for better text contrast
                      Container(color: Colors.black.withOpacity(0.15)),
                      // Optional small title/logo at top-left
                      const Positioned(
                        left: 20,
                        top: 20,
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'TiffinGo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // White content area
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Ghar jaisa khana, har din!\nEnjoy freshly cooked homemade tiffins that bring comfort and taste together.',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Start your tasty journey today!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),

                      // Get Start button - navy blue with arrow
                      SizedBox(
                        width: 200,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 6,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Start',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1E3A8A),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A clipper that creates a concave arc at the bottom of the widget.
class _BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    // create a quadratic bezier curve for the concave arc
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
