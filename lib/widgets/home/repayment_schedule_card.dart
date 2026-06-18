import 'package:flutter/material.dart';

class RepaymentScheduleCard extends StatelessWidget {
  final double nextPaymentAmount;
  final String nextPaymentDate;

  static const Color accentBlue = Color(0xFF1565C0);

  const RepaymentScheduleCard({
    super.key,
    required this.nextPaymentAmount,
    required this.nextPaymentDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: accentBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Payment',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${nextPaymentAmount.toStringAsFixed(2)} — $nextPaymentDate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
