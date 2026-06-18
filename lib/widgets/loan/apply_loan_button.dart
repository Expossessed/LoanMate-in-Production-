import 'package:flutter/material.dart';

class ApplyLoanButton extends StatelessWidget {
  const ApplyLoanButton({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loan application submitted!'),
              backgroundColor: primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Apply for Loan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
