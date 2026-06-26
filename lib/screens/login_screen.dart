import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool obscurePassword = true;
  bool _isLoading = false;

  // ── Lockout state ──────────────────────────────────────────────────────
  bool _isLocked = false;
  int _remainingSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ── Lockout countdown ─────────────────────────────────────────────────
  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _isLocked = true;
      _remainingSeconds = seconds;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isLocked = false;
          _remainingSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  String get _lockoutLabel {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return m > 0
        ? 'Try again in ${m}m ${s.toString().padLeft(2, '0')}s'
        : 'Try again in ${s}s';
  }

  // ── Sign-in handler ───────────────────────────────────────────────────
  Future<void> _handleSignIn() async {
    if (_isLocked) return;

    final studentId = studentIdController.text.trim();
    final password = passwordController.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Student ID and password.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.signIn(
      studentId: studentId,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      // Trigger lockout countdown if the response says locked
      if (result['locked'] == true) {
        final secs = (result['remaining_seconds'] as int?) ?? 300;
        _startLockoutCountdown(secs);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Green Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.only(
                top: 70.0,
                left: 30.0,
                right: 30.0,
                bottom: 40.0,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'LoanMate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Your money,\nyour future.',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'UCLM Student Financial Services',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form Section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign in to your account',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.black87,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ── Lockout Banner ──────────────────────────────────
                  if (_isLocked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock_rounded,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Account temporarily locked.\n$_lockoutLabel',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Student ID ──────────────────────────────────────
                  const Text(
                    'STUDENT ID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: studentIdController,
                    enabled: !_isLocked,
                    decoration: InputDecoration(
                      hintText: 'Enter your Student ID',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: AppColors.cardCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primaryGreen, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Password ────────────────────────────────────────
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    enabled: !_isLocked,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: AppColors.cardCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primaryGreen, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: _isLocked
                            ? null
                            : () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Sign In Button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || _isLocked) ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        disabledBackgroundColor: _isLocked
                            ? Colors.red.shade100
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : _isLocked
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_rounded,
                                        size: 18,
                                        color: Colors.red.shade400),
                                    const SizedBox(width: 8),
                                    Text(
                                      _lockoutLabel,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade500,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Divider ──────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style:
                              TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── SSO Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.book_outlined,
                          color: AppColors.primaryGreen),
                      label: const Text(
                        'Continue with University SSO',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.cardCream,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Register link ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New student? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
