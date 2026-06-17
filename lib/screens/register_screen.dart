import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController yearLevelController = TextEditingController();

  bool agreeToTerms = false;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    courseController.dispose();
    yearLevelController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    bool isObscured = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon, color: primaryGreen),

        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              )
            : null,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),

        floatingLabelStyle: const TextStyle(color: primaryGreen),
      ),
    );
  }

  //Alert popup saying "You are now registered!"
  void showRegisteredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          icon: const Icon(
            Icons.check_circle_rounded,
            color: primaryGreen,
            size: 64,
          ),

          title: const Text(
            'Registration Successful',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: const Text(
            'You are now registered!\nYou can now log in with your Student ID and password.',
            textAlign: TextAlign.center,
          ),

          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // takes you back to login screen
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  //Register Checker
  void handleRegister() {
    if (studentIdController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        courseController.text.trim().isEmpty ||
        yearLevelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms & Conditions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('══════════════════════════════');
    print('REGISTERED (dummy data)');
    print('Student ID : ${studentIdController.text}');
    print(
      'Name       : ${firstNameController.text} ${lastNameController.text}',
    );
    print('Course     : ${courseController.text}');
    print('Year Level : ${yearLevelController.text}');
    print('══════════════════════════════');

    showRegisteredDialog();
  }

  //Register UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),

          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'LoanMate',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Fill in your details to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              //Fillup Form
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    children: [
                      buildTextField(
                        controller: studentIdController,
                        label: 'Student ID',
                        hint: 'Enter your Student ID',
                        icon: Icons.badge_outlined,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: firstNameController,
                              label: 'First Name',
                              hint: '',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildTextField(
                              controller: lastNameController,
                              label: 'Last Name',
                              hint: '',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: courseController,
                              label: 'Course',
                              hint: '',
                              icon: Icons.school_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildTextField(
                              controller: yearLevelController,
                              label: 'Year Level',
                              hint: '',
                              icon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      buildTextField(
                        controller: passwordController,
                        label: 'Password',
                        hint: 'Create a password',
                        icon: Icons.lock_outline,
                        obscure: obscurePassword,
                        isObscured: obscurePassword,
                        toggleObscure: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      buildTextField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline,
                        obscure: obscureConfirmPassword,
                        isObscured: obscureConfirmPassword,
                        toggleObscure: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      //Terms & Conditions (To be remade)
                      Row(
                        children: [
                          Checkbox(
                            value: agreeToTerms,
                            activeColor: primaryGreen,
                            onChanged: (bool? newValue) {
                              setState(() {
                                agreeToTerms = newValue ?? false;
                              });
                            },
                          ),

                          Flexible(
                            child: Wrap(
                              children: [
                                const Text(
                                  'I agree to the ',
                                  style: TextStyle(fontSize: 13),
                                ),

                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          title: const Text(
                                            'Terms & Conditions',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryGreen,
                                            ),
                                          ),
                                          content: const SingleChildScrollView(
                                            child: Text(
                                              'These are placeholder Terms & Conditions *(to be remade).\n\n'
                                              '1. You agree to use LoanMate responsibly.\n'
                                              '2. All loan data shown is for demonstration purposes only.\n'
                                              '3. Your personal information will be kept confidential.\n'
                                              '4. Misuse of the app may result in account suspension.\n'
                                              '5. LoanMate is a capstone project and is not a real financial service.\n\n'
                                              'By creating an account, you acknowledge that you have read and understood these terms.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text(
                                                'Close',
                                                style: TextStyle(
                                                  color: primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Text(
                                    'Terms & Conditions',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      //Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: agreeToTerms ? handleRegister : null,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,

                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),

                          child: const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      //Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Login',
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
