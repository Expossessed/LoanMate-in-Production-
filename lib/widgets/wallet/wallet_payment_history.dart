import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Displays the 5 most recent transactions of ALL types for the E-Wallet tab.
/// Each [item] in [transactions] must contain: `type`, `amount`, `date`, `description`.
class WalletPaymentHistory extends StatelessWidget {
  final List<Map<String, String>> transactions;

  const WalletPaymentHistory({super.key, required this.transactions});

  // ── Per-type visual config ──────────────────────────────────────────────
  static const _typeConfig = <String, Map<String, dynamic>>{
    'payment': {
      'label': 'Loan Payment',
      'icon': Icons.payments_rounded,
      'color': AppColors.primaryGreen,
    },
    'auto_deduction': {
      'label': 'Auto-Deduction',
      'icon': Icons.autorenew_rounded,
      'color': AppColors.accentBlue,
    },
    'top_up': {
      'label': 'Top-Up',
      'icon': Icons.add_circle_outline_rounded,
      'color': Color(0xFF4CAF50),
    },
    'withdrawal': {
      'label': 'Withdrawal',
      'icon': Icons.remove_circle_outline_rounded,
      'color': Colors.redAccent,
    },
    'savings': {
      'label': 'Savings',
      'icon': Icons.savings_outlined,
      'color': Color(0xFFF59E0B),
    },
    'init': {
      'label': 'Account Opened',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Colors.grey,
    },
  };

  Map<String, dynamic> _configFor(String type) =>
      _typeConfig[type] ??
      {
        'label': type.isNotEmpty
            ? '${type[0].toUpperCase()}${type.substring(1)}'
            : 'Transaction',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.blueGrey,
      };

  bool _isCredit(String type) =>
      type == 'top_up' || type == 'init';

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No payment history yet.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Show latest 5 only
    final display = transactions.length > 5
        ? transactions.sublist(0, 5)
        : transactions;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: display.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = display[index];
        final type = item['type'] ?? '';
        final cfg = _configFor(type);
        final color = cfg['color'] as Color;
        final IconData icon = cfg['icon'] as IconData;
        final label = cfg['label'] as String;
        final isCredit = _isCredit(type);

        final desc = item['description'] ?? '';
        final subtitle = desc.isNotEmpty ? desc : item['date'] ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
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
              // ── Icon badge ──────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Label + subtitle ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Amount pill ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCredit ? '+' : '-',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      item['amount'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
