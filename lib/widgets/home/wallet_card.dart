import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  final double walletBalance;
  final String id;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentBlue = Color(0xFF1565C0);

  const WalletCard({
    super.key,
    required this.walletBalance,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: accentBlue.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [accentBlue, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'E-Wallet Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Balance: ₱${walletBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: $id',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
