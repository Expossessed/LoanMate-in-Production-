import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

// Displays the payment history with status-colored chips
class WalletPaymentHistory extends StatelessWidget {
  final List<Map<String, String>> payments;

  const WalletPaymentHistory({super.key, required this.payments});

  Widget _emptyState() {
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
          Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No repayments recorded yet.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paid repayments will appear here.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // List or empty state
        if (payments.isEmpty)
          _emptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final String status = payment['status'] ?? '';
              final Color chipColor = AppColors.walletPaymentColor(status);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  // Status-colored icon
                  leading: CircleAvatar(
                    backgroundColor: chipColor.withOpacity(0.1),
                    child: Icon(
                      AppColors.walletPaymentIcon(status),
                      color: chipColor,
                    ),
                  ),
                  // Date and amount
                  title: Text(
                    payment['date'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    payment['amount'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  // Status chip
                  trailing: Chip(
                    label: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: chipColor,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
