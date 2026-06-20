import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SavingsProgressBar extends StatelessWidget {
  final double savingsGoal;
  final double savingsBalance;

  const SavingsProgressBar({
    super.key,
    required this.savingsGoal,
    required this.savingsBalance,
  });

  double get savingsProgress => savingsGoal > 0 ? savingsBalance / savingsGoal : 0.0;

  @override
  Widget build(BuildContext context) {
    final Color barColor = AppColors.savingsColor(savingsProgress);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${(savingsProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: savingsProgress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Savings Goal: ₱${(savingsBalance).toStringAsFixed(2)}/₱${savingsGoal.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
