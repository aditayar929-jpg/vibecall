import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      context.go('/profile-setup');
    } else if (authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    setState(() => _isLoading = false);

    if (success && mounted) {
      context.go('/profile-setup');
    } else if (authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInAsGuest();
    setState(() => _isLoading = false);

    if (success && mounted) {
      context.go('/home');
    } else if (authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12122A), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.videocam_rounded, size: 45, color: Colors.white),
                ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                // App name
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(colors: AppColors.primaryGradient)
                          .createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  AppStrings.tagline,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, letterSpacing: 2),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 50),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_rounded, color: AppColors.primaryPurple),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, delay: 400.ms),

                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primaryPurple),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.white38,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05, delay: 500.ms),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      if (_emailController.text.trim().isEmpty) {
                        _showError('Enter your email first');
                        return;
                      }
                      final authProvider = context.read<AuthProvider>();
                      final sent = await authProvider.sendPasswordReset(_emailController.text.trim());
                      if (sent && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Password reset email sent!'),
                            backgroundColor: AppColors.successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.neonPink.withOpacity(0.8), fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      disabledBackgroundColor: AppColors.primaryPurple.withOpacity(0.5),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 20),

                // Google button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.cardBackground,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.05, delay: 800.ms),

                const SizedBox(height: 12),

                // Guest button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInAsGuest,
                    icon: const Icon(Icons.person_outline_rounded, size: 24, color: AppColors.diamondBlue),
                    label: const Text(
                      'Continue as Guest',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.diamondBlue),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.diamondBlue.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.diamondBlue.withOpacity(0.05),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.05, delay: 900.ms),

                const SizedBox(height: 12),

                // Phone button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/otp?phone=+919876543210'),
                    icon: const Icon(Icons.phone_rounded, size: 22, color: AppColors.successGreen),
                    label: const Text(
                      'Continue with Phone',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.successGreen),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.successGreen.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.successGreen.withOpacity(0.05),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.05, delay: 1000.ms),

                const SizedBox(height: 30),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.neonPink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1100.ms),

                const SizedBox(height: 20),

                // Terms
                Text(
                  'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25)),
                ).animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
