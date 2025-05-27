import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _tapCount = 0;
  DateTime? _firstTapTime;

  void _handleSecretTap() {
    final now = DateTime.now();

    // Reset tap count if more than 3 seconds have passed since first tap
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 3)) {
      _tapCount = 1;
      _firstTapTime = now;
    } else {
      _tapCount++;

      // If 5 taps reached, navigate to admin login
      if (_tapCount == 5) {
        // Provide subtle feedback (optional)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accessing admin area...'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blueGrey,
          ),
        );

        // Navigate to admin login page
        context.go('/admin-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgdesign_welcome.png',
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo with gesture detection
                    GestureDetector(
                      onTap: _handleSecretTap,
                      child: Image.asset(
                        'assets/images/seniorsurfersLogoNoName.png',
                        height: 150,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Welcome Text
                    const Text(
                      'Welcome to Senior Surfers!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Helping you stay connected and confident with technology.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(136, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Get Started Button
                    ElevatedButton(
                      onPressed: () {
                        // Using GoRouter instead of Navigator
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
