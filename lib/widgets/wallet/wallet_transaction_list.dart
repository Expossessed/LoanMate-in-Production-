import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Full transaction list for the E-Wallet tab.
/// Displays every transaction from [transactions] with type-based colour coding.
/// Shows a combined "No transactions yet" empty state when both [transactions]
/// and [paidRepayments] are empty (so the caller can pass [paidRepayments] to
/// drive the empty state logic).
class WalletTransactionList extends StatelessWidget {
  final List<Map<String, String>> transactions;

  /// Used only to decide whether to show the combined empty state.
  final List<Map<String, String>> paidRepayments;

  const WalletTransactionList({
    super.key,
    required this.transactions,
    required this.paidRepayments,
  });

  // ── type → colour ─────────────────────────────────────────────────────────
  static Color txColor(String type) {
    switch (type) {
      case 'deposit':
        return Colors.green.shade600;
      case 'deduction':
        return Colors.red.shade600;
      case 'loan_disbursement':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  static IconData txIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icons.arrow_downward_rounded;
      case 'deduction':
        return Icons.arrow_upward_rounded;
      case 'loan_disbursement':
        return Icons.account_balance_rounded;
      case 'top_up':
        return Icons.add_circle_outline_rounded;
      case 'withdrawal':
        return Icons.arrow_circle_down_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'auto_deduction':
        return Icons.schedule_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combined empty state: no transactions AND no paid repayments
    if (transactions.isEmpty && paidRepayments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Only-transactions empty state (paid repayments exist but no wallet txs)
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No wallet transactions yet.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        // Skip system init row (account creation placeholder)
        if ((tx['type'] ?? '') == 'init') return const SizedBox.shrink();
        final type = tx['type'] ?? '';
        final color = txColor(type);
        final typeLabel = type
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Type icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(txIcon(type), color: color, size: 20),
              ),
              const SizedBox(width: 14),
              // Label + description + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if ((tx['description'] ?? '').isNotEmpty)
                      Text(
                        tx['description']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    Text(
                      tx['date'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                tx['amount'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
