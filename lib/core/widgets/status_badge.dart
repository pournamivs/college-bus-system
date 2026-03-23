import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum BusStatus { moving, delayed, sos, offline }

class StatusBadge extends StatelessWidget {
  final BusStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BusStatus.moving:
        color = AppColors.success;
        text = 'Moving';
        icon = Icons.directions_bus;
        break;
      case BusStatus.delayed:
        color = AppColors.warning;
        text = 'Delayed';
        icon = Icons.access_time_filled;
        break;
      case BusStatus.sos:
        color = AppColors.error;
        text = 'SOS Active';
        icon = Icons.warning;
        break;
      case BusStatus.offline:
        color = AppColors.textSecondary;
        text = 'Offline';
        icon = Icons.cloud_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
