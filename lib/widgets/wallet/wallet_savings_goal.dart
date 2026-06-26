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

  // Allow progress to exceed 1.0 so overachievement is visible
  double get progress => targetSavings > 0 ? (currentSavings / targetSavings) : 0.0;

  @override
  Widget build(BuildContext context) {
    final double cappedProgress = progress.clamp(0.0, 1.0);
    final bool exceeded = progress > 1.0;
    final Color barColor = exceeded
        ? AppColors.primaryGreen
        : AppColors.savingsColor(cappedProgress);

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
                  'Monthly Savings Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: exceeded
                        ? AppColors.primaryGreen.withOpacity(0.12)
                        : barColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exceeded
                        ? '+${((progress - 1.0) * 100).toInt()}% over'
                        : '${(cappedProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: exceeded ? AppColors.primaryGreen : barColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar (capped at 100% visually)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: cappedProgress,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),

            // Peso amount label
            Text(
              exceeded
                  ? '₱${currentSavings.toStringAsFixed(0)} saved · Goal: ₱${targetSavings.toStringAsFixed(0)} ✓'
                  : '₱${currentSavings.toStringAsFixed(0)} / ₱${targetSavings.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: exceeded ? AppColors.primaryGreen : Colors.grey[600],
                fontWeight: exceeded ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
