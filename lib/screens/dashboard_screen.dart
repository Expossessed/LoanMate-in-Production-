import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../tabs/home_tab.dart';
import '../tabs/apply_tab.dart';
import '../tabs/loan_tab.dart';
import '../tabs/ewallet_tab.dart';
import '../tabs/profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  int currentIndex = 0;

  // GlobalKeys let us call reload methods on child tabs
  final GlobalKey<HomeTabState> _homeKey = GlobalKey<HomeTabState>();
  final GlobalKey<LoanTabState> _loanKey = GlobalKey<LoanTabState>();
  final GlobalKey<EWalletTabState> _walletKey = GlobalKey<EWalletTabState>();

  late final List<Widget> tabPages;

  final List<String> tabTitles = const [
    'Home',
    'Apply',
    'Track',
    'E-Wallet',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    tabPages = [
      HomeTab(key: _homeKey),
      const ApplyTab(),
      LoanTab(key: _loanKey),
      EWalletTab(
        key: _walletKey,
        onDataChanged: _onWalletDataChanged,
      ),
      const ProfileTab(),
    ];
  }

  /// Called by EWalletTab whenever a transaction mutates the database.
  /// Forces Home and Loan tabs to re-fetch so balances and activity are in sync.
  void _onWalletDataChanged() {
    _homeKey.currentState?.reloadData();
    _loanKey.currentState?.reloadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,

      body: IndexedStack(
        index: currentIndex,
        children: tabPages,
      ),

      bottomNavigationBar: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
                // Refresh the tab we're switching to
                if (index == 0) {
                  _homeKey.currentState?.reloadData();
                } else if (index == 2) {
                  _loanKey.currentState?.reloadData();
                } else if (index == 3) {
                  _walletKey.currentState?.reloadData();
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: Colors.grey.shade500,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5),
              items: [
                _buildNavItem(Icons.home_filled, Icons.home_outlined, 'HOME', currentIndex == 0),
                _buildNavItem(Icons.description, Icons.description_outlined, 'APPLY', currentIndex == 1),
                _buildNavItem(Icons.trending_up, Icons.trending_up, 'TRACK', currentIndex == 2),
                _buildNavItem(Icons.account_balance_wallet, Icons.account_balance_wallet_outlined, 'WALLET', currentIndex == 3),
                _buildNavItem(Icons.person, Icons.person_outline, 'PROFILE', currentIndex == 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, bool isSelected) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? Colors.white : Colors.grey.shade500,
        ),
      ),
      label: label,
    );
  }
}
