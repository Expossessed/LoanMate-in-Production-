import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../tabs/admin_loan_review_tab.dart';
import 'login_screen.dart';

/// Admin dashboard — mirrors the student DashboardScreen shell but is scoped
/// to admin-only tabs. Currently only has the Loan Review tab.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final supabase = Supabase.instance.client;

  int _currentIndex = 0;

  late final List<Widget> _tabs;

  final List<_AdminNavItem> _navItems = const [
    _AdminNavItem(
      label: 'LOANS',
      activeIcon: Icons.description,
      inactiveIcon: Icons.description_outlined,
    ),
    // Future tabs go here (e.g. Users, Reports)
  ];

  @override
  void initState() {
    super.initState();
    _tabs = const [
      AdminLoanReviewTab(),
    ];
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      // AppBar with sign-out
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: _signOut,
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _tabs),
          // Floating sign-out button overlaid on top-right
          Positioned(
            top: 62,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _signOut,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _navItems.length > 1
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.cardCream,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: AppColors.primaryGreen,
                    unselectedItemColor: Colors.grey.shade500,
                    selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5),
                    items: _navItems.asMap().entries.map((e) {
                      final selected = e.key == _currentIndex;
                      final item = e.value;
                      return BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            selected ? item.activeIcon : item.inactiveIcon,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        ),
                        label: item.label,
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          : null, // no bottom bar when only one tab
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  const _AdminNavItem(
      {required this.label,
      required this.activeIcon,
      required this.inactiveIcon});
}
