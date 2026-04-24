import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class ReadinessScoreCard extends StatelessWidget {
  final int score;

  const ReadinessScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Readiness Score',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$score%',
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
