import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool obscurePassword = true;

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 24.0,
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              //Logo with our Project Name and Subtitle
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'LoanMate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  'Student Loan Management',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                const SizedBox(height: 36),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 28.0,
                    ),
                    child: Column(
                      children: [
                        //Student ID
                        TextField(
                          controller: studentIdController,
                          keyboardType: TextInputType.text,

                          decoration: InputDecoration(
                            labelText: 'Student ID',
                            hintText: 'Enter your Student ID',
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: primaryGreen,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),

                            floatingLabelStyle: const TextStyle(
                              color: primaryGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        //Password
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,

                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: primaryGreen,
                            ),

                            //The pass visibility button
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              //Changes UI to show the pass
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: primaryGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        //Remember Me
                        CheckboxListTile(
                          value: rememberMe,

                          onChanged: (bool? newValue) {
                            setState(() {
                              rememberMe = newValue ?? false;
                            });
                          },

                          title: const Text(
                            'Remember Me',
                            style: TextStyle(fontSize: 14),
                          ),

                          activeColor: primaryGreen,
                          controlAffinity: ListTileControlAffinity.leading,

                          contentPadding: EdgeInsets.zero,
                        ),

                        const SizedBox(height: 12),

                        //Login
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              print('──────────────────────────');
                              print('Logged in');
                              print('Student ID: ${studentIdController.text}');
                              print('Password: ${passwordController.text}');
                              print('Remember Me: $rememberMe');
                              print('──────────────────────────');
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),

                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        //Forgot Password
                        TextButton(
                          onPressed: () {
                            print('Forgot Password tapped');
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        //Register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(fontSize: 14),
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
                                'Register',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
