import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../widgets/track_loan/apply_loan_button.dart';
import '../widgets/track_loan/ai_evaluation_card.dart';
import '../widgets/track_loan/active_loans_section.dart';
import '../widgets/track_loan/pending_loans_section.dart';
import '../widgets/track_loan/loan_history_section.dart';
import '../widgets/track_loan/recent_activity_section.dart';
import '../widgets/track_loan/next_payment_card.dart';

class LoanTab extends StatefulWidget {
  const LoanTab({super.key});

  @override
  State<LoanTab> createState() => LoanTabState();
}

class LoanTabState extends State<LoanTab> {
  final supabase = Supabase.instance.client;
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  // ── AI Evaluation (raw value from loans.ai_evaluation) ──
  String aiResult = 'N/A';
  String aiRiskLevel = 'N/A';

  // ── Active loans (from active_loans table) ──
  List<Map<String, String>> activeLoans = [];
  double totalRemainingBalance = 0.0;

  // ── Next payment from repayment_schedule ──
  String nextDueDate = '';
  String nextDueAmount = '';

  // ── Pending / history / activity (from loans table) ──
  List<Map<String, String>> pendingLoans = [];
  List<Map<String, String>> loanHistory = [];
  List<Map<String, String>> recentActivity = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public so DashboardScreen or other tabs can trigger a refresh.
  void reloadData() => _loadData();

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Reset state
    activeLoans = [];
    pendingLoans = [];
    loanHistory = [];
    recentActivity = [];
    totalRemainingBalance = 0.0;
    nextDueDate = '';
    nextDueAmount = '';
    aiResult = 'N/A';
    aiRiskLevel = 'N/A';

    try {
      // ── 1) Fetch ALL loans for this user ──
      final loans = await supabase
          .from('loans')
          .select('id, amount, purpose, status, ai_evaluation, applied_at')
          .eq('user_id', user.id)
          .order('applied_at', ascending: false);

      // Collect loan IDs for subsequent queries
      final loanIds = loans.map((l) => l['id'].toString()).toList();

      // ── 2) Fetch active_loans for this user ──
      List<dynamic> activeRows = [];
      if (loanIds.isNotEmpty) {
        try {
          activeRows = await supabase
              .from('active_loans')
              .select(
                  'id, loan_id, remaining_balance, monthly_payment, start_date, last_payment_date')
              .eq('user_id', user.id);
        } catch (e) {
          print('active_loans fetch error: $e');
        }
      }

      // Build a lookup: loan_id → active_loans row
      final Map<String, Map<String, dynamic>> activeByLoan = {};
      for (final a in activeRows) {
        activeByLoan[a['loan_id'].toString()] = a;
      }

      // ── 3) Fetch next pending repayment (first row ordered by due_date ASC) ──
      if (loanIds.isNotEmpty) {
        try {
          final schedules = await supabase
              .from('repayment_schedule')
              .select('loan_id, due_date, amount, status')
              .inFilter('loan_id', loanIds)
              .eq('status', 'pending')
              .order('due_date', ascending: true)
              .limit(1);
          if (schedules.isNotEmpty) {
            final first = schedules[0];
            try {
              nextDueDate = DateFormat('MMM dd, yyyy')
                  .format(DateTime.parse(first['due_date'].toString()));
            } catch (_) {
              nextDueDate = first['due_date']?.toString() ?? '';
            }
            nextDueAmount =
                currencyFormat.format((first['amount'] as num?)?.toDouble() ?? 0);
          }
        } catch (e) {
          print('repayment_schedule fetch error: $e');
        }
      }

      // ── 4) Categorise loans ──
      for (final loan in loans) {
        final status = loan['status']?.toString().toLowerCase() ?? 'unknown';
        final loanId = loan['id']?.toString() ?? '';
        final amount = (loan['amount'] as num?)?.toDouble() ?? 0.0;

        String dateFormatted = loan['applied_at']?.toString() ?? '';
        try {
          dateFormatted = DateFormat('MMMM dd, yyyy')
              .format(DateTime.parse(dateFormatted));
        } catch (_) {}

        final row = {
          'title': loan['purpose']?.toString() ?? 'Loan',
          'amount': currencyFormat.format(amount),
          'date': dateFormatted,
          'status': _capitalize(status),
        };

        if (status == 'pending') {
          // Skip the registration placeholder loan
          final purpose = loan['purpose']?.toString() ?? '';
          if (purpose.toLowerCase() != 'placeholder') {
            pendingLoans.add(row);
          }
        } else if (status == 'approved' ||
            status == 'active' ||
            status == 'partial') {
          // Look up active_loans row
          final activeRow = activeByLoan[loanId];
          final remaining =
              (activeRow?['remaining_balance'] as num?)?.toDouble() ?? amount;
          final monthly =
              (activeRow?['monthly_payment'] as num?)?.toDouble() ?? 0.0;

          String startDate = activeRow?['start_date']?.toString() ?? '';
          try {
            startDate =
                DateFormat('MMM dd, yyyy').format(DateTime.parse(startDate));
          } catch (_) {}

          totalRemainingBalance += remaining;

          activeLoans.add({
            'purpose': loan['purpose']?.toString() ?? 'Loan',
            'amount': currencyFormat.format(amount),
            'amount_raw': amount.toString(),
            'remaining_raw': remaining.toString(),
            'monthly_payment': currencyFormat.format(monthly),
            'start_date': startDate,
            'date': dateFormatted,
            'status': _capitalize(status),
            'next_due': nextDueDate,
          });
        } else if (status == 'rejected' || status == 'denied') {
          pendingLoans.add(row);
        } else {
          loanHistory.add(row);
        }
      }

      // ── 5) Recent activity from last 5 loans ──
      const activityIcons = {
        'approved': 'check_circle',
        'paid': 'payment',
        'pending': 'send',
        'rejected': 'cancel',
        'denied': 'cancel',
        'overdue': 'warning',
        'partial': 'payment',
        'active': 'check_circle',
      };
      for (final loan in loans.take(5)) {
        // Skip the registration placeholder
        final purpose = loan['purpose']?.toString() ?? '';
        if (purpose.toLowerCase() == 'placeholder') continue;

        final status = loan['status']?.toString() ?? 'unknown';
        final dateRaw = loan['applied_at']?.toString() ?? '';
        String dateFmt = dateRaw;
        try {
          dateFmt = DateFormat('MMMM yyyy').format(DateTime.parse(dateRaw));
        } catch (_) {}
        recentActivity.add({
          'text': 'Loan ${_capitalize(status)}',
          'date': dateFmt,
          'icon': activityIcons[status] ?? 'info_outline',
        });
      }

      // ── 6) AI evaluation — raw value from latest loan, shown as static badge ──
      if (loans.isNotEmpty) {
        final rawAi = loans[0]['ai_evaluation']?.toString() ?? 'N/A';
        aiResult = _capitalize(rawAi);
        // Simple display label: no API call, just map for badge colour
        aiRiskLevel = rawAi.toLowerCase() == 'eligible' ? 'Low Risk' : 'High Risk';
      }
    } catch (e) {
      print('Error loading loan data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load loan data: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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

    double totalOriginal = 0;
    for (final loan in activeLoans) {
      totalOriginal += double.tryParse(loan['amount_raw'] ?? '0') ?? 0;
    }
    final double totalPaid = totalOriginal - totalRemainingBalance;
    final double progress =
        totalOriginal > 0 ? (totalPaid / totalOriginal).clamp(0.0, 1.0) : 0.0;
    final int progressPct = (progress * 100).toInt();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.only(
              top: 50.0,
              left: 24.0,
              right: 24.0,
              bottom: 40.0,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius:
                  BorderRadius.only(bottomRight: Radius.circular(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOAN MANAGEMENT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track Loan',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Progress
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.redAccent,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$progressPct%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'paid',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Balances
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL LOAN',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '₱${totalOriginal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'REMAINING',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '₱${totalRemainingBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: Colors.redAccent,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ApplyLoanButton(),
                const SizedBox(height: 24),

                // AI Evaluation — static badge, raw text from loans.ai_evaluation
                AiEvaluationCard(aiResult: aiResult, aiRiskLevel: aiRiskLevel),
                const SizedBox(height: 24),

                // Next Payment card (from repayment_schedule)
                if (nextDueDate.isNotEmpty) ...[
                  NextPaymentCard(
                    dueDate: nextDueDate,
                    dueAmount: nextDueAmount,
                  ),
                  const SizedBox(height: 24),
                ],

                // Active Loans (from active_loans table)
                ActiveLoansSection(
                  activeLoans: activeLoans,
                  totalRemaining: totalRemainingBalance,
                ),
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
        ],
      ),
    );
  }

}
