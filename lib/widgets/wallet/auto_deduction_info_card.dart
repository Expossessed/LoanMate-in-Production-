import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

// Info card showing the monthly auto-deduction amount and schedule
class AutoDeductionInfoCard extends StatelessWidget {
  final double amount;
  final String schedule;

  const AutoDeductionInfoCard({
    super.key,
    required this.amount,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.accentBlue.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            // Calendar icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.event_repeat_rounded,
                color: AppColors.accentBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Deduction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Auto-Deduction',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${amount.toStringAsFixed(2)} every $schedule',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
