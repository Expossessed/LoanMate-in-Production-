import 'package:flutter/material.dart';

class AiEvaluationCard extends StatelessWidget {
  final String aiResult;
  final String aiRiskLevel;

  static const Color primaryGreen = Color(0xFF2E7D32);

  const AiEvaluationCard({
    super.key,
    required this.aiResult,
    required this.aiRiskLevel,
  });

  Color _aiCardColor() {
    switch (aiResult.toLowerCase()) {
      case 'eligible':
        return primaryGreen;
      case 'not eligible':
        return Colors.red.shade700;
      case 'under review':
        return Colors.orange.shade800;
      default:
        return Colors.grey;
    }
  }

  String _aiCardIcon() {
    switch (aiResult.toLowerCase()) {
      case 'eligible':
        return '✓';
      case 'not eligible':
        return '✗';
      case 'under review':
        return '⏳';
      default:
        return '•';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_aiCardColor(), _aiCardColor().withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 24,
              child: Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Evaluation Result',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$aiResult — $aiRiskLevel ${_aiCardIcon()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
