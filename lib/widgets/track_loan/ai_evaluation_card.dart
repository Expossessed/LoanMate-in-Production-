import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AiEvaluationCard extends StatelessWidget {
  final String aiResult;
  final String aiRiskLevel;

  const AiEvaluationCard({
    super.key,
    required this.aiResult,
    required this.aiRiskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.aiResultColor(aiResult),
              AppColors.aiResultColor(aiResult).withOpacity(0.8),
            ],
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
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$aiResult — $aiRiskLevel ${AppColors.aiResultIcon(aiResult)}',
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
