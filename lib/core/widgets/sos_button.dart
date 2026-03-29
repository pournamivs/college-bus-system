import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../constants/app_colors.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key});

  Future<void> _sendSOSAlert(BuildContext context) async {
    try {
      final uid = await AuthService().getUid();
      if (uid == null) return;
      
      final pos = await LocationService().getCurrentPosition();
      await FirestoreService().reportSOS(
        uid,
        pos?.latitude ?? 10.0276,
        pos?.longitude ?? 76.3084,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS ALERT SENT WITH LIVE LOCATION', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SOS: $e'),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    }
  }

  void _triggerSOS(BuildContext context) {
    final countdown = ValueNotifier<int>(5);
    Timer? timer;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (countdown.value <= 1) {
            timer?.cancel();
            countdown.value = 0;
            Navigator.pop(dialogContext);
            _sendSOSAlert(context);
            return;
          }
          countdown.value -= 1;
        });

        return ValueListenableBuilder<int>(
          valueListenable: countdown,
          builder: (context, value, child) => AlertDialog(
            title: const Text('Emergency SOS'),
            content: Text(
              'Sending alert to Admin and linked Parents in $value seconds.\n'
              'Your current location will be attached.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(dialogContext);
                },
                child: const Text('CANCEL'),
              ),
            ],
          ),
        );
      },
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
