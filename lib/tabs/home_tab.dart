import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/home/greeting_card.dart';
import '../widgets/home/wallet_card.dart';
import '../widgets/home/savings_progress_bar.dart';
import '../widgets/home/loan_status_chip.dart';
import '../widgets/home/approved_loan_card.dart';
import '../widgets/home/repayment_schedule_card.dart';
import '../widgets/home/loan_activity_graph.dart';
import '../widgets/home/ai_prediction_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final supabase = Supabase.instance.client;

  String name = '';
  String studentId = '';
  double walletBalance = 0.0;
  double savingsGoal = 0.0;
  double savingsBalance = 0.0;
  String loanStatus = 'No Loans';
  int paymentDueDays = 0;
  double approvedLoanAmount = 0.0;
  double nextPaymentAmount = 0.0;
  String aiEvaluation = 'N/A';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Run all queries IN PARALLEL using Future.wait so it's fast
    // Each one is wrapped in its own try-catch so one failure doesn't
    // stop the others from loading.
    await Future.wait([
      _loadProfile(user.id),
      _loadWallet(user.id),
      _loadLoans(user.id),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final profile = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      name = profile['first_name'] ?? '';
      studentId = profile['student_id'] ?? '';
    } catch (e) {
      print('Home: Error loading profile: $e');
    }
  }

  Future<void> _loadWallet(String userId) async {
    try {
      final wallet = await supabase
          .from('wallet')
          .select()
          .eq('user_id', userId)
          .single();
      walletBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
      savingsGoal = (wallet['savings_goal'] as num?)?.toDouble() ?? 0.0;
      savingsBalance = (wallet['current_savings'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      // No wallet yet — keep defaults
    }
  }

  Future<void> _loadLoans(String userId) async {
    try {
      final loans = await supabase
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('applied_at', ascending: false);

      if (loans.isNotEmpty) {
        // Latest loan status and AI evaluation
        loanStatus = _capitalize(loans[0]['status'] ?? 'No Loans');
        aiEvaluation = loans[0]['ai_evaluation'] ?? 'N/A';

        // Sum of approved loans
        double total = 0;
        for (var loan in loans) {
          if (loan['status'] == 'approved') {
            total += (loan['amount'] as num).toDouble();
          }
        }
        approvedLoanAmount = total;
      }
    } catch (e) {
      print('Home: Error loading loans: $e');
    }

    // Next repayment — simple query without joins
    try {
      final schedules = await supabase
          .from('repayment_schedule')
          .select()
          .eq('status', 'pending')
          .order('due_date', ascending: true)
          .limit(1);
      if (schedules.isNotEmpty) {
        nextPaymentAmount = (schedules[0]['amount'] as num).toDouble();
        final dueDate = DateTime.parse(schedules[0]['due_date']);
        paymentDueDays = dueDate.difference(DateTime.now()).inDays;
      }
    } catch (_) {}
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String get nextPaymentDate => DateFormat(
    'MMMM dd, yyyy',
  ).format(DateTime.now().add(Duration(days: paymentDueDays)));

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
            GreetingCard(name: name),
            const SizedBox(height: 20),
            WalletCard(walletBalance: walletBalance, id: studentId),
            const SizedBox(height: 20),
            SavingsProgressBar(savingsGoal: savingsGoal, savingsBalance: savingsBalance),
            const SizedBox(height: 20),
            LoanStatusChip(loanStatus: loanStatus, paymentDueDays: paymentDueDays),
            const SizedBox(height: 20),
            ApprovedLoanCard(approvedLoanAmount: approvedLoanAmount),
            const SizedBox(height: 20),
            RepaymentScheduleCard(nextPaymentAmount: nextPaymentAmount, nextPaymentDate: nextPaymentDate),
            const SizedBox(height: 20),
            const LoanActivityGraph(),
            const SizedBox(height: 20),
            AiPredictionCard(aiEvaluation: aiEvaluation),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
