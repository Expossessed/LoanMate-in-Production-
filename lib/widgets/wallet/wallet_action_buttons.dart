import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class WalletActionButtons extends StatelessWidget {
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
  final VoidCallback onPayLoan;
  final VoidCallback onAddToSavings;
  final TextEditingController payAmountController;

  const WalletActionButtons({
    super.key,
    required this.onTopUp,
    required this.onWithdraw,
    required this.onPayLoan,
    required this.onAddToSavings,
    required this.payAmountController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Up and Withdraw row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTopUp,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  'Top Up',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onWithdraw,
                icon: const Icon(Icons.arrow_circle_down_rounded, size: 18),
                label: const Text(
                  'Withdraw',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Amount input field (full width)
        TextField(
          controller: payAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter amount (₱)',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
            prefixIcon: const Icon(
              Icons.payments_outlined,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 10),

        // Pay Loan and Add to Savings row (below the input)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPayLoan,
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text(
                  'Pay Loan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddToSavings,
                icon: const Icon(Icons.savings_rounded, size: 18),
                label: const Text(
                  'Add to Savings',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
