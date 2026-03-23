import 'package:flutter/material.dart';
import 'package:location/location.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Location _location = Location();
  String _currentLocation = 'Unknown';
  String _eta = 'loading...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getETA();
  }

  Future<void> _getCurrentLocation() async {
    final LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation = '\${locationData.latitude}, \${locationData.longitude}';
    });
  }

  Future<void> _getETA() async {
    // Dummy ETA for demonstration purposes
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _eta = '15 minutes';
    });
  }

  void _sos() {
    // Logic for SOS button (e.g., send an alert)
    print('SOS Alert Sent!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Dashboard'),),
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
                    Text('Current Location: $_currentLocation', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('ETA: $_eta', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _sos,
                      child: Text('SOS'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red,
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