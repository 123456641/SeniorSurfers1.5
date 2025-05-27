import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart'; // Import go_router

class LoginPagee extends StatefulWidget {
  const LoginPagee({super.key});

  @override
  State<LoginPagee> createState() => _LoginPageeState();
}

class _LoginPageeState extends State<LoginPagee>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Progressive form state
  int _currentStep = 0;
  bool _emailValid = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Field validation errors
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize animation
    _animationController.forward();

    // Add listeners to focus nodes for better UX
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      _validateEmail();
    }
  }

  void _handlePasswordFocusChange() {
    if (!_passwordFocusNode.hasFocus) {
      _validatePassword();
    }
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = "Email is required";
        _emailValid = false;
      });
      return false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailError = "Please enter a valid email address";
        _emailValid = false;
      });
      return false;
    }

    setState(() {
      _emailError = null;
      _emailValid = true;
    });
    return true;
  }

  bool _validatePassword() {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _passwordError = "Password is required";
      });
      return false;
    } else if (password.length < 6) {
      setState(() {
        _passwordError = "Password must be at least 6 characters";
      });
      return false;
    }

    setState(() {
      _passwordError = null;
    });
    return true;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateEmail()) {
        setState(() {
          _currentStep = 1;
        });

        // Reset and run the animation again
        _animationController.reset();
        _animationController.forward();

        // Focus the next field
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        });
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });

      // Reset and run the animation again
      _animationController.reset();
      _animationController.forward();

      // Focus previous field
      if (_currentStep == 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(_emailFocusNode);
        });
      }
    }
  }

  /// Check if user has completed onboarding
  Future<bool> _checkOnboardingStatus(String userId) async {
    try {
      final response =
          await Supabase.instance.client
              .from('users')
              .select('onboarding_completed')
              .eq('id', userId)
              .maybeSingle();

      if (response == null) {
        // User record doesn't exist in users table, create it
        await Supabase.instance.client.from('users').insert({
          'id': userId,
          'email': _emailController.text.trim(),
          'onboarding_completed': false,
        });
        return false;
      }

      return response['onboarding_completed'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // If there's an error, assume onboarding is not completed
      return false;
    }
  }

  Future<void> _login() async {
    // Validate both fields before submission
    final emailValid = _validateEmail();
    final passwordValid = _validatePassword();

    if (!emailValid || !passwordValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Haptic feedback for button press
      HapticFeedback.mediumImpact();

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // Successfully logged in
        if (_rememberMe) {
          // In a real app, you'd implement proper credential storage here
          // This is just a placeholder
          debugPrint('Remembering user credentials');
        }

        // Check onboarding status
        final hasCompletedOnboarding = await _checkOnboardingStatus(
          response.user!.id,
        );

        // Haptic feedback for success
        HapticFeedback.heavyImpact();

        if (mounted) {
          if (hasCompletedOnboarding) {
            // User has completed onboarding, go to dashboard
            context.go('/dashboard');
          } else {
            // User hasn't completed onboarding, go to onboarding
            context.go('/onboarding');
          }
        }
      }
    } on AuthException catch (e) {
      // Haptic feedback for error
      HapticFeedback.vibrate();

      String errorMessage =
          e.message.toLowerCase().contains('invalid login credentials')
              ? "Incorrect email or password. Please try again."
              : e.message;

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      // Haptic feedback for error
      HapticFeedback.vibrate();

      _showErrorSnackBar(
        "An unexpected error occurred. Please try again later.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF27445D);
    const Color primaryButtonColor = Color(0xFF27445D);
    final theme = Theme.of(context);

    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeScreen = screenSize.width >= 1200;

    // Responsive padding and sizes
    final horizontalPadding =
        isSmallScreen
            ? 24.0
            : isMediumScreen
            ? 48.0
            : 64.0;

    final contentWidth =
        isSmallScreen
            ? screenSize.width
            : isMediumScreen
            ? 500.0
            : 600.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background image - covers the entire screen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bgdesign_welcome.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Responsive layout with centered content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24.0,
                  ),
                  child: _buildLoginContent(
                    context,
                    primaryTextColor,
                    theme,
                    isSmallScreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginContent(
    BuildContext context,
    Color primaryTextColor,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    // If on web and large screen, we'll show a card background
    final contentPadding = isSmallScreen ? 0.0 : 32.0;
    final cardRadius = isSmallScreen ? 0.0 : 16.0;
    final titleSize = isSmallScreen ? 22.0 : 26.0;
    final subtitleSize = isSmallScreen ? 15.0 : 17.0;

    return Card(
      elevation: isSmallScreen ? 0 : 8,
      color: isSmallScreen ? Colors.transparent : Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Logo at the top
            Center(
              child: Image.asset(
                'assets/images/seniorsurfersLogoNoName.png',
                height: isSmallScreen ? 80 : 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Welcome to Senior Surfers',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _currentStep == 0
                    ? 'Let\'s start with your email'
                    : 'Now enter your password',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: primaryTextColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              backgroundColor: Colors.grey.shade200,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 30),

            // Step 1: Email input
            if (_currentStep == 0)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _nextStep(),
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        fillColor: Colors.white70,
                        filled: true,
                        errorText: _emailError,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon:
                            _emailValid
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27445D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Step 2: Password input
            if (_currentStep == 1)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        fillColor: Colors.white70,
                        filled: true,
                        errorText: _passwordError,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Remember me checkbox
                    Row(children: [const Spacer()]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27445D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Sign up option - Updated to use GoRouter
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      // Updated: Use GoRouter instead of Navigator
                      context.go('/signup');
                    },
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add a ResponsiveBuilder to easily check screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;

  const ResponsiveBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine screen size
    ScreenSize screenSize;
    if (screenWidth < 600) {
      screenSize = ScreenSize.small;
    } else if (screenWidth < 1200) {
      screenSize = ScreenSize.medium;
    } else {
      screenSize = ScreenSize.large;
    }

    return builder(context, screenSize);
  }
}

// Screen size enum for responsive design
enum ScreenSize {
  small, // Mobile (< 600px)
  medium, // Tablet (600px - 1200px)
  large, // Desktop (> 1200px)
}
