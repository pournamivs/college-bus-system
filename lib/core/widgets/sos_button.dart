import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key});

  void _triggerSOS(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text('Are you sure you want to trigger an emergency alert? This will notify the admin and emergency services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              // In production, call API: POST /api/emergency/sos
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS ALERT SENT!', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('TRIGGER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _triggerSOS(context),
      backgroundColor: AppColors.error,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
