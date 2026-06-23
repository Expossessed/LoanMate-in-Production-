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
  int paymentDueDays = 0;
  double approvedLoanAmount = 0.0;
  double nextPaymentAmount = 0.0;
  String aiEvaluation = 'N/A';

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

                // E-Wallet Balance
                const Row(
                  children: [
                    Text(
                      'E-WALLET BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                        fontSize: 48,
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
                const SizedBox(height: 32),

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

                // Active Loan Card
                Container(
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'EDUCATIONAL',
                                    style: TextStyle(
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
                                  '₱${approvedLoanAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: Colors.black87,
                                    fontSize: 32,
                                  ),
                                ),
                                Text(
                                  '₱${approvedLoanAmount.toStringAsFixed(0)}', // Assuming remaining = approved for visual purposes since we dont have active loan balance here
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
                            const Text(
                              'Approved Jan 10, 2026',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value:
                                    0.26, // Hardcoded visual to match screenshot
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
                                const Text(
                                  '26% repaid · ₱6,500 paid',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  'Next: $nextPaymentDate',
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
                ),
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
                            const Text(
                              '+₱500 this month',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
