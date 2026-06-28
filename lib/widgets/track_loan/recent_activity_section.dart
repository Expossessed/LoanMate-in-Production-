import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class RecentActivitySection extends StatelessWidget {
  final List<Map<String, String>> activities;

  const RecentActivitySection({super.key, required this.activities});

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          _emptyState('No recent activity.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isPayment = activity['icon'] == 'payment';
              final iconColor = isPayment
                  ? AppColors.accentBlue
                  : AppColors.primaryGreen;
              final bgColor = isPayment
                  ? AppColors.accentBlue.withOpacity(0.10)
                  : AppColors.primaryGreen.withOpacity(0.10);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bgColor,
                    child: Icon(
                      AppColors.activityIcon(activity['icon'] ?? ''),
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    activity['text'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isPayment ? AppColors.accentBlue : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    activity['date'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
