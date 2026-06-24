import 'package:flutter/material.dart';
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
  String _fullName = '';
  String _studentId = '';
  String _courseAndYear = '';
  String _mobileNumber =
      '+63 917 845 2310'; // Placeholder as it's not in DB yet

  String? _selectedLoanType = 'Emergency';

  int _currentStep = 1;

  // Step 2 variables
  final TextEditingController _amountController = TextEditingController(
    text: '15000',
  );
  int _repaymentTerm = 12;
  final TextEditingController _purposeController = TextEditingController(
    text: 'Tuition fee payment for 2nd Semester AY 2026-2027',
  );

  // Step 3 variables
  final Map<String, bool> _docsUploaded = {
    'cor': false,
    'id': false,
    'income': false,
    'barangay': false,
  };
  @override
  void initState() {
    super.initState();
    _loadProfile();
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
      _fullName = '$first $last'.trim();
      _studentId = profile['student_id'] ?? '';

      final course = profile['course'] ?? '';
      final year = profile['year_level'] ?? '';
      if (course.isNotEmpty && year.isNotEmpty) {
        _courseAndYear = '$course, $year Year';
      } else {
        _courseAndYear = '$course $year'.trim();
      }
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
        _buildReadonlyField('MOBILE NUMBER', _mobileNumber),

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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOAN ESTIMATE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '₱1,325',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/mo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildEstimateRow('Principal', '₱15,000'),
              const SizedBox(height: 8),
              _buildEstimateRow('Interest', '6% per annum'),
              const SizedBox(height: 8),
              _buildEstimateRow('Total Repayment', '₱15,900'),
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
                'Monthly repayments of ₱1,325 will be automatically deducted from your E-Wallet every 15th of the month.',
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
                onPressed: () {
                  // Submit
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application Submitted!')),
                  );
                  // Reset back to Step 1
                  setState(() => _currentStep = 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
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

  Widget _buildDocUploadCard(String key, String title, bool isRequired) {
    final isUploaded = _docsUploaded[key] == true;

    return Container(
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppColors.primaryGreen.withOpacity(0.15)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUploaded ? Icons.check : Icons.upload_rounded,
              color: isUploaded ? AppColors.primaryGreen : Colors.grey.shade600,
              size: 20,
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
                  '${isRequired ? 'Required' : 'Optional'} · ${isUploaded ? 'Uploaded' : 'Pending'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (isUploaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Uploaded',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _docsUploaded[key] = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
