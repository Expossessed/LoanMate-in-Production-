import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';

class AdminLoanReviewTab extends StatefulWidget {
  const AdminLoanReviewTab({super.key});

  @override
  State<AdminLoanReviewTab> createState() => _AdminLoanReviewTabState();
}

class _AdminLoanReviewTabState extends State<AdminLoanReviewTab> {
  final supabase = Supabase.instance.client;
  final _currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  List<Map<String, dynamic>> _pendingLoans = [];
  bool _isLoading = true;
  // Track which loan IDs are currently being processed
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadPendingLoans();
  }

  Future<void> _loadPendingLoans() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all pending loans joined with the applicant's user profile
      final rows = await supabase
          .from('loans')
          .select(
              'id, amount, purpose, status, ai_evaluation, applied_at, user_id, users(first_name, last_name, student_id, course, year_level)')
          .eq('status', 'pending')
          .order('applied_at', ascending: true);

      if (mounted) setState(() => _pendingLoans = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      print('Admin load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load requests: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── APPROVE ────────────────────────────────────────────────────────────────
  Future<void> _approveLoan(Map<String, dynamic> loan) async {
    final loanId = loan['id'].toString();
    final userId = loan['user_id'].toString();
    final amount = (loan['amount'] as num).toDouble();

    setState(() => _processing.add(loanId));
    try {
      // ── Compute repayment values ──────────────────────────────────────────
      const double interestRate = 0.03; // 3% p.a.
      const int termMonths = 6;
      final double totalInterest = amount * interestRate * (termMonths / 12);
      final double totalRepayment = amount + totalInterest;
      final double monthlyPayment = totalRepayment / termMonths;

      // ── Guard: total active loan balance cap of ₱10,000 ──────────────────
      final activeRows = await supabase
          .from('active_loans')
          .select('remaining_balance')
          .eq('user_id', userId);

      double currentTotal = 0;
      for (final row in activeRows) {
        currentTotal += (row['remaining_balance'] as num?)?.toDouble() ?? 0;
      }

      if (currentTotal + totalRepayment > 10000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot approve: student\'s total active loan balance would exceed ₱10,000 '
                '(current ₱${currentTotal.toStringAsFixed(2)} + '
                'new ₱${totalRepayment.toStringAsFixed(2)}).',
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final now = DateTime.now().toIso8601String();

      // 1) Update loans.status → approved
      await supabase.from('loans').update({
        'status': 'approved',
        'approved_at': now,
      }).eq('id', loanId);

      // 2) Always insert a new active_loans row for this loan
      await supabase.from('active_loans').insert({
        'loan_id': loanId,
        'user_id': userId,
        'original_amount': amount,
        'remaining_balance': totalRepayment,
        'monthly_payment': monthlyPayment,
        'start_date': DateTime.now().toIso8601String().substring(0, 10),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan approved and added to active loans.'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _pendingLoans.removeWhere((l) => l['id'] == loanId));
      }
    } catch (e) {
      print('Approve error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approve failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(loanId));
    }
  }

  // ── DENY ───────────────────────────────────────────────────────────────────
  Future<void> _denyLoan(Map<String, dynamic> loan) async {
    final loanId = loan['id'].toString();

    // Confirm before denying
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deny this loan request?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This action will mark the loan as denied. The student will see the updated status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.primaryGreen)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Deny', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing.add(loanId));
    try {
      await supabase
          .from('loans')
          .update({'status': 'denied'}).eq('id', loanId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loan request denied.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _pendingLoans.removeWhere((l) => l['id'] == loanId));
      }
    } catch (e) {
      print('Deny error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deny failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(loanId));
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 60, left: 24, right: 24, bottom: 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius:
                  BorderRadius.only(bottomRight: Radius.circular(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              )),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      onPressed: _loadPendingLoans,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'LOAN REQUESTS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Pending Review',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_pendingLoans.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingLoans.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPendingLoans,
                        color: AppColors.primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _pendingLoans.length,
                          itemBuilder: (context, index) =>
                              _buildLoanCard(_pendingLoans[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 56, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontFamily: 'Arial',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending loan requests at this time.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final loanId = loan['id'].toString();
    final isProcessing = _processing.contains(loanId);
    final user = loan['users'] as Map<String, dynamic>? ?? {};
    final firstName = user['first_name']?.toString() ?? '';
    final lastName = user['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim().toUpperCase();
    final studentId = user['student_id']?.toString() ?? '—';
    final course = user['course']?.toString() ?? '';
    final yearLevel = user['year_level']?.toString() ?? '';
    final courseYear = [course, yearLevel]
        .where((s) => s.isNotEmpty)
        .join(' · ')
        .toUpperCase();

    final amount = (loan['amount'] as num?)?.toDouble() ?? 0.0;
    final purpose = loan['purpose']?.toString() ?? '—';
    final aiEval = loan['ai_evaluation']?.toString() ?? 'pending';
    final appliedAt = loan['applied_at']?.toString() ?? '';
    String dateLabel = appliedAt;
    try {
      dateLabel =
          DateFormat('MMM dd, yyyy').format(DateTime.parse(appliedAt));
    } catch (_) {}

    // AI badge color
    Color aiBadgeColor;
    switch (aiEval.toLowerCase()) {
      case 'eligible':
        aiBadgeColor = AppColors.primaryGreen;
        break;
      case 'ineligible':
        aiBadgeColor = Colors.red.shade600;
        break;
      default:
        aiBadgeColor = Colors.orange.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              children: [
                // ── Avatar (centred) ──────────────────────────────────
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ── Full Name ─────────────────────────────────────────
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // ── Student ID ────────────────────────────────────────
                Text(
                  studentId,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
                if (courseYear.isNotEmpty) ...[const SizedBox(height: 2),
                  Text(
                    courseYear,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // ── Applied date chip ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 5),
                      Text(
                        'Applied $dateLabel',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Loan Details ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOAN AMOUNT',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currency.format(amount),
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // AI badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: aiBadgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: aiBadgeColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology_rounded,
                              size: 14, color: aiBadgeColor),
                          const SizedBox(width: 5),
                          Text(
                            'AI: ${aiEval[0].toUpperCase()}${aiEval.substring(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: aiBadgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Purpose
                Text(
                  'PURPOSE',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    purpose,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          // DENY
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _denyLoan(loan),
                              icon: const Icon(Icons.close_rounded,
                                  size: 18),
                              label: const Text('Deny'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(
                                    color: Colors.red.shade300, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // APPROVE
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _approveLoan(loan),
                              icon: const Icon(Icons.check_rounded,
                                  size: 18, color: Colors.white),
                              label: const Text('Approve',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
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
  }
}
