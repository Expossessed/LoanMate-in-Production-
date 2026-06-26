import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PendingLoansSection extends StatelessWidget {
  final List<Map<String, String>> loans;

  const PendingLoansSection({super.key, required this.loans});

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No pending loan requests.',
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
          'Pending Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 12),

        if (loans.isEmpty)
          _emptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              final Color chipColor = AppColors.pendingLoanColor(loan['status'] ?? '');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: chipColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),

                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  leading: CircleAvatar(
                    backgroundColor: chipColor.withOpacity(0.1),
                    child: Icon(
                      AppColors.pendingLoanIcon(loan['status'] ?? ''),
                      color: chipColor,
                    ),
                  ),

                  title: Text(
                    loan['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${loan['amount']} • ${loan['date']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  trailing: Chip(
                    label: Text(
                      loan['status'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: chipColor,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
