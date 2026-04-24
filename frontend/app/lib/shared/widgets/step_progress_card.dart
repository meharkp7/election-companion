import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/enums.dart';

class StepProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final StepStatus status;
  final VoidCallback? onTap;

  const StepProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case StepStatus.locked:
        color = AppColors.border;
        icon = Icons.lock;
        break;
      case StepStatus.active:
        color = AppColors.orange;
        icon = Icons.radio_button_unchecked;
        break;
      case StepStatus.done:
        color = AppColors.green;
        icon = Icons.check_circle;
        break;
    }

    return Card(
      color: AppColors.card,
      child: InkWell(
        onTap: status != StepStatus.locked ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.ink3,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
