import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../widgets/wallet/wallet_balance_card.dart';
import '../widgets/wallet/remaining_loan_card.dart';
import '../widgets/wallet/wallet_savings_goal.dart';
import '../widgets/wallet/auto_deduction_info_card.dart';
import '../widgets/wallet/auto_deduction_log.dart';
import '../widgets/wallet/wallet_payment_history.dart';
import '../widgets/wallet/wallet_action_buttons.dart';
import '../widgets/wallet/insufficient_balance_warning.dart';

class EWalletTab extends StatefulWidget {
  const EWalletTab({super.key});

  @override
  State<EWalletTab> createState() => _EWalletTabState();
}

class _EWalletTabState extends State<EWalletTab> {
  // ── Mutable State ──

  // Wallet balance — changes on top-up, withdraw, and payments
  double walletBalance = 1500.00;

  // Total loan (original amount)
  final double totalLoanBalance = 10000.00;

  // Remaining loan balance — decreases as payments are made
  double remainingLoanBalance = 8500.00;

  // Savings goal amounts
  double currentSavings = 500.00;
  final double targetSavings = 5000.00;

  // Next payment date — shifts 30 days forward when user pays manually
  DateTime nextPaymentDate = DateTime(2025, 6, 30);

  // Fixed monthly payment amount
  final double monthlyPayment = 1000.00;

  // Controller for the Pay Now input field
  final TextEditingController payAmountController = TextEditingController();

  // Check if wallet has enough funds for the monthly payment
  bool get hasInsufficientBalance => walletBalance < monthlyPayment;

  // Auto-deduction schedule label (based on next payment date)
  String get autoDeductionSchedule =>
      DateFormat('MMMM dd, yyyy').format(nextPaymentDate);

  // Payment history — grows when payments are made (auto or manual)
  List<Map<String, String>> paymentHistory = [
    {'date': 'May 30, 2025', 'amount': '₱1,000.00', 'status': 'Paid'},
    {'date': 'April 30, 2025', 'amount': '₱1,000.00', 'status': 'Paid'},
    {'date': 'March 30, 2025', 'amount': '₱1,000.00', 'status': 'Paid'},
  ];

  // Auto-deduction log — only grows on auto-deductions, NOT manual payments
  List<Map<String, String>> autoDeductionEntries = [
    {
      'description': '₱1,000.00 auto-deducted for loan payment',
      'date': 'May 30, 2025',
    },
    {
      'description': '₱1,000.00 auto-deducted for loan payment',
      'date': 'April 30, 2025',
    },
    {
      'description': '₱1,000.00 auto-deducted for loan payment',
      'date': 'March 30, 2025',
    },
  ];

  @override
  void dispose() {
    payAmountController.dispose();
    super.dispose();
  }

  // ── Top Up Handler ──
  // Adds ₱500 to wallet balance (placeholder amount)
  void handleTopUp() {
    setState(() {
      walletBalance += 500.00;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('₱500.00 added to your wallet!'),
        backgroundColor: AppColors.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Withdraw Handler ──
  // Withdraws ₱500 from wallet if sufficient balance
  void handleWithdraw() {
    if (walletBalance < 500.00) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient balance to withdraw.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      walletBalance -= 500.00;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('₱500.00 withdrawn from your wallet.'),
        backgroundColor: AppColors.accentBlue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Pay Loan Handler ──
  // Reads amount from input, deducts from wallet and loan balance,
  // logs to payment history only. Does NOT add to savings.
  void handlePayLoan() {
    if (remainingLoanBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your loan is already fully paid! 🎉'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final String inputText = payAmountController.text.trim();
    if (inputText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an amount to pay.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final double? parsedAmount = double.tryParse(inputText);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (walletBalance < parsedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance! You entered ₱${parsedAmount.toStringAsFixed(2)} '
            'but only have ₱${walletBalance.toStringAsFixed(2)}.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final double actualPayment =
        parsedAmount > remainingLoanBalance ? remainingLoanBalance : parsedAmount;

    final String todayFormatted = DateFormat(
      'MMMM dd, yyyy',
    ).format(DateTime.now());

    setState(() {
      walletBalance -= actualPayment;
      remainingLoanBalance -= actualPayment;
      nextPaymentDate = DateTime.now().add(const Duration(days: 30));

      paymentHistory.insert(0, {
        'date': todayFormatted,
        'amount': '₱${actualPayment.toStringAsFixed(2)}',
        'status': 'Paid',
      });
    });

    payAmountController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '₱${actualPayment.toStringAsFixed(2)} paid! '
          'Next payment due: ${DateFormat('MMMM dd, yyyy').format(nextPaymentDate)}',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Add to Savings Handler ──
  // Reads amount from input, deducts from wallet, adds to savings goal.
  void handleAddToSavings() {
    final String inputText = payAmountController.text.trim();
    if (inputText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an amount to save.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final double? parsedAmount = double.tryParse(inputText);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (walletBalance < parsedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance! You entered ₱${parsedAmount.toStringAsFixed(2)} '
            'but only have ₱${walletBalance.toStringAsFixed(2)}.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (currentSavings >= targetSavings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Savings goal already reached! 🎉'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final double maxCanSave = targetSavings - currentSavings;
    final double actualSavings = parsedAmount > maxCanSave ? maxCanSave : parsedAmount;

    setState(() {
      walletBalance -= actualSavings;
      currentSavings += actualSavings;
    });

    payAmountController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '₱${actualSavings.toStringAsFixed(2)} added to savings! '
          'Progress: ₱${currentSavings.toStringAsFixed(0)}/₱${targetSavings.toStringAsFixed(0)}',
        ),
        backgroundColor: AppColors.accentBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large balance card at the top
            WalletBalanceCard(balance: walletBalance),

            const SizedBox(height: 16),

            // Show warning if wallet balance is below the monthly payment
            if (hasInsufficientBalance) ...[
              InsufficientBalanceWarning(
                walletBalance: walletBalance,
                monthlyPayment: monthlyPayment,
              ),
              const SizedBox(height: 16),
            ],

            // Top Up, Withdraw, and Pay Now with input
            WalletActionButtons(
              onTopUp: handleTopUp,
              onWithdraw: handleWithdraw,
              onPayLoan: handlePayLoan,
              onAddToSavings: handleAddToSavings,
              payAmountController: payAmountController,
            ),

            const SizedBox(height: 20),

            // Remaining loan balance card
            RemainingLoanCard(remainingBalance: remainingLoanBalance),

            const SizedBox(height: 20),

            // Savings goal progress bar
            WalletSavingsGoal(
              currentSavings: currentSavings,
              targetSavings: targetSavings,
            ),

            const SizedBox(height: 20),

            // Auto-deduction info — shows ₱1,000 monthly and next date
            AutoDeductionInfoCard(
              amount: monthlyPayment,
              schedule: autoDeductionSchedule,
            ),

            const SizedBox(height: 24),

            // Auto-deduction log (only auto-deductions, not manual pays)
            AutoDeductionLog(entries: autoDeductionEntries),

            const SizedBox(height: 24),

            // Payment history (all payments — auto + manual)
            WalletPaymentHistory(payments: paymentHistory),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
