import 'package:flutter/material.dart';

class RecentActivitySection extends StatelessWidget {
  final List<Map<String, String>> activities;

  static const Color primaryGreen = Color(0xFF2E7D32);

  const RecentActivitySection({super.key, required this.activities});

  IconData _activityIcon(String key) {
    switch (key) {
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'send':
        return Icons.send_rounded;
      case 'cancel':
        return Icons.cancel_rounded;
      case 'warning':
        return Icons.warning_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

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
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    child: Icon(
                      _activityIcon(activity['icon'] ?? ''),
                      color: primaryGreen,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    activity['text'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
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
