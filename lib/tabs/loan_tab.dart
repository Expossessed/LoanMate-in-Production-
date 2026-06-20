import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/loan/apply_loan_button.dart';
import '../widgets/loan/ai_evaluation_card.dart';
import '../widgets/loan/pending_loans_section.dart';
import '../widgets/loan/loan_history_section.dart';
import '../widgets/loan/recent_activity_section.dart';

class LoanTab extends StatefulWidget {
  const LoanTab({super.key});

  @override
  State<LoanTab> createState() => LoanTabState();
}

class LoanTabState extends State<LoanTab> {
  final supabase = Supabase.instance.client;
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  String aiResult = 'N/A';
  String aiRiskLevel = 'N/A';
  List<Map<String, String>> pendingLoans = [];
  List<Map<String, String>> loanHistory = [];
  List<Map<String, String>> recentActivity = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch ALL loans for this user
      final loans = await supabase
          .from('loans')
          .select()
          .eq('user_id', user.id)
          .order('applied_at', ascending: false);

      // Separate into pending and history
      for (var loan in loans) {
        final status = loan['status']?.toString() ?? 'unknown';
        final amount = (loan['amount'] as num?)?.toDouble() ?? 0.0;
        final dateRaw = loan['applied_at']?.toString() ?? '';
        String dateFormatted = dateRaw;
        try {
          dateFormatted = DateFormat('MMMM dd, yyyy').format(DateTime.parse(dateRaw));
        } catch (_) {}

        final row = {
          'title': loan['purpose']?.toString() ?? 'Loan',
          'amount': currencyFormat.format(amount),
          'date': dateFormatted,
          'status': _capitalize(status),
        };

        if (status == 'pending' || status == 'denied' || status == 'rejected') {
          pendingLoans.add(row);
        } else {
          loanHistory.add(row);
        }
      }

      // Build recent activity from the last 5 loans
      final activityIcons = {
        'approved': 'check_circle',
        'paid': 'payment',
        'pending': 'send',
        'rejected': 'cancel',
        'denied': 'cancel',
        'overdue': 'warning',
        'partial': 'payment',
      };
      for (var loan in loans.take(5)) {
        final status = loan['status']?.toString() ?? 'unknown';
        final dateRaw = loan['applied_at']?.toString() ?? '';
        String dateFormatted = dateRaw;
        try {
          dateFormatted = DateFormat('MMMM yyyy').format(DateTime.parse(dateRaw));
        } catch (_) {}

        recentActivity.add({
          'text': 'Loan ${_capitalize(status)}',
          'date': dateFormatted,
          'icon': activityIcons[status] ?? 'info_outline',
        });
      }

      // AI evaluation from the latest loan
      if (loans.isNotEmpty) {
        final aiVal = loans[0]['ai_evaluation']?.toString() ?? 'N/A';
        aiResult = _capitalize(aiVal);
        aiRiskLevel = aiVal.toLowerCase() == 'eligible' ? 'Low Risk' : 'High Risk';
      }
    } catch (e) {
      print('Error loading loan data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
            const ApplyLoanButton(),
            const SizedBox(height: 24),
            AiEvaluationCard(aiResult: aiResult, aiRiskLevel: aiRiskLevel),
            const SizedBox(height: 24),
            PendingLoansSection(loans: pendingLoans),
            const SizedBox(height: 24),
            LoanHistorySection(loans: loanHistory),
            const SizedBox(height: 24),
            RecentActivitySection(activities: recentActivity),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
