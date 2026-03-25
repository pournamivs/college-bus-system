import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key});

  Future<void> _sendSOSAlert(BuildContext context) async {
    try {
      final token = await AuthService().getToken();
      final pos = await LocationService().getCurrentPosition();
      
      final res = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/emergency/trigger'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': pos?.latitude ?? 10.0276,
          'longitude': pos?.longitude ?? 76.3084,
          'alert_type': 'safety',
        }),
      );
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS ALERT SENT WITH LIVE LOCATION', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        throw Exception('Failed to send SOS');
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
