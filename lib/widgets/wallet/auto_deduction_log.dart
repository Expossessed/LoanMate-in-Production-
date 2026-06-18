import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

// Displays a list of auto-deduction log entries
class AutoDeductionLog extends StatelessWidget {
  final List<Map<String, String>> entries;

  const AutoDeductionLog({super.key, required this.entries});

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No auto-deduction records yet.',
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
        // Section title
        const Text(
          'Auto-Deduction Log',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // List or empty state
        if (entries.isEmpty)
          _emptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  // Green circle with auto-pay icon
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    child: const Icon(
                      Icons.autorenew_rounded,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                  // Deduction description
                  title: Text(
                    entry['description'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  // Date label
                  subtitle: Text(
                    entry['date'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
