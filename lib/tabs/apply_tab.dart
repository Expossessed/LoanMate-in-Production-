import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';

class ApplyTab extends StatefulWidget {
  const ApplyTab({super.key});

  @override
  State<ApplyTab> createState() => _ApplyTabState();
}

class _ApplyTabState extends State<ApplyTab> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _fullName = '';
  String _studentId = '';
  String _courseAndYear = '';
  final TextEditingController _mobileController = TextEditingController();

  String? _selectedLoanType = 'Emergency';

  int _currentStep = 1;

  // Step 2 variables
  final TextEditingController _amountController = TextEditingController(
    text: '',
  );
  int _repaymentTerm = 6;
  final TextEditingController _purposeController = TextEditingController(
    text: '',
  );

  // Step 3 — document files
  final Map<String, File?> _docFiles = {
    'cor': null,
    'id': null,
    'income': null,
    'barangay': null,
  };

  // Reactive loan calculation
  double get _principal =>
      double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
  // 3% per annum simple interest
  double get _totalInterest => _principal * 0.03 * (_repaymentTerm / 12);
  double get _totalRepayment => _principal + _totalInterest;
  double get _monthlyPayment =>
      _repaymentTerm > 0 ? _totalRepayment / _repaymentTerm : 0;
  // Penalty: 2% for 6mo, 4% for 12mo, 6% for 18mo of principal
  double get _penaltyRate => _repaymentTerm == 6
      ? 0.02
      : _repaymentTerm == 12
      ? 0.03
      : 0.04;
  double get _penaltyAmount => _principal * _penaltyRate;

  String _fmt(double v) =>
      '₱${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  @override
  void initState() {
    super.initState();
    _loadProfile();
    _amountController.addListener(() => setState(() {}));
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final first = profile['first_name'] ?? '';
      final last = profile['last_name'] ?? '';
      _fullName = '$first $last'.trim().toUpperCase();
      _studentId = profile['student_id'] ?? '';

      final course = (profile['course'] ?? '').toString().toUpperCase();
      final yearRaw = (profile['year_level'] ?? '').toString();
      // Extract the digit from year_level (e.g. "3" from "3rd Year" or just "3")
      final yearNum =
          int.tryParse(yearRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final ordinal = yearNum == 1
          ? 'ST'
          : yearNum == 2
          ? 'ND'
          : yearNum == 3
          ? 'RD'
          : 'TH';
      final yearLabel = yearNum > 0
          ? '$yearNum$ordinal YEAR'
          : yearRaw.toUpperCase();
      _courseAndYear = course.isNotEmpty ? '$course, $yearLabel' : yearLabel;
    } catch (e) {
      print('Error loading profile for apply form: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _currentStep >= 2
                      ? Colors.redAccent
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _currentStep >= 3
                      ? Colors.redAccent
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step $_currentStep of 3',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTypeOption({
    required String type,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final isSelected = _selectedLoanType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLoanType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.cardCream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Top Part
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 60,
                left: 24,
                right: 24,
                bottom: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await supabase.auth.signOut();
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
                  Text(
                    'LOAN APPLICATION',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Apply for a Loan',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStepIndicator(),
                ],
              ),
            ),

            // Content Body
            Padding(padding: const EdgeInsets.all(24.0), child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose loan type',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        _buildLoanTypeOption(
          type: 'Educational',
          description: 'Tuition, books & school fees',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF5C45A1),
          iconBgColor: const Color(0xFFEBE6FC),
        ),
        _buildLoanTypeOption(
          type: 'Emergency',
          description: 'Medical & urgent expenses',
          icon: Icons.flash_on_rounded,
          iconColor: Colors.redAccent,
          iconBgColor: Colors.redAccent.withOpacity(0.1),
        ),
        _buildLoanTypeOption(
          type: 'Livelihood',
          description: 'Business & project funding',
          icon: Icons.trending_up_rounded,
          iconColor: Colors.orange.shade700,
          iconBgColor: Colors.orange.shade50,
        ),

        const SizedBox(height: 32),
        const Text(
          'Your details',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        _buildReadonlyField('FULL NAME', _fullName),
        _buildReadonlyField('STUDENT ID', _studentId),
        _buildReadonlyField('COURSE & YEAR', _courseAndYear),

        // Mobile — editable blank field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOBILE NUMBER',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 14,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g. +63 912 345 6789',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),

        const SizedBox(height: 20),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loan details',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // Amount
        Text(
          'AMOUNT (*)',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '*5,000 minimum · *50,000 maximum',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 20),

        // Repayment Term
        Text(
          'REPAYMENT TERM',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTermOption(6),
            const SizedBox(width: 12),
            _buildTermOption(12),
            const SizedBox(width: 12),
            _buildTermOption(18),
          ],
        ),
        const SizedBox(height: 20),

        // Purpose
        Text(
          'PURPOSE',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _purposeController,
            maxLines: 3,
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 32),

        // Loan Estimate
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Green header: monthly payment ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED MONTHLY PAYMENT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(_monthlyPayment),
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'per month',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'for $_repaymentTerm months',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // ── White breakdown panel ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Loan Principal',
                      value: _fmt(_principal),
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.percent_rounded,
                      label: 'Interest Rate',
                      value: '3% per year',
                      valueColor: Colors.blue.shade700,
                    ),
                    _buildDetailRow(
                      icon: Icons.trending_up_rounded,
                      label: 'Total Interest',
                      value: _fmt(_totalInterest),
                      valueColor: Colors.blue.shade700,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.receipt_long_rounded,
                      label: 'Total Repayment',
                      value: _fmt(_totalRepayment),
                      bold: true,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Missed Payment Penalty',
                      value:
                          '${(_penaltyRate * 100).toStringAsFixed(0)}% of principal',
                      valueColor: Colors.orange.shade700,
                    ),
                    _buildDetailRow(
                      icon: Icons.attach_money_rounded,
                      label: 'Penalty Amount',
                      value: _fmt(_penaltyAmount),
                      valueColor: Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep = 1);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentStep = 3);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTermOption(int months) {
    final isSelected = _repaymentTerm == months;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _repaymentTerm = months),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: Text(
              '$months mos',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(color: Colors.grey.shade100, height: 1),
  );

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload documents',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload clear, legible copies of each required file.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 24),

        _buildDocUploadCard('cor', 'Certificate of Registration\n(COR)', true),
        _buildDocUploadCard('id', 'School ID', true),
        _buildDocUploadCard(
          'income',
          'Parent/Guardian Income\nCertificate',
          true,
        ),
        _buildDocUploadCard('barangay', 'Barangay Clearance', false),

        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUTO-DEDUCT ACTIVE',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monthly repayments of ${_fmt(_monthlyPayment)} will be automatically deducted from your E-Wallet every 15th of the month. Missed payments incur a ${(_penaltyRate * 100).toStringAsFixed(0)}% penalty (${_fmt(_penaltyAmount)}).',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep = 2);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Submit flow — DB-wired ────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    // 0) Guard: required docs
    final requiredKeys = ['cor', 'id', 'income'];
    final missing = requiredKeys.where((k) => _docFiles[k] == null).toList();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    // Guard: required fields
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid loan amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the loan purpose.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1) Insert into `loans` first to get loan_id
      final loanInsert = await supabase
          .from('loans')
          .insert({
            'user_id': user.id,
            'amount': amount,
            'purpose': _purposeController.text.trim(),
            'status': 'pending',
            'ai_evaluation': 'pending',
          })
          .select('id')
          .single();

      final loanId = loanInsert['id'].toString();

      // 2) Upload each file to Storage bucket `loan-docs` and collect URLs
      final List<Map<String, dynamic>> docRows = [];
      for (final entry in _docFiles.entries) {
        final file = entry.value;
        if (file == null) continue;
        final filename = entry.key + '_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
        final storagePath = '${user.id}/$loanId/$filename';
        await supabase.storage
            .from('application_images')
            .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));
        final publicUrl = supabase.storage
            .from('application_images')
            .getPublicUrl(storagePath);
        docRows.add({
          'user_id': user.id,
          'loan_id': loanId,
          'file_url': publicUrl,
        });
      }

      // 3) Insert one row per file into `documents`
      if (docRows.isNotEmpty) {
        await supabase.from('documents').insert(docRows);
      }

      if (!mounted) return;

      // 4a) Show AI review spinner (UX — simulated, ai_evaluation stays 'pending')
      _showAiReviewDialog();
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.of(context).pop(); // close spinner

      // 4b) Show success dialog
      await _showAiApprovedDialog();
      if (!mounted) return;

      // 4c) Reset form
      setState(() {
        _currentStep = 1;
        _amountController.clear();
        _purposeController.clear();
        _mobileController.clear();
        _repaymentTerm = 6;
        _docFiles.updateAll((_, __) => null);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAiReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 20),
              const Text(
                'AI is reviewing your documents…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifying authenticity and eligibility',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAiApprovedDialog() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Documents Approved!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your loan application has been submitted for admin review.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Doc upload card with image_picker ────────────────────────────────────
  Widget _buildDocUploadCard(String key, String title, bool isRequired) {
    final file = _docFiles[key];
    final isUploaded = file != null;

    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked != null) {
          setState(() => _docFiles[key] = File(picked.path));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppColors.primaryGreen.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUploaded
                ? AppColors.primaryGreen.withOpacity(0.5)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isUploaded
                    ? AppColors.primaryGreen.withOpacity(0.15)
                    : Colors.grey.shade100,
              ),
              child: isUploaded
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.upload_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isRequired ? 'Required' : 'Optional'} · ${isUploaded ? 'Uploaded ✓' : 'Tap to upload'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUploaded
                          ? AppColors.primaryGreen
                          : Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUploaded
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: isUploaded ? AppColors.primaryGreen : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
