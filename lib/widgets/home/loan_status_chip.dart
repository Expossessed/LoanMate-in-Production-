import 'package:flutter/material.dart';

class LoanStatusChip extends StatelessWidget {
  final String loanStatus;
  final int paymentDueDays;

  static const Color primaryGreen = Color(0xFF2E7D32);

  const LoanStatusChip({
    super.key,
    required this.loanStatus,
    required this.paymentDueDays,
  });

  Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return primaryGreen;
      case 'paid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.grey.shade900;
    }
  }

  IconData statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'paid':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'overdue':
        return Icons.error_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color paymentColor() {
    if (paymentDueDays < 0) return Colors.red;
    if (paymentDueDays <= 3) return Colors.red;
    if (paymentDueDays <= 7) return Colors.orange;
    if (paymentDueDays <= 10) return Colors.yellow;
    if (paymentDueDays >= 15) return Colors.green;
    return Colors.amber.shade700;
  }

  IconData paymentIcon(int days) {
    if (days < 0) return Icons.check_circle;
    if (days == 0) return Icons.error_outline_rounded;
    if (days <= 3) return Icons.error_outline_rounded;
    if (days <= 7)
      return Icons.access_time_rounded;
    else
      return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    Color color = paymentColor();
    final String msg = paymentDueDays == 1
        ? 'Pay tomorrow!'
        : 'Pay within $paymentDueDays days';
    return Row(
      children: [
        const Text(
          'Loan Status:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Chip(
          label: Text(
            loanStatus,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: statusColor(loanStatus),
          avatar: Icon(statusIcon(loanStatus), color: Colors.white, size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        const SizedBox(width: 6),
        if (paymentDueDays > 0)
          Chip(
            label: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: color,
            avatar: Icon(
              paymentIcon(paymentDueDays),
              color: Colors.white,
              size: 20,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          ),
      ],
    );
  }
}
