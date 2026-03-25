import 'package:flutter/material.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _currentLocation = 'Unknown';
  String _eta = 'loading...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getETA();
  }

  Future<void> _getCurrentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    setState(() {
      _currentLocation = '10.0276, 76.3084';
    });
  }

  Future<void> _getETA() async {
    // Dummy ETA for demonstration purposes
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _eta = '15 minutes';
    });
  }

  void _sos() {
    // Logic for SOS button (e.g., send an alert)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS Alert Sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    Text('Current Location: $_currentLocation', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('ETA: $_eta', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _sos,
                      child: const Text('SOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}