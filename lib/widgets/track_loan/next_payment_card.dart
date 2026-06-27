import 'package:flutter/material.dart';

/// Orange card showing the next pending repayment due date and amount.
/// Sourced from the first pending row in `repayment_schedule`.
class NextPaymentCard extends StatelessWidget {
  final String dueDate;
  final String dueAmount;

  const NextPaymentCard({
    super.key,
    required this.dueDate,
    required this.dueAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Calendar icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Colors.orange.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT PAYMENT DUE',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueDate,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            dueAmount,
            style: TextStyle(
              fontFamily: 'Arial',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
