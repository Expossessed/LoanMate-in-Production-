import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart'; // kept for body section colours
import '../widgets/wallet/remaining_loan_card.dart';
import '../widgets/wallet/wallet_savings_goal.dart';
import '../widgets/wallet/auto_deduction_info_card.dart';
import '../widgets/wallet/auto_deduction_log.dart';
import '../widgets/wallet/wallet_action_buttons.dart';
import '../widgets/wallet/insufficient_balance_warning.dart';
import '../widgets/wallet/wallet_transaction_list.dart';
import '../widgets/wallet/wallet_paid_repayments.dart';
import '../widgets/wallet/wallet_payment_history.dart';
import '../widgets/wallet/ewallet_header.dart';

class EWalletTab extends StatefulWidget {
  /// Callback fired after any transaction mutates the database
  /// so the dashboard can tell other tabs to refresh.
  final VoidCallback? onDataChanged;

  const EWalletTab({super.key, this.onDataChanged});

  @override
  EWalletTabState createState() => EWalletTabState();
}

class EWalletTabState extends State<EWalletTab> {
  final supabase = Supabase.instance.client;

  // ── Mutable State (loaded from Supabase) ──
  double walletBalance = 0.0;
  double remainingLoanBalance = 0.0;
  double currentSavings = 0.0;
  double targetSavings = 0.0;
  DateTime nextPaymentDate = DateTime.now().add(const Duration(days: 30));
  double monthlyPayment = 0.0;

  final TextEditingController payAmountController = TextEditingController();

  bool get hasInsufficientBalance =>
      monthlyPayment > 0 && walletBalance < monthlyPayment;
  String get autoDeductionSchedule =>
      DateFormat('MMMM dd, yyyy').format(nextPaymentDate);

  // Full transactions list (all types)
  List<Map<String, String>> transactions = [];
  // Paid repayment_schedule rows (separate payment history section)
  List<Map<String, String>> paidRepayments = [];

  // Legacy — kept so existing handlers that insert still compile
  List<Map<String, String>> paymentHistory = [];
  List<Map<String, String>> autoDeductionEntries = [];

  bool _isLoading = true;
  String? walletId; // stored so we can insert transactions

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Public method so the DashboardScreen can trigger a re-fetch.
  void reloadData() {
    loadData();
  }

  Future<void> loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Reset lists
    transactions = [];
    paidRepayments = [];
    paymentHistory = [];
    autoDeductionEntries = [];

    try {
      // 1) Fetch wallet → balance, savings_goal, current_savings
      try {
        final wallet = await supabase
            .from('wallet')
            .select('id, balance, savings_goal, current_savings')
            .eq('user_id', user.id)
            .single();
        walletBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
        targetSavings = (wallet['savings_goal'] as num?)?.toDouble() ?? 5000.0;
        currentSavings =
            (wallet['current_savings'] as num?)?.toDouble() ?? 0.0;
        walletId = wallet['id']?.toString();
      } catch (e) {
        print('wallet fetch error: $e');
      }

      // 2) Fetch remaining loan balance from active_loans
      try {
        final activeRows = await supabase
            .from('active_loans')
            .select('remaining_balance, monthly_payment')
            .eq('user_id', user.id);
        double totalRemaining = 0;
        double totalMonthly = 0;
        for (final a in activeRows) {
          totalRemaining += (a['remaining_balance'] as num?)?.toDouble() ?? 0;
          totalMonthly += (a['monthly_payment'] as num?)?.toDouble() ?? 0;
        }
        remainingLoanBalance = totalRemaining;
        monthlyPayment = totalMonthly;
      } catch (e) {
        print('active_loans fetch error: $e');
      }

      // 3) Fetch next pending repayment date
      try {
        final schedules = await supabase
            .from('repayment_schedule')
            .select('due_date, loan_id, loans!inner(user_id)')
            .eq('loans.user_id', user.id)
            .eq('status', 'pending')
            .order('due_date', ascending: true)
            .limit(1);
        if (schedules.isNotEmpty) {
          nextPaymentDate =
              DateTime.parse(schedules[0]['due_date'].toString());
        }
      } catch (e) {
        print('repayment_schedule (next) fetch error: $e');
      }

      // 4) Fetch ALL transactions for this wallet, ordered date DESC
      if (walletId != null) {
        try {
          final txRows = await supabase
              .from('transactions')
              .select('type, amount, date, description')
              .eq('wallet_id', walletId!)
              .order('date', ascending: false);
          transactions = txRows.map<Map<String, String>>((item) {
            String dateFmt = item['date']?.toString() ?? '';
            try {
              dateFmt = DateFormat('MMM dd, yyyy')
                  .format(DateTime.parse(dateFmt));
            } catch (_) {}
            final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
            return {
              'type': item['type']?.toString() ?? '',
              'amount': '₱${amt.toStringAsFixed(2)}',
              'date': dateFmt,
              'description': item['description']?.toString() ?? '',
            };
          }).toList();

          // Keep legacy paymentHistory + autoDeductionEntries in sync
          paymentHistory = transactions
              .where((t) => t['type'] == 'payment')
              .toList();
          autoDeductionEntries = transactions
              .where((t) => t['type'] == 'auto_deduction')
              .map((t) => {
                    'description': t['description'] ?? '',
                    'date': t['date'] ?? '',
                  })
              .toList();
        } catch (e) {
          print('transactions fetch error: $e');
        }
      }

      // 5) Fetch paid repayment_schedule rows for this user's loans
      try {
        final paid = await supabase
            .from('repayment_schedule')
            .select('due_date, amount, loans!inner(user_id)')
            .eq('loans.user_id', user.id)
            .eq('status', 'paid')
            .order('due_date', ascending: false);
        paidRepayments = paid.map<Map<String, String>>((item) {
          String dateFmt = item['due_date']?.toString() ?? '';
          try {
            dateFmt =
                DateFormat('MMM dd, yyyy').format(DateTime.parse(dateFmt));
          } catch (_) {}
          final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
          return {
            'due_date': dateFmt,
            'amount': '₱${amt.toStringAsFixed(2)}',
          };
        }).toList();
      } catch (e) {
        print('paid repayments fetch error: $e');
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wallet data: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    payAmountController.dispose();
    super.dispose();
  }

  /// sends a notification when data is changed then reloads data.
  void notifyAndReload() {
    widget.onDataChanged?.call();
    loadData();
  }

  void handleTopUp() {
    showTransactionDialog(
      title: 'Top Up Wallet',
      subtitle: 'Enter the amount you want to add to your wallet.',
      icon: Icons.add_circle_outline_rounded,
      iconColor: AppColors.primaryGreen,
      buttonText: 'Top Up',
      buttonColor: AppColors.primaryGreen,
      onConfirm: (amount) => _executeTopUp(amount),
    );
  }

  Future<void> _executeTopUp(double amount) async {
    final user = supabase.auth.currentUser;
    if (user == null || walletId == null) return;

    try {
      final newBalance = walletBalance + amount;
      print(
        'DEBUG TopUp: updating wallet balance to $newBalance for user ${user.id}',
      );
      final updateResult = await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', user.id)
          .select();
      print('DEBUG TopUp: wallet update result = $updateResult');
      if (updateResult.isEmpty) {
        throw Exception(
          'Wallet update returned empty — check RLS policies on the wallet table.',
        );
      }
      final txResult = await supabase.from('transactions').insert({
        'wallet_id': walletId,
        'type': 'top_up',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'description': 'Wallet top-up',
      }).select();
      print('DEBUG TopUp: transaction insert result = $txResult');
      setState(() => walletBalance = newBalance);
      notifyAndReload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '₱${amount.toStringAsFixed(2)} added to your wallet!',
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // withdraw handler
  void handleWithdraw() {
    showTransactionDialog(
      title: 'Withdraw Funds',
      subtitle:
          'Enter the amount you want to withdraw.\nAvailable: ₱${walletBalance.toStringAsFixed(2)}',
      icon: Icons.arrow_circle_down_rounded,
      iconColor: AppColors.accentBlue,
      buttonText: 'Withdraw',
      buttonColor: AppColors.accentBlue,
      maxAmount: walletBalance,
      onConfirm: (amount) => _executeWithdraw(amount),
    );
  }

  Future<void> _executeWithdraw(double amount) async {
    final user = supabase.auth.currentUser;
    if (user == null || walletId == null) return;

    if (walletBalance < amount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insufficient balance to withdraw.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    try {
      final newBalance = walletBalance - amount;
      print(
        'DEBUG Withdraw: updating wallet balance to $newBalance for user ${user.id}',
      );
      final updateResult = await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', user.id)
          .select();
      print('DEBUG Withdraw: wallet update result = $updateResult');
      if (updateResult.isEmpty) {
        throw Exception(
          'Wallet update returned empty — check RLS policies on the wallet table.',
        );
      }
      final txResult = await supabase.from('transactions').insert({
        'wallet_id': walletId,
        'type': 'withdrawal',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'description': 'Wallet withdrawal',
      }).select();
      print('DEBUG Withdraw: transaction insert result = $txResult');
      setState(() => walletBalance = newBalance);
      notifyAndReload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '₱${amount.toStringAsFixed(2)} withdrawn from your wallet.',
            ),
            backgroundColor: AppColors.accentBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdraw failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // pay loan
  Future<void> handlePayLoan() async {
    final user = supabase.auth.currentUser;
    if (user == null || walletId == null) return;

    if (remainingLoanBalance <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your loan is already fully paid! 🎉'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final String inputText = payAmountController.text.trim();
    if (inputText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter an amount to pay.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final double? parsedAmount = double.tryParse(inputText);
    if (parsedAmount == null || parsedAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid amount.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (walletBalance < parsedAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient balance! You have ₱${walletBalance.toStringAsFixed(2)}.',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final double actualPayment = parsedAmount > remainingLoanBalance
        ? remainingLoanBalance
        : parsedAmount;
    final String todayFormatted = DateFormat(
      'MMMM dd, yyyy',
    ).format(DateTime.now());

    try {
      final newBalance = walletBalance - actualPayment;
      final updateResult = await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', user.id)
          .select();
      if (updateResult.isEmpty) {
        throw Exception('Wallet update returned empty, please report to us!');
      }
      await supabase.from('transactions').insert({
        'wallet_id': walletId,
        'type': 'payment',
        'amount': actualPayment,
        'date': DateTime.now().toIso8601String(),
        'description': 'Paid',
      }).select();

      if (!mounted) return;
      setState(() {
        walletBalance = newBalance;
        remainingLoanBalance -= actualPayment;
        nextPaymentDate = DateTime.now().add(const Duration(days: 30));
        paymentHistory.insert(0, {
          'date': todayFormatted,
          'amount': '₱${actualPayment.toStringAsFixed(2)}',
          'status': 'Paid',
        });
      });
      payAmountController.clear();
      notifyAndReload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₱${actualPayment.toStringAsFixed(2)} paid!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // savings handler
  Future<void> handleAddToSavings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

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
            'Insufficient balance! You have ₱${walletBalance.toStringAsFixed(2)}.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final double actualSavings = parsedAmount;

    try {
      final newBalance = walletBalance - actualSavings;
      final newSavings = currentSavings + actualSavings;
      final updateResult = await supabase
          .from('wallet')
          .update({'balance': newBalance, 'current_savings': newSavings})
          .eq('user_id', user.id)
          .select();
      if (updateResult.isEmpty) {
        throw Exception(
          'Wallet update returned empty — check RLS policies on the wallet table.',
        );
      }

      // logs the savings transfer as a transaction
      if (walletId != null) {
        await supabase.from('transactions').insert({
          'wallet_id': walletId,
          'type': 'savings',
          'amount': actualSavings,
          'date': DateTime.now().toIso8601String(),
          'description': 'Added to savings',
        }).select();
      }

      if (!mounted) return;
      setState(() {
        walletBalance = newBalance;
        currentSavings = newSavings;
      });
      payAmountController.clear();
      notifyAndReload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '₱${actualSavings.toStringAsFixed(2)} added to savings! Total: ₱${newSavings.toStringAsFixed(0)}',
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // transaction popup dialog
  void showTransactionDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required Color buttonColor,
    double? maxAmount,
    required Future<void> Function(double amount) onConfirm,
  }) {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.all(28),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 32),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // input amount
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          prefixText: '₱ ',
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: iconColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          if (maxAmount != null && parsed > maxAmount) {
                            return 'Maximum: ₱${maxAmount.toStringAsFixed(2)}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      //amount chips
                      Wrap(
                        spacing: 8,
                        children: [100, 500, 1000, 2000].map((amt) {
                          return ActionChip(
                            label: Text(
                              '₱$amt',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                            backgroundColor: iconColor.withOpacity(0.08),
                            side: BorderSide(color: iconColor.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () {
                              amountController.text = amt.toString();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final amount = double.parse(
                                          amountController.text.trim(),
                                        );
                                        setDialogState(
                                          () => isProcessing = true,
                                        );
                                        await onConfirm(amount);
                                        if (dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      buttonText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Dark Green with Curved Bottom) ──
          EWalletHeader(
            walletBalance: walletBalance,
            currentSavings: currentSavings,
          ),

          // ── Body (Cream Background) ──
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remaining Loan Card — only shown when there is an active loan
                if (remainingLoanBalance > 0) ...[
                  RemainingLoanCard(
                    remainingBalance: remainingLoanBalance,
                    monthlyPayment: monthlyPayment,
                  ),
                  const SizedBox(height: 24),
                ],

                // Original functional buttons (kept for Pay Loan / Add to Savings)
                const Text(
                  'Manual Transactions',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                WalletActionButtons(
                  onTopUp: handleTopUp,
                  onWithdraw: handleWithdraw,
                  onPayLoan: handlePayLoan,
                  onAddToSavings: handleAddToSavings,
                  payAmountController: payAmountController,
                ),
                const SizedBox(height: 24),

                if (hasInsufficientBalance && remainingLoanBalance > 0) ...[
                  InsufficientBalanceWarning(
                    walletBalance: walletBalance,
                    monthlyPayment: monthlyPayment,
                  ),
                  const SizedBox(height: 16),
                ],

                // Auto-Deduct
                if (remainingLoanBalance > 0) ...[
                  AutoDeductionInfoCard(
                    amount: monthlyPayment,
                    schedule: autoDeductionSchedule,
                  ),
                  const SizedBox(height: 24),
                  AutoDeductionLog(entries: autoDeductionEntries),
                  const SizedBox(height: 24),
                ],

                // Monthly Savings Goal Section
                Text(
                  'Monthly Savings Goal',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 16),
                WalletSavingsGoal(
                  currentSavings: currentSavings,
                  targetSavings: targetSavings,
                ),
                const SizedBox(height: 32),

                // ── Transaction History ──
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 16),
                WalletTransactionList(
                  transactions: transactions,
                  paidRepayments: paidRepayments,
                ),
                const SizedBox(height: 32),

                // ── Payment History ──
                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 16),
                // All-types history capped at 5
                WalletPaymentHistory(transactions: transactions),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
