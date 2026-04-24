import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

enum ElectionStep {
  onboarding('Onboarding'),
  eligibility('Check Eligibility'),
  registration('Register to Vote'),
  verification('Verify Registration'),
  votingDay('Voting Day');

  const ElectionStep(this.displayName);
  final String displayName;
}

class ProgressTracker extends StatelessWidget {
  final ElectionStep currentStep;
  final List<ElectionStep> completedSteps;

  const ProgressTracker({
    super.key,
    required this.currentStep,
    this.completedSteps = const [],
  });

  @override
  Widget build(BuildContext context) {
    const allSteps = ElectionStep.values;
    final currentIndex = allSteps.indexOf(currentStep);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Election Journey',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: allSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = completedSteps.contains(step);
              final isCurrent = step == currentStep;
              final isUpcoming = index > currentIndex;

              return Expanded(
                child: _buildStep(
                  step: step,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isUpcoming: isUpcoming,
                  isLast: index == allSteps.length - 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required ElectionStep step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isUpcoming,
    required bool isLast,
  }) {
    Color getStepColor() {
      if (isCompleted) return AppColors.green;
      if (isCurrent) return AppColors.orange;
      return AppColors.ink3;
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.greenLight
                    : (isCurrent ? AppColors.orangeLight : AppColors.card),
                border: Border.all(
                  color: getStepColor(),
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.green,
                      )
                    : Text(
                        '${ElectionStep.values.indexOf(step) + 1}',
                        style: TextStyle(
                          color: getStepColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? AppColors.green : AppColors.border,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          step.displayName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isUpcoming ? AppColors.ink3 : AppColors.ink,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
