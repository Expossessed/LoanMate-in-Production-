import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

// Displays savings progress with a LinearProgressIndicator and peso labels
class WalletSavingsGoal extends StatelessWidget {
  final double currentSavings;
  final double targetSavings;

  const WalletSavingsGoal({
    super.key,
    required this.currentSavings,
    required this.targetSavings,
  });

  double get progress => targetSavings > 0 ? (currentSavings / targetSavings).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final Color barColor = AppColors.savingsColor(progress);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with percentage
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
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),

            // Peso amount label
            Text(
              '₱${currentSavings.toStringAsFixed(0)} / ₱${targetSavings.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
