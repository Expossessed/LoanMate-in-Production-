import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../screens/login_screen.dart';

/// The green header block for the Loan tab showing circular repayment
/// progress plus total loan / remaining balance figures.
class LoanHeaderCard extends StatelessWidget {
  final double totalOriginal;
  final double totalRemainingBalance;

  const LoanHeaderCard({
    super.key,
    required this.totalOriginal,
    required this.totalRemainingBalance,
  });

  @override
  Widget build(BuildContext context) {
    final double totalPaid = totalOriginal - totalRemainingBalance;
    final double progress = totalOriginal > 0
        ? (totalPaid / totalOriginal).clamp(0.0, 1.0)
        : 0.0;
    final int progressPct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.only(
        top: 50.0,
        left: 24.0,
        right: 24.0,
        bottom: 40.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.white.withOpacity(0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sign out',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text(
            'LOAN MANAGEMENT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track Loan',
            style: TextStyle(
              fontFamily: 'Arial',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.redAccent,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$progressPct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'paid',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Balances column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL LOAN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '₱${totalOriginal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'REMAINING',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '₱${totalRemainingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.redAccent,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
