import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
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
  HomeTabState createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final supabase = Supabase.instance.client;

  String name = '';
  String studentId = '';
  double walletBalance = 0.0;
  double savingsGoal = 0.0;
  double savingsBalance = 0.0;
  String loanStatus = 'No Loans';
  // Active loan data
  Map<String, dynamic>? activeLoan; // the raw active loan row
  double activeLoanTotal = 0.0;     // original approved amount
  double activeLoanRemaining = 0.0; // remaining (total - paid)
  double activeLoanPaid = 0.0;      // amount already paid
  String activeLoanPurpose = '';
  DateTime? activeLoanApprovedDate;
  DateTime? nextPaymentDate;
  // Savings this month
  double monthlySavingsAdded = 0.0;
  // Payment transactions (for repayment progress)
  List<Map<String, dynamic>> paymentTransactions = [];
  String? walletId;
  List<Map<String, dynamic>> recentTransactions = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Public method so that the DashboardScreen can trigger a re-fetch
  /// whenever the EWallet tab mutates the database.
  void reloadData() {
    loadData();
  }

  Future<void> loadData() async {
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
      walletId = wallet['id'];

      if (walletId != null) {
        // Recent transactions (for activity feed) — exclude system 'init' rows
        try {
          final txs = await supabase
              .from('transactions')
              .select()
              .eq('wallet_id', walletId!)
              .order('date', ascending: false)
              .limit(10); // fetch extra so we still get 5 after filtering
          recentTransactions = List<Map<String, dynamic>>.from(txs)
              .where((tx) => (tx['type']?.toString() ?? '') != 'init')
              .take(5)
              .toList();
        } catch (_) {}

        // Payment transactions for repayment progress
        try {
          final pmts = await supabase
              .from('transactions')
              .select('amount, date')
              .eq('wallet_id', walletId!)
              .eq('type', 'payment')
              .order('date', ascending: true);
          paymentTransactions = List<Map<String, dynamic>>.from(pmts);
        } catch (_) {}

        // Monthly savings added (sum of savings-type tx in current month)
        try {
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
          final monthEnd = DateTime(now.year, now.month + 1, 1).toIso8601String();
          final savingsTxs = await supabase
              .from('transactions')
              .select('amount')
              .eq('wallet_id', walletId!)
              .eq('type', 'savings')
              .gte('date', monthStart)
              .lt('date', monthEnd);
          double total = 0;
          for (final tx in savingsTxs) {
            total += (tx['amount'] as num?)?.toDouble() ?? 0.0;
          }
          monthlySavingsAdded = total;
        } catch (_) {}
      }
    } catch (_) {
      // No wallet yet — keep defaults
    }
  }

  Future<void> _loadLoans(String userId) async {
    // Reset
    activeLoan = null;
    activeLoanTotal = 0;
    activeLoanRemaining = 0;
    activeLoanPaid = 0;
    activeLoanPurpose = '';
    activeLoanApprovedDate = null;
    nextPaymentDate = null;

    try {
      final loans = await supabase
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('applied_at', ascending: false);

      if (loans.isNotEmpty) {
        loanStatus = _capitalize(loans[0]['status'] ?? 'No Loans');

        // Find the most recent active/approved loan
        for (final loan in loans) {
          final status = loan['status']?.toString().toLowerCase() ?? '';
          if (status == 'approved' || status == 'active' || status == 'partial') {
            activeLoan = loan;
            activeLoanTotal = (loan['amount'] as num?)?.toDouble() ?? 0.0;
            activeLoanPurpose = _capitalize(loan['purpose']?.toString() ?? 'Loan');
            final rawDate = loan['applied_at']?.toString() ?? '';
            try {
              activeLoanApprovedDate = DateTime.parse(rawDate);
            } catch (_) {}
            break;
          }
        }
      }
    } catch (e) {
      print('Home: Error loading loans: $e');
    }

    if (activeLoan == null) return;

    // How much has been paid (sum of payment-type transactions on this wallet)
    if (walletId != null) {
      try {
        final payments = await supabase
            .from('transactions')
            .select('amount')
            .eq('wallet_id', walletId!)
            .eq('type', 'payment');
        double paid = 0;
        for (final p in payments) {
          paid += (p['amount'] as num?)?.toDouble() ?? 0.0;
        }
        activeLoanPaid = paid;
        activeLoanRemaining = (activeLoanTotal - paid).clamp(0.0, activeLoanTotal);
      } catch (_) {}
    }

    // Next pending repayment schedule entry
    try {
      final schedules = await supabase
          .from('repayment_schedule')
          .select('due_date, amount')
          .eq('status', 'pending')
          .order('due_date', ascending: true)
          .limit(1);
      if (schedules.isNotEmpty) {
        nextPaymentDate = DateTime.tryParse(schedules[0]['due_date']?.toString() ?? '');
      }
    } catch (_) {}
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
              bottom: 30.0,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WELCOME BACK',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.isEmpty ? 'Student' : name,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // E-Wallet Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'E-WALLET BALANCE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: Colors.white,
                              fontSize: 42,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
                            child: Text(
                              '.${(walletBalance % 1 * 100).toInt().toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Quick Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(Icons.arrow_upward_rounded, 'Send'),
                          _buildActionButton(Icons.arrow_downward_rounded, 'Receive'),
                          _buildActionButton(Icons.add, 'Apply'),
                          _buildActionButton(Icons.history_rounded, 'History'),
                        ],
                      ),
                    ],
                  ),
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
                // Active Loan Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Loan',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                        fontSize: 22,
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Track',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Loan Card — dynamic
                if (activeLoan == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.cardCream,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.credit_card_off_rounded, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No Active Loan',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apply for a loan to get started',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Builder(builder: (_) {
                    final repaidPct = activeLoanTotal > 0
                        ? (activeLoanPaid / activeLoanTotal).clamp(0.0, 1.0)
                        : 0.0;
                    final repaidPctInt = (repaidPct * 100).toInt();
                    final approvedStr = activeLoanApprovedDate != null
                        ? DateFormat('MMM dd, yyyy').format(activeLoanApprovedDate!)
                        : '—';
                    final nextStr = nextPaymentDate != null
                        ? DateFormat('MMM dd, yyyy').format(nextPaymentDate!)
                        : '—';
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardCream,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        activeLoanPurpose.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'REMAINING',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₱${activeLoanTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontFamily: 'Arial',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                        color: Colors.black87,
                                        fontSize: 32,
                                      ),
                                    ),
                                    Text(
                                      '₱${activeLoanRemaining.toStringAsFixed(0)}',
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
                                const SizedBox(height: 4),
                                Text(
                                  'Approved $approvedStr',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: repaidPct,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$repaidPctInt% repaid · ₱${activeLoanPaid.toStringAsFixed(0)} paid',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      'Next: $nextStr',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 16),

                // Row of small cards (Savings & Score)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardCream,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.track_changes_rounded,
                                  color: AppColors.primaryGreen,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'SAVINGS',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '₱${savingsBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: Colors.black87,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              monthlySavingsAdded > 0
                                  ? '+₱${monthlySavingsAdded.toStringAsFixed(0)} this month'
                                  : 'No savings this month',
                              style: TextStyle(
                                color: monthlySavingsAdded > 0
                                    ? AppColors.primaryGreen
                                    : Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardCream,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.star_border_rounded,
                                  color: Colors.red.shade400,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'SCORE',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '742',
                              style: const TextStyle(
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: Colors.black87,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Excellent',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ── Repayment Progress ──
                _buildRepaymentProgress(),

                const SizedBox(height: 30),

                // ── Recent Activity ──
                _buildRecentActivity(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Repayment Progress',
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              if (paymentTransactions.isNotEmpty)
                Text(
                  '${paymentTransactions.length} payment${paymentTransactions.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),

          if (paymentTransactions.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No payments yet',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your repayments will appear here',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 24),
            // Cumulative total summary
            Builder(builder: (_) {
              double totalPaid = paymentTransactions.fold(
                0.0, (s, tx) => s + ((tx['amount'] as num?)?.toDouble() ?? 0.0));
              double progress = activeLoanTotal > 0
                  ? (totalPaid / activeLoanTotal).clamp(0.0, 1.0)
                  : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${totalPaid.toStringAsFixed(0)} paid',
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Colors.black87,
                        ),
                      ),
                      if (activeLoanTotal > 0)
                        Text(
                          'of ₱${activeLoanTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (activeLoanTotal > 0)
                    Text(
                      '${(progress * 100).toInt()}% of loan repaid',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Individual payment rows
            ...paymentTransactions.reversed.take(8).map((tx) {
              final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
              final date = DateTime.tryParse(tx['date']?.toString() ?? '') ?? DateTime.now();
              final dateStr = DateFormat('MMM dd, yyyy').format(date);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loan Payment',
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-₱${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    // Types that ADD to balance (inflow = green)
    const inflowTypes = {'top_up', 'loan_disbursement', 'refund'};

    // Map type → readable label
    String _typeLabel(String type) {
      switch (type) {
        case 'top_up': return 'Top Up';
        case 'withdrawal': return 'Withdrawal';
        case 'payment': return 'Loan Payment';
        case 'savings': return 'Savings Deposit';
        case 'loan_disbursement': return 'Loan Disbursed';
        case 'auto_deduction': return 'Auto Deduction';
        case 'refund': return 'Refund';
        default: return _capitalize(type.replaceAll('_', ' '));
      }
    }

    // Map type → icon
    IconData _typeIcon(String type, bool isInflow) {
      if (isInflow) return Icons.arrow_downward_rounded;
      return Icons.arrow_upward_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Empty state
        if (recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )

        // Transaction rows
        else
          ...recentTransactions.take(5).map((tx) {
            final type = tx['type']?.toString() ?? '';
            final isInflow = inflowTypes.contains(type);
            final color = isInflow ? AppColors.primaryGreen : Colors.redAccent;
            final bgColor = isInflow
                ? AppColors.primaryGreen.withOpacity(0.1)
                : Colors.redAccent.withOpacity(0.08);
            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            final sign = isInflow ? '+' : '-';
            final label = _typeLabel(type);
            final icon = _typeIcon(type, isInflow);

            final rawDate = tx['date']?.toString() ?? '';
            DateTime date = DateTime.tryParse(rawDate) ?? DateTime.now();
            final dayStr = DateFormat('MMM dd').format(date);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // Label + sub-label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.replaceAll('_', ' ').toLowerCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount + date column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign₱${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}

