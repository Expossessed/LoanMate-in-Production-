import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';

class HomeRecentActivity extends StatelessWidget {
  final List<Map<String, dynamic>> recentTransactions;

  const HomeRecentActivity({super.key, required this.recentTransactions});

  static const _inflowTypes = {'top_up', 'loan_disbursement', 'refund'};

  String _typeLabel(String type) {
    switch (type) {
      case 'top_up':
        return 'Top Up';
      case 'withdrawal':
        return 'Withdrawal';
      case 'payment':
        return 'Loan Payment';
      case 'savings':
        return 'Savings Deposit';
      case 'loan_disbursement':
        return 'Loan Disbursed';
      case 'auto_deduction':
        return 'Auto Deduction';
      case 'refund':
        return 'Refund';
      default:
        final s = type.replaceAll('_', ' ');
        return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    }
  }

  IconData _typeIcon(bool isInflow) =>
      isInflow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          ...recentTransactions.take(5).map((tx) {
            final type = tx['type']?.toString() ?? '';
            final isInflow = _inflowTypes.contains(type);
            final color = isInflow ? AppColors.primaryGreen : Colors.redAccent;
            final bgColor = isInflow
                ? AppColors.primaryGreen.withOpacity(0.1)
                : Colors.redAccent.withOpacity(0.08);
            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            final sign = isInflow ? '+' : '-';
            final label = _typeLabel(type);
            final icon = _typeIcon(isInflow);

            final rawDate = tx['date']?.toString() ?? '';
            final date = DateTime.tryParse(rawDate) ?? DateTime.now();
            final dayStr = DateFormat('MMM dd').format(date);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.replaceAll('_', ' ').toLowerCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign₱${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
