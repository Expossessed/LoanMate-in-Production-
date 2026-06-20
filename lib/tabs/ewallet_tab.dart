import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = Supabase.instance.client;

  // ── Mutable State (loaded from Supabase) ──
  double walletBalance = 0.0;
  double remainingLoanBalance = 0.0;
  double currentSavings = 0.0;
  double targetSavings = 0.0;
  DateTime nextPaymentDate = DateTime.now().add(const Duration(days: 30));
  final double monthlyPayment = 1000.00;

  final TextEditingController payAmountController = TextEditingController();

  bool get hasInsufficientBalance => walletBalance < monthlyPayment;
  String get autoDeductionSchedule =>
      DateFormat('MMMM dd, yyyy').format(nextPaymentDate);

  List<Map<String, String>> paymentHistory = [];
  List<Map<String, String>> autoDeductionEntries = [];

  bool _isLoading = true;
  String? _walletId; // stored so we can insert transactions

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1) Fetch wallet
      try {
        final wallet = await supabase
            .from('wallet')
            .select()
            .eq('user_id', user.id)
            .single();
        walletBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
        targetSavings = (wallet['savings_goal'] as num?)?.toDouble() ?? 5000.0;
        currentSavings = (wallet['current_savings'] as num?)?.toDouble() ?? 0.0;
        _walletId = wallet['id'];
      } catch (_) {}

      // 2) Fetch remaining loan balance (sum of approved loan amounts minus paid)
      try {
        final approved = await supabase
            .from('loans')
            .select('amount')
            .eq('user_id', user.id)
            .inFilter('status', ['approved', 'active', 'partial']);
        double total = 0;
        for (var loan in approved) {
          total += (loan['amount'] as num).toDouble();
        }
        remainingLoanBalance = total;
      } catch (_) {}

      // 3) Fetch next repayment date
      try {
        final schedules = await supabase
            .from('repayment_schedule')
            .select('due_date, loan_id, loans!inner(user_id)')
            .eq('status', 'pending')
            .order('due_date', ascending: true)
            .limit(1);
        if (schedules.isNotEmpty) {
          nextPaymentDate = DateTime.parse(schedules[0]['due_date']);
        }
      } catch (_) {}

      // 4) Fetch payment history from transactions
      if (_walletId != null) {
        try {
          final payments = await supabase
              .from('transactions')
              .select()
              .eq('wallet_id', _walletId!)
              .eq('type', 'payment')
              .order('date', ascending: false);
          paymentHistory = payments.map<Map<String, String>>((item) {
            String dateFormatted = item['date']?.toString() ?? '';
            try {
              dateFormatted = DateFormat(
                'MMMM dd, yyyy',
              ).format(DateTime.parse(dateFormatted));
            } catch (_) {}
            return {
              'date': dateFormatted,
              'amount': '₱${item['amount']}',
              'status': 'Paid',
            };
          }).toList();
        } catch (_) {}

        // 5) Fetch auto-deduction log
        try {
          final deductions = await supabase
              .from('transactions')
              .select()
              .eq('wallet_id', _walletId!)
              .eq('type', 'auto_deduction')
              .order('date', ascending: false);
          autoDeductionEntries = deductions.map<Map<String, String>>((item) {
            String dateFormatted = item['date']?.toString() ?? '';
            try {
              dateFormatted = DateFormat(
                'MMMM dd, yyyy',
              ).format(DateTime.parse(dateFormatted));
            } catch (_) {}
            return {
              'description': item['description']?.toString() ?? '',
              'date': dateFormatted,
            };
          }).toList();
        } catch (_) {}
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    payAmountController.dispose();
    super.dispose();
  }

  // ── Top Up Handler ──
  void handleTopUp() async {
    final user = supabase.auth.currentUser;
    if (user == null || _walletId == null) return;

    try {
      final newBalance = walletBalance + 500.00;
      await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', user.id);
      await supabase.from('transactions').insert({
        'wallet_id': _walletId,
        'type': 'top_up',
        'amount': 500.00,
        'date': DateTime.now().toIso8601String(),
        'description': 'Wallet top-up',
      });
      setState(() => walletBalance = newBalance);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('₱500.00 added to your wallet!'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Top-up failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ── Withdraw Handler ──
  void handleWithdraw() async {
    final user = supabase.auth.currentUser;
    if (user == null || _walletId == null) return;

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
    try {
      final newBalance = walletBalance - 500.00;
      await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', user.id);
      await supabase.from('transactions').insert({
        'wallet_id': _walletId,
        'type': 'withdrawal',
        'amount': 500.00,
        'date': DateTime.now().toIso8601String(),
        'description': 'Wallet withdrawal',
      });
      setState(() => walletBalance = newBalance);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('₱500.00 withdrawn from your wallet.'),
          backgroundColor: AppColors.accentBlue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdraw failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ── Pay Loan Handler ──
  void handlePayLoan() async {
    final user = supabase.auth.currentUser;
    if (user == null || _walletId == null) return;

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
            'Insufficient balance! You have ₱${walletBalance.toStringAsFixed(2)}.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
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
      await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', user.id);
      await supabase.from('transactions').insert({
        'wallet_id': _walletId,
        'type': 'payment',
        'amount': actualPayment,
        'date': DateTime.now().toIso8601String(),
        'description': 'Paid',
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₱${actualPayment.toStringAsFixed(2)} paid!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ── Add to Savings Handler ──
  void handleAddToSavings() async {
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
    final double actualSavings = parsedAmount > maxCanSave
        ? maxCanSave
        : parsedAmount;

    try {
      final newBalance = walletBalance - actualSavings;
      final newSavings = currentSavings + actualSavings;
      await supabase
          .from('wallet')
          .update({'balance': newBalance, 'current_savings': newSavings})
          .eq('user_id', user.id);

      setState(() {
        walletBalance = newBalance;
        currentSavings = newSavings;
      });
      payAmountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '₱${actualSavings.toStringAsFixed(2)} added to savings! Progress: ₱${currentSavings.toStringAsFixed(0)}/₱${targetSavings.toStringAsFixed(0)}',
          ),
          backgroundColor: AppColors.accentBlue,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WalletBalanceCard(balance: walletBalance),
            const SizedBox(height: 16),
            if (hasInsufficientBalance) ...[
              InsufficientBalanceWarning(
                walletBalance: walletBalance,
                monthlyPayment: monthlyPayment,
              ),
              const SizedBox(height: 16),
            ],
            WalletActionButtons(
              onTopUp: handleTopUp,
              onWithdraw: handleWithdraw,
              onPayLoan: handlePayLoan,
              onAddToSavings: handleAddToSavings,
              payAmountController: payAmountController,
            ),
            const SizedBox(height: 20),
            RemainingLoanCard(remainingBalance: remainingLoanBalance),
            const SizedBox(height: 20),
            WalletSavingsGoal(
              currentSavings: currentSavings,
              targetSavings: targetSavings,
            ),
            const SizedBox(height: 20),
            AutoDeductionInfoCard(
              amount: monthlyPayment,
              schedule: autoDeductionSchedule,
            ),
            const SizedBox(height: 24),
            AutoDeductionLog(entries: autoDeductionEntries),
            const SizedBox(height: 24),
            WalletPaymentHistory(payments: paymentHistory),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
