import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TripStatusCard(),
            SizedBox(height: 16),
            StudentCountCard(),
            SizedBox(height: 16),
            RouteInformationCard(),
            SizedBox(height: 16),
            GPSLocationCard(),
            SizedBox(height: 16),
            TripControlButtons(),
          ],
        ),
      ),
    );
  }
}

class TripStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text('Trip Status'),
          subtitle: Text('Ongoing'),
        ),
      ),
    );
  }
}

class StudentCountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text('Student Count'),
          subtitle: Text('7 Students'),
        ),
      ),
    );
  }
}

class RouteInformationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text('Route Information'),
          subtitle: Text('Route: Main St. to School'),
        ),
      ),
    );
  }
}

class GPSLocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text('GPS Location'),
          subtitle: Text('Location: 35.6895° N, 139.6917° E'),
        ),
      ),
    );
  }
}

class TripControlButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: () {}, child: Text('Start Trip')), 
        ElevatedButton(onPressed: () {}, child: Text('Stop Trip')), 
      ],
    );
  }
}
