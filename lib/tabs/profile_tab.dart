import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});



  final String userName = 'Juan';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryGreen,
            child: Text(
              userName[0],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile settings will appear here.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
