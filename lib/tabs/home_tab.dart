import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/home/greeting_card.dart';
import '../widgets/home/wallet_card.dart';
import '../widgets/home/savings_progress_bar.dart';
import '../widgets/home/loan_status_chip.dart';
import '../widgets/home/approved_loan_card.dart';
import '../widgets/home/repayment_schedule_card.dart';
import '../widgets/home/loan_activity_graph.dart';
import '../widgets/home/ai_prediction_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  final String Name = 'Juan';
  final double walletBalance = 2000.00;
  final String loanStatus = 'Active';
  final int paymentDueDays = 2;
  final double savingsGoal = 10000.00;
  final double savingsBalance = 1000.00;
  final String aiEvaluation = 'Poor Standing';
  final String ID = '12312312';
  final double approvedLoanAmount = 10000.00;
  final double nextPaymentAmount = 500.00;

  String get nextPaymentDate => DateFormat(
    'MMMM dd, yyyy',
  ).format(DateTime.now().add(Duration(days: paymentDueDays)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingCard(name: Name),
            const SizedBox(height: 20),
            WalletCard(walletBalance: walletBalance, id: ID),
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
