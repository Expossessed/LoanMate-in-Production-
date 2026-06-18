import 'package:flutter/material.dart';
import '../widgets/loan/apply_loan_button.dart';
import '../widgets/loan/ai_evaluation_card.dart';
import '../widgets/loan/loan_list_section.dart';
import '../widgets/loan/recent_activity_section.dart';

class LoanTab extends StatefulWidget {
  const LoanTab({super.key});

  @override
  State<LoanTab> createState() => LoanTabState();
}

class LoanTabState extends State<LoanTab> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  final String aiResult = 'Eligible';
  final String aiRiskLevel = 'Low Risk';

  final List<Map<String, String>> pendingLoans = const [
    {
      'title': 'Tuition Fee Loan',
      'amount': '₱5,000.00',
      'date': 'June 10, 2025',
      'status': 'Pending',
    },
    {
      'title': 'Book Allowance Loan',
      'amount': '₱2,500.00',
      'date': 'June 15, 2025',
      'status': 'Pending',
    },
  ];

  final List<Map<String, String>> loanHistory = const [
    {
      'title': 'Emergency Loan',
      'amount': '₱3,000.00',
      'date': 'May 20, 2025',
      'status': 'Paid',
    },
    {
      'title': 'Tuition Fee Loan',
      'amount': '₱8,000.00',
      'date': 'April 5, 2025',
      'status': 'Paid',
    },
    {
      'title': 'Laptop Loan',
      'amount': '₱15,000.00',
      'date': 'March 1, 2025',
      'status': 'Overdue',
    },
  ];

  final List<Map<String, String>> recentActivity = const [
    {'text': 'Loan approved', 'date': 'May 2025', 'icon': 'check_circle'},
    {'text': 'Payment received', 'date': 'April 2025', 'icon': 'payment'},
    {
      'text': 'Loan application submitted',
      'date': 'March 2025',
      'icon': 'send',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ApplyLoanButton(),
            const SizedBox(height: 24),
            AiEvaluationCard(aiResult: aiResult, aiRiskLevel: aiRiskLevel),
            const SizedBox(height: 24),
            LoanListSection(
              title: 'Pending Requests',
              loans: pendingLoans,
              emptyMessage: 'No pending loan requests.',
              showBorder: true,
            ),
            const SizedBox(height: 24),
            LoanListSection(
              title: 'Loan History',
              loans: loanHistory,
              emptyMessage: 'No loan history yet.',
              showBorder: false,
            ),
            const SizedBox(height: 24),
            RecentActivitySection(activities: recentActivity),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
