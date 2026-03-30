import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({
    super.key,
    required this.label,
  });

  Color get _color {
    final lower = label.toLowerCase();
    if (lower.contains('paid') && !lower.contains('unpaid')) return AppColors.success;
    if (lower.contains('present')) return AppColors.success;
    if (lower.contains('overdue') || lower.contains('absent') || lower.contains('unpaid')) return AppColors.error;
    if (lower.contains('due soon') || lower.contains('late')) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
