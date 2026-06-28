import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../widgets/track_loan/ai_evaluation_card.dart';
import '../widgets/track_loan/active_loans_section.dart';
import '../widgets/track_loan/pending_loans_section.dart';
import '../widgets/track_loan/loan_history_section.dart';
import '../widgets/track_loan/recent_activity_section.dart';
import '../widgets/track_loan/next_payment_card.dart';
import '../widgets/track_loan/loan_header_card.dart';

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
  double totalOriginalAmount = 0.0; // sum of active_loans.original_amount

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
    totalOriginalAmount = 0.0;
    nextDueDate = '';
    nextDueAmount = '';
    aiResult = 'N/A';
    aiRiskLevel = 'N/A';

    try {
      // ── 1) Fetch ALL loans for this user (pending / history / activity / AI) ──
      final loans = await supabase
          .from('loans')
          .select('id, amount, purpose, status, ai_evaluation, applied_at')
          .eq('user_id', user.id)
          .order('applied_at', ascending: false);

      final loanIds = loans.map((l) => l['id'].toString()).toList();

      // Build a lookup: loan_id → loans row (for purpose / applied_at)
      final Map<String, Map<String, dynamic>> loanById = {};
      for (final l in loans) {
        loanById[l['id'].toString()] = l;
      }

      // ── 2) Fetch active_loans directly — source of truth for active loans ──
      List<dynamic> activeRows = [];
      try {
        activeRows = await supabase
            .from('active_loans')
            .select(
              'id, loan_id, original_amount, remaining_balance, monthly_payment, start_date, last_payment_date',
            )
            .eq('user_id', user.id)
            .order('start_date', ascending: false);
        // Filter out registration placeholders (original_amount == 0)
        activeRows = activeRows
            .where((r) => ((r['original_amount'] as num?)?.toDouble() ?? 0) > 0)
            .toList();
      } catch (e) {
        print('active_loans fetch error: $e');
      }

      // Track which loan_ids are in active_loans (to exclude from pending/history)
      final Set<String> activeLoanIds = {};

      for (final row in activeRows) {
        final loanId = row['loan_id']?.toString() ?? '';
        final loanRow = loanById[loanId];
        final original = (row['original_amount'] as num?)?.toDouble() ?? 0.0;
        final remaining =
            (row['remaining_balance'] as num?)?.toDouble() ?? original;
        final monthly = (row['monthly_payment'] as num?)?.toDouble() ?? 0.0;

        totalOriginalAmount += original;
        totalRemainingBalance += remaining;

        // ── Fully paid: move to history, remove from active display ──
        if (remaining <= 0) {
          // Mark the loan_id as handled so step 4 won't double-add it
          activeLoanIds.add(loanId);
          String appliedDate = loanRow?['applied_at']?.toString() ?? '';
          try {
            appliedDate = DateFormat('MMMM dd, yyyy')
                .format(DateTime.parse(appliedDate));
          } catch (_) {}
          loanHistory.add({
            'title': loanRow?['purpose']?.toString() ?? 'Loan',
            'amount': currencyFormat.format(original),
            'date': appliedDate,
            'status': 'Paid',
          });
          continue; // don't add to activeLoans
        }

        // ── Still has a balance: show in active section ──
        activeLoanIds.add(loanId);

        String startDate = row['start_date']?.toString() ?? '';
        try {
          startDate = DateFormat(
            'MMM dd, yyyy',
          ).format(DateTime.parse(startDate));
        } catch (_) {}

        String appliedDate = loanRow?['applied_at']?.toString() ?? '';
        try {
          appliedDate = DateFormat(
            'MMMM dd, yyyy',
          ).format(DateTime.parse(appliedDate));
        } catch (_) {}

        activeLoans.add({
          'purpose': loanRow?['purpose']?.toString() ?? 'Loan',
          'amount': currencyFormat.format(
            original,
          ), // original_amount from active_loans
          'amount_raw': original.toString(),
          'remaining_raw': remaining.toString(),
          'monthly_payment': currencyFormat.format(monthly),
          'start_date': startDate,
          'date': appliedDate,
          'status': 'Active',
          'next_due': '', // patched below after schedule query
        });
      } // end for(activeRows)

      // ── 3) Fetch next pending repayment ──
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
              nextDueDate = DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(first['due_date'].toString()));
            } catch (_) {
              nextDueDate = first['due_date']?.toString() ?? '';
            }
            nextDueAmount = currencyFormat.format(
              (first['amount'] as num?)?.toDouble() ?? 0,
            );

            // Patch next_due into each active loan card
            for (var i = 0; i < activeLoans.length; i++) {
              activeLoans[i] = {...activeLoans[i], 'next_due': nextDueDate};
            }
          }
        } catch (e) {
          print('repayment_schedule fetch error: $e');
        }
      }

      // ── 4) Categorise remaining loans (pending / history) ──
      for (final loan in loans) {
        final status = loan['status']?.toString().toLowerCase() ?? 'unknown';
        final loanId = loan['id']?.toString() ?? '';
        final amount = (loan['amount'] as num?)?.toDouble() ?? 0.0;
        final purpose = loan['purpose']?.toString() ?? '';

        // Skip registration placeholder
        if (purpose.toLowerCase() == 'placeholder') continue;
        // Skip loans already shown in the active section
        if (activeLoanIds.contains(loanId)) continue;

        String dateFormatted = loan['applied_at']?.toString() ?? '';
        try {
          dateFormatted = DateFormat(
            'MMMM dd, yyyy',
          ).format(DateTime.parse(dateFormatted));
        } catch (_) {}

        final row = {
          'title': purpose,
          'amount': currencyFormat.format(amount),
          'date': dateFormatted,
          'status': _capitalize(status),
        };

        if (status == 'pending') {
          pendingLoans.add(row);
        } else if (status == 'rejected' || status == 'denied') {
          // Denied/rejected are final — show in history with red colour, not pending
          loanHistory.add(row);
        } else {
          loanHistory.add(row);
        }
      }

      // ── 5) Recent activity — loan status events + actual payments ──
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
          'sort_key': dateRaw,
        });
      }

      // ── 5b) Fetch actual payment/auto_deduction transactions ──
      try {
        final walletRow = await supabase
            .from('wallet')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (walletRow != null) {
          final walletId = walletRow['id']?.toString();
          if (walletId != null) {
            final txRows = await supabase
                .from('transactions')
                .select('type, amount, date, description')
                .eq('wallet_id', walletId)
                .inFilter('type', ['payment', 'auto_deduction'])
                .order('date', ascending: false)
                .limit(5);
            for (final tx in txRows) {
              final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
              final type = tx['type']?.toString() ?? 'payment';
              final dateRaw = tx['date']?.toString() ?? '';
              String dateFmt = dateRaw;
              try {
                dateFmt = DateFormat('MMM dd, yyyy')
                    .format(DateTime.parse(dateRaw));
              } catch (_) {}
              recentActivity.add({
                'text': type == 'auto_deduction'
                    ? 'Auto-Deduction  ₱${amt.toStringAsFixed(2)}'
                    : 'Loan Payment  ₱${amt.toStringAsFixed(2)}',
                'date': dateFmt,
                'icon': 'payment',
                'sort_key': dateRaw,
              });
            }
          }
        }
      } catch (_) {}

      // Sort merged activity newest-first and cap at 8
      recentActivity.sort((a, b) =>
          (b['sort_key'] ?? '').compareTo(a['sort_key'] ?? ''));
      if (recentActivity.length > 8) {
        recentActivity = recentActivity.sublist(0, 8);
      }

      // ── 6) AI evaluation — raw value from latest loan ──
      if (loans.isNotEmpty) {
        final rawAi = loans[0]['ai_evaluation']?.toString() ?? 'N/A';
        aiResult = _capitalize(rawAi);
        aiRiskLevel = rawAi.toLowerCase() == 'eligible'
            ? 'Low Risk'
            : 'High Risk';
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

    // Use active_loans.original_amount (already summed during _loadData)
    final double totalOriginal = totalOriginalAmount;
    final double totalPaid = totalOriginal - totalRemainingBalance;
    final double progress = totalOriginal > 0
        ? (totalPaid / totalOriginal).clamp(0.0, 1.0)
        : 0.0;
    final int progressPct = (progress * 100).toInt();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          LoanHeaderCard(
            totalOriginal: totalOriginal,
            totalRemainingBalance: totalRemainingBalance,
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
