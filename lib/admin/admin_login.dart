import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _usernameController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // Log email being used
      print('Attempting login with email: $email');

      // Sign in with Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user;

      if (session != null && user != null && user.email != null) {
        print('Login successful for: ${user.email}');

        // Query the users table to check admin status
        final adminCheck =
            await Supabase.instance.client
                .from('users')
                .select('is_admin')
                .eq('email', user.email!.trim().toLowerCase())
                .maybeSingle();

        print('Admin check result: $adminCheck');

        final isAdmin =
            adminCheck != null &&
            (adminCheck['is_admin'] == true ||
                adminCheck['is_admin'].toString().toLowerCase() == 'true');

        if (isAdmin) {
          print('User is an admin, navigating to admin dashboard');
          // Redirect to the admin dashboard's main page (analysis)
          context.go('/admin/analysis');
        } else {
          print('User is not an admin');
          setState(() {
            _errorMessage = 'You are not authorized as an admin.';
          });
          await Supabase.instance.client.auth.signOut();
        }
      } else {
        print('Login failed or missing user email');
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected error: $e');
      setState(() {
        _errorMessage = 'Unexpected error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layouts
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bgdesign_welcome.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 12,
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                // Responsive margins based on screen size
                margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : screenSize.width * 0.2,
                ),
                child: Padding(
                  // Responsive padding based on screen size
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 32,
                    vertical: isSmallScreen ? 24 : 40,
                  ),
                  child: ConstrainedBox(
                    // Constraining max width for web view
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin Login',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 30),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                              // Make button width responsive
                              width: isSmallScreen ? double.infinity : 200,
                              height: isSmallScreen ? 50 : 55,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C3E50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
