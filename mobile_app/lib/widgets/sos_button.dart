import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'dart:async';
import 'dart:convert';
import '../utils/theme.dart';

class SOSButton extends StatefulWidget {
  @override
  _SOSButtonState createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isOnCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _checkCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSOS = prefs.getString('last_sos_time');
    if (lastSOS != null) {
      final lastTime = DateTime.parse(lastSOS);
      final diff = DateTime.now().difference(lastTime).inSeconds;
      if (diff < 60) {
        _startUI_Cooldown(60 - diff);
      }
    }
  }

  void _startUI_Cooldown(int secondsLeft) {
    setState(() {
      _isOnCooldown = true;
      _cooldownSeconds = secondsLeft;
    });
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 1) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
        setState(() => _isOnCooldown = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isOnCooldown ? null : () => _showSOSDialog(context),
      backgroundColor: _isOnCooldown ? Colors.grey : Colors.red,
      icon: Icon(_isOnCooldown ? Icons.timer : Icons.warning_amber_rounded, size: 32, color: Colors.white),
      label: Text(
        _isOnCooldown ? 'WAIT ${_cooldownSeconds}s' : 'SOS', 
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('EMERGENCY SOS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to trigger an emergency alert? This will immediately notify administrators.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startCountdown(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('TRIGGER SOS'),
          ),
        ],
      ),
    );
  }

  void _startCountdown(BuildContext context) {
    HapticFeedback.heavyImpact();
    int timeLeft = 5;
    Timer? timer;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(Duration(seconds: 1), (t) {
              if (timeLeft > 1) {
                HapticFeedback.selectionClick();
                setState(() => timeLeft--);
              } else {
                t.cancel();
                Navigator.pop(ctx);
                _sendEmergencyAlert(context);
              }
            });

            return AlertDialog(
              title: Text('Sending SOS in $timeLeft...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: LinearProgressIndicator(
                value: timeLeft / 5.0,
                color: Colors.red,
                backgroundColor: Colors.red.shade100,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SOS Cancelled.')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                  child: Text('CANCEL'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => timer?.cancel());
  }

  Future<void> _sendEmergencyAlert(BuildContext context) async {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acquiring location...')));
    
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/emergency/trigger'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'alert_type': 'safety'
        }),
      );
      
      if (response.statusCode == 200) {
        // Start cooldown
        await prefs.setString('last_sos_time', DateTime.now().toIso8601String());
        _startUI_Cooldown(60);

        final data = jsonDecode(response.body);
        final alertId = data['id'];

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(' SOS Sent Successfully'),
              ],
            ),
            content: Text('Administrators have been notified of your location. Please stay calm.\n\nTicket ID: #$alertId'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OKAY'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling Admin... (Feature Mockup)')));
                },
                icon: Icon(Icons.phone),
                label: Text('CALL ADMIN'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              )
            ],
          )
        );
      } else {
        throw Exception('Failed to send SOS: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Network Error: Could not send SOS. (Offline retry not implemented)'),
        backgroundColor: Colors.orange.shade800,
        duration: Duration(seconds: 5),
      ));
    }
  }
}
