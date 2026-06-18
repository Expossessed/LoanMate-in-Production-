import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LoanStatusChip extends StatelessWidget {
  final String loanStatus;
  final int paymentDueDays;

  const LoanStatusChip({
    super.key,
    required this.loanStatus,
    required this.paymentDueDays,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.paymentColor(paymentDueDays);
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
          backgroundColor: AppColors.statusColor(loanStatus),
          avatar: Icon(AppColors.statusIcon(loanStatus), color: Colors.white, size: 18),
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
              AppColors.paymentIcon(paymentDueDays),
              color: Colors.white,
              size: 20,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          ),
      ],
    );
  }
}
