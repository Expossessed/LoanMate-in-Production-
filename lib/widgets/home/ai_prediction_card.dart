import 'package:flutter/material.dart';

class AiPredictionCard extends StatelessWidget {
  final String aiEvaluation;

  static const Color accentBlue = Color(0xFF1565C0);

  const AiPredictionCard({super.key, required this.aiEvaluation});

  Color aiColor(String e) {
    switch (e.toLowerCase()) {
      case 'good standing':
        return accentBlue;
      case 'at risk':
        return Colors.orange.shade800;
      case 'poor standing':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = aiColor(aiEvaluation);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.9), cardColor],
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
                    'AI Evaluation',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$aiEvaluation',
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
