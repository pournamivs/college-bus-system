import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/sos_button.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DriverDashboard extends StatefulWidget {
  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isTripActive = false;
  WebSocketChannel? _channel;
  StreamSubscription<Position>? _positionStream;
  String _statusMessage = 'Fetching assigned bus...';
  Map<String, dynamic>? _assignedBus;
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(10.0238, 76.3129);

  @override
  void initState() {
    super.initState();
    _fetchAssignedBus();
  }

  Future<void> _fetchAssignedBus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/driver/my-bus'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _assignedBus = jsonDecode(response.body);
          _statusMessage = 'Ready to start trip on ${_assignedBus!['name']}';
        });
      } else {
        setState(() => _statusMessage = 'Error fetching bus: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Connection Error. Using Demo Bus.');
      _assignedBus = {'id': 102, 'name': 'Demo Bus 102', 'number_plate': 'DEMO-123'};
    }
  }

  @override
  void dispose() {
    _stopTrip();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _startTrip() async {
    if (_assignedBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No bus assigned yet.')));
      return;
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = 'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    setState(() {
      _isTripActive = true;
      _statusMessage = 'Connecting to Tracking Server...';
    });

    try {
      final busIdStr = 'bus_${_assignedBus!['id']}';
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConstants.wsBaseUrl}/ws/bus/$busIdStr'), 
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (_channel != null) {
          _channel!.sink.add(jsonEncode({
            'lat': position.latitude,
            'lng': position.longitude,
            'speed': position.speed,
            'timestamp': DateTime.now().toIso8601String()
          }));
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _statusMessage = 'Broadcasting ${_assignedBus!['number_plate']}\n(${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          });
          _mapController.move(_currentLocation, 15.0);
        }
      });
    } catch (e) {
      setState(() {
        _isTripActive = false;
        _statusMessage = 'Error connecting to websocket: $e';
      });
    }
  }

  void _stopTrip() {
    _positionStream?.cancel();
    _channel?.sink.close();
    setState(() {
      _isTripActive = false;
      _statusMessage = 'Trip stopped. Offline.';
      _channel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Console', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.logout, color: Colors.indigo.shade900), onPressed: _logout),
        ],
      ),
      body: Container(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_assignedBus != null) ...[
                Text(_assignedBus!['name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                Text(_assignedBus!['number_plate'], style: TextStyle(fontSize: 14, color: Colors.indigo.shade300, letterSpacing: 2)),
                SizedBox(height: 20),
              ],
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.trackmybus.app',
                        ),
                        if (_isTripActive) ...[
                          _PulseAnimation(location: _currentLocation),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLocation,
                                width: 60,
                                height: 60,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.directions_bus, color: Colors.indigo, size: 36),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (!_isTripActive)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, color: Colors.white70, size: 64),
                              SizedBox(height: 16),
                              Text('READY TO TRACK', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isTripActive ? _stopTrip : _startTrip,
                    child: Text(_isTripActive ? 'END TRIP' : 'START TRIP SESSION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive ? Colors.red.shade400 : Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SOSButton(),
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final LatLng location;
  _PulseAnimation({required this.location});
  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.location,
          width: 200 + (_controller.value * 100),
          height: 200 + (_controller.value * 100),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.3 * (1 - _controller.value)),
            ),
          ),
        ),
      ],
    );
  }
}
