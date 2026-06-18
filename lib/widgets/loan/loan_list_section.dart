import 'package:flutter/material.dart';

class LoanListSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> loans;
  final String emptyMessage;
  final bool showBorder;

  static const Color primaryGreen = Color(0xFF2E7D32);

  const LoanListSection({
    super.key,
    required this.title,
    required this.loans,
    required this.emptyMessage,
    this.showBorder = false,
  });

  Color _statusChipColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return primaryGreen;
      case 'overdue':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  IconData _statusLeadingIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'overdue':
        return Icons.error_outline_rounded;
      case 'active':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (loans.isEmpty)
          _emptyState(emptyMessage)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              final Color chipColor = _statusChipColor(
                loan['status'] ?? '',
              );
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: showBorder
                      ? BorderSide(
                          color: chipColor.withOpacity(0.5),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: chipColor.withOpacity(0.1),
                    child: Icon(
                      _statusLeadingIcon(loan['status'] ?? ''),
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
