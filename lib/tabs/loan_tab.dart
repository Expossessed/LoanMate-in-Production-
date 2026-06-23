import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/loan/apply_loan_button.dart';
import '../widgets/loan/ai_evaluation_card.dart';
import '../widgets/loan/active_loans_section.dart';
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
  List<Map<String, String>> activeLoans = [];
  double totalRemainingBalance = 0.0;
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

    // Reset lists before reload
    activeLoans = [];
    pendingLoans = [];
    loanHistory = [];
    recentActivity = [];
    totalRemainingBalance = 0.0;

    try {
      // ── 1) Fetch ALL loans for this user ──
      final loans = await supabase
          .from('loans')
          .select()
          .eq('user_id', user.id)
          .order('applied_at', ascending: false);

      // ── 2) Fetch repayment schedules for pending amounts ──
      // We use the active_loans view if it exists, else fall back to loans table
      Map<String, double> paidByLoan = {};
      try {
        final txLoans = await supabase
            .from('transactions')
            .select('wallet_id, amount, type')
            .eq('type', 'payment');
        // Sum payments per loan — we'll map via wallet
        // For now, remaining = original loan amount (until active_loans table exists)
      } catch (_) {}

      // ── 3) Build repayment-schedule next-due map ──
      Map<String, String> nextDueByLoan = {};
      try {
        final schedules = await supabase
            .from('repayment_schedule')
            .select('loan_id, due_date')
            .eq('status', 'pending')
            .order('due_date', ascending: true);
        for (final s in schedules) {
          final loanId = s['loan_id']?.toString() ?? '';
          if (loanId.isNotEmpty && !nextDueByLoan.containsKey(loanId)) {
            String dueFmt = s['due_date']?.toString() ?? '';
            try {
              dueFmt = DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(dueFmt));
            } catch (_) {}
            nextDueByLoan[loanId] = dueFmt;
          }
        }
      } catch (_) {}

      // ── 4) Try fetching from active_loans table (if it exists) ──
      // This gives us pre-computed remaining balances per loan.
      Map<String, double> remainingByLoan = {};
      try {
        final actives = await supabase
            .from('active_loans')
            .select('loan_id, remaining_balance')
            .eq('user_id', user.id);
        for (final a in actives) {
          final loanId = a['loan_id']?.toString() ?? '';
          final remaining = (a['remaining_balance'] as num?)?.toDouble() ?? 0.0;
          remainingByLoan[loanId] = remaining;
        }
      } catch (_) {
        // active_loans table doesn't exist yet — use loan amount as remaining
      }

      // ── 5) Categorise loans ──
      for (var loan in loans) {
        final status = loan['status']?.toString().toLowerCase() ?? 'unknown';
        final loanId = loan['id']?.toString() ?? '';
        final amount = (loan['amount'] as num?)?.toDouble() ?? 0.0;
        final dateRaw = loan['applied_at']?.toString() ?? '';
        String dateFormatted = dateRaw;
        try {
          dateFormatted = DateFormat(
            'MMMM dd, yyyy',
          ).format(DateTime.parse(dateRaw));
        } catch (_) {}

        final row = {
          'title': loan['purpose']?.toString() ?? 'Loan',
          'amount': currencyFormat.format(amount),
          'date': dateFormatted,
          'status': _capitalize(status),
        };

        if (status == 'pending' || status == 'denied' || status == 'rejected') {
          pendingLoans.add(row);
        } else if (status == 'approved' ||
            status == 'active' ||
            status == 'partial') {
          // Active loan — show with remaining balance
          final remaining = remainingByLoan[loanId] ?? amount;
          totalRemainingBalance += remaining;

          activeLoans.add({
            'purpose': loan['purpose']?.toString() ?? 'Loan',
            'amount': currencyFormat.format(amount),
            'amount_raw': amount.toString(),
            'remaining_raw': remaining.toString(),
            'date': dateFormatted,
            'status': _capitalize(status),
            'next_due': nextDueByLoan[loanId] ?? '',
          });
        } else {
          loanHistory.add(row);
        }
      }

      // ── 6) Recent activity from last 5 loans ──
      final activityIcons = {
        'approved': 'check_circle',
        'paid': 'payment',
        'pending': 'send',
        'rejected': 'cancel',
        'denied': 'cancel',
        'overdue': 'warning',
        'partial': 'payment',
        'active': 'check_circle',
      };
      for (var loan in loans.take(5)) {
        final status = loan['status']?.toString() ?? 'unknown';
        final dateRaw = loan['applied_at']?.toString() ?? '';
        String dateFormatted = dateRaw;
        try {
          dateFormatted = DateFormat(
            'MMMM yyyy',
          ).format(DateTime.parse(dateRaw));
        } catch (_) {}
        recentActivity.add({
          'text': 'Loan ${_capitalize(status)}',
          'date': dateFormatted,
          'icon': activityIcons[status] ?? 'info_outline',
        });
      }

      // ── 7) AI evaluation from latest loan ──
      if (loans.isNotEmpty) {
        final aiVal = loans[0]['ai_evaluation']?.toString() ?? 'N/A';
        aiResult = _capitalize(aiVal);
        aiRiskLevel = aiVal.toLowerCase() == 'eligible'
            ? 'Low Risk'
            : 'High Risk';
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

    double totalOriginal = 0;
    for (var loan in activeLoans) {
      totalOriginal += double.tryParse(loan['amount_raw'] ?? '0') ?? 0;
    }
    double totalPaid = totalOriginal - totalRemainingBalance;
    double progress = totalOriginal > 0
        ? (totalPaid / totalOriginal).clamp(0.0, 1.0)
        : 0.0;
    int progressPct = (progress * 100).toInt();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Dark Green with Curved Bottom) ──
          Container(
            padding: const EdgeInsets.only(
              top: 50.0,
              left: 24.0,
              right: 24.0,
              bottom: 40.0,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(80)),
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
                Text(
                  'Track Loan',
                  style: const TextStyle(
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

          // ── Body (Cream Background) ──
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ApplyLoanButton(),
                const SizedBox(height: 24),
                AiEvaluationCard(aiResult: aiResult, aiRiskLevel: aiRiskLevel),
                const SizedBox(height: 24),

                // ── Active Loans ──
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
