import 'package:flutter/material.dart';

// Warning banner shown when wallet balance is less than the monthly payment
class InsufficientBalanceWarning extends StatelessWidget {
  final double walletBalance;
  final double monthlyPayment;

  const InsufficientBalanceWarning({
    super.key,
    required this.walletBalance,
    required this.monthlyPayment,
  });

  @override
  Widget build(BuildContext context) {
    final double shortage = monthlyPayment - walletBalance;

    return Card(
      elevation: 3,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.red.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning icon
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),

            // Warning text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insufficient Balance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your balance (₱${walletBalance.toStringAsFixed(2)}) is less than '
                    'your monthly payment (₱${monthlyPayment.toStringAsFixed(2)}). '
                    'Please top up at least ₱${shortage.toStringAsFixed(2)} to avoid missed payments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                      height: 1.4,
                    ),
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
