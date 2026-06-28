import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../screens/login_screen.dart';
import '../widgets/home/home_greeting.dart';
import '../widgets/home/home_wallet_card.dart';
import '../widgets/home/home_active_loan_card.dart';
import '../widgets/home/home_savings_score_cards.dart';
import '../widgets/home/home_repayment_progress.dart';
import '../widgets/home/home_recent_activity.dart';

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
  // Active loan data (aggregated across ALL active_loans rows)
  Map<String, dynamic>? activeLoan; // representative loan row (most recent)
  double activeLoanTotal = 0.0; // TOTAL original amount (all loans)
  double activeLoanRemaining = 0.0; // TOTAL remaining balance (all loans)
  double activeLoanPaid = 0.0; // amount already paid
  double totalMonthlyPayment =
      0.0; // sum of monthly_payment across all active loans
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
          final monthEnd = DateTime(
            now.year,
            now.month + 1,
            1,
          ).toIso8601String();
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
    totalMonthlyPayment = 0;
    activeLoanPurpose = '';
    activeLoanApprovedDate = null;
    nextPaymentDate = null;

    // Hoisted so repayment_schedule query can filter by user's own loan_ids
    List<String> loanIds = [];

    try {
      final loans = await supabase
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('applied_at', ascending: false);

      loanIds = loans.map((l) => l['id'].toString()).toList();

      if (loans.isNotEmpty) {
        loanStatus = _capitalize(loans[0]['status'] ?? 'No Loans');

        // Find the most recent active/approved loan for display reference
        for (final loan in loans) {
          final status = loan['status']?.toString().toLowerCase() ?? '';
          if (status == 'approved' ||
              status == 'active' ||
              status == 'partial') {
            activeLoan = loan;
            activeLoanPurpose = _capitalize(
              loan['purpose']?.toString() ?? 'Loan',
            );
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

    // Aggregate ALL active_loans rows to get true total balance & monthly payment
    // Skip placeholder rows inserted at registration (original_amount == 0)
    try {
      final activeRows = await supabase
          .from('active_loans')
          .select('original_amount, remaining_balance, monthly_payment')
          .eq('user_id', userId);

      double totalOriginal = 0;
      double totalRemaining = 0;
      double totalMonthly = 0;
      for (final row in activeRows) {
        final orig = (row['original_amount'] as num?)?.toDouble() ?? 0.0;
        if (orig == 0.0) continue; // skip registration placeholders
        totalOriginal += orig;
        totalRemaining += (row['remaining_balance'] as num?)?.toDouble() ?? 0.0;
        totalMonthly += (row['monthly_payment'] as num?)?.toDouble() ?? 0.0;
      }
      activeLoanTotal = totalOriginal;
      activeLoanRemaining = totalRemaining;
      totalMonthlyPayment = totalMonthly;

      // If active_loans has real rows, ensure activeLoan sentinel is set
      if (totalOriginal > 0 && activeLoan == null) {
        activeLoan = {}; // placeholder so the card renders
      }
    } catch (e) {
      print('Home: Error loading active_loans: $e');
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
      } catch (_) {}
    }

    // Next pending repayment — scoped to this user's own loan_ids
    if (loanIds.isNotEmpty) {
      try {
        final schedules = await supabase
            .from('repayment_schedule')
            .select('due_date, amount')
            .inFilter('loan_id', loanIds)
            .eq('status', 'pending')
            .order('due_date', ascending: true)
            .limit(1);
        if (schedules.isNotEmpty) {
          nextPaymentDate = DateTime.tryParse(
            schedules[0]['due_date']?.toString() ?? '',
          );
        }
      } catch (_) {}
    }
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
                // Logout Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.white.withOpacity(0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sign out',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Welcome Row
                HomeGreeting(name: name),
                const SizedBox(height: 36),

                // E-Wallet Card
                HomeWalletCard(walletBalance: walletBalance),
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
                HomeActiveLoanCard(
                  activeLoan: activeLoan,
                  activeLoanTotal: activeLoanTotal,
                  activeLoanPaid: activeLoanPaid,
                  activeLoanRemaining: activeLoanRemaining,
                  totalMonthlyPayment: totalMonthlyPayment,
                  activeLoanApprovedDate: activeLoanApprovedDate,
                  nextPaymentDate: nextPaymentDate,
                  activeLoanPurpose: activeLoanPurpose,
                ),
                const SizedBox(height: 16),

                // Row of small cards (Savings & Score)
                HomeSavingsScoreCards(
                  savingsBalance: savingsBalance,
                  monthlySavingsAdded: monthlySavingsAdded,
                ),

                const SizedBox(height: 30),

                // ── Repayment Progress ──
                HomeRepaymentProgress(
                  paymentTransactions: paymentTransactions,
                  activeLoanTotal: activeLoanTotal,
                ),

                const SizedBox(height: 30),

                // ── Recent Activity ──
                HomeRecentActivity(
                  recentTransactions: recentTransactions,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

