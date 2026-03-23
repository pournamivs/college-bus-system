import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:track_my_bus/core/constants/api_constants.dart';
import 'package:track_my_bus/core/constants/app_colors.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  bool _isTripStarted = false;
  WebSocketChannel? _channel;
  StreamSubscription<Position>? _positionStream;
  LatLng _currentLocation = const LatLng(10.02, 76.32);
  Map<String, dynamic>? _assignedBus;
  String _statusMessage = 'Fetching assigned bus...';

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
        Uri.parse('${ApiConstants.apiBaseUrl}/api/driver/my-bus'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _assignedBus = jsonDecode(response.body);
          _statusMessage = 'Ready on ${_assignedBus!['name']}';
        });
      } else {
        setState(() => _statusMessage = 'No bus assigned');
      }
    } catch (e) {
      debugPrint("Bus fetch error: $e");
      setState(() => _statusMessage = 'Offline - Check Backend');
    }
  }

  void _toggleTrip() async {
    if (_isTripStarted) {
      _stopTrip();
    } else {
      await _startTrip();
    }
  }

  Future<void> _startTrip() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    setState(() {
      _isTripStarted = true;
      _statusMessage = 'Broadcasting...';
    });

    final busId = _assignedBus?['id'] ?? 102;
    _channel = WebSocketChannel.connect(
      Uri.parse('${ApiConstants.wsBaseUrl}/ws/bus/bus_$busId'),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _channel?.sink.add(jsonEncode({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    });
  }

  void _stopTrip() {
    _positionStream?.cancel();
    _channel?.sink.close();
    setState(() {
      _isTripStarted = false;
      _statusMessage = 'Trip Ended';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Driver Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trackmybus.app',
                ),
                if (_isTripStarted)
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(10.02, 76.32),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.directions_bus, color: AppColors.primary, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Controls
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_assignedBus?['name'] ?? 'Loading Bus...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_statusMessage, 
                            style: TextStyle(color: _isTripStarted ? AppColors.success : AppColors.textSecondary)),
                      ],
                    ),
                    Icon(_isTripStarted ? Icons.my_location : Icons.location_off, 
                         color: _isTripStarted ? AppColors.success : AppColors.textSecondary, size: 32),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripStarted ? AppColors.error : AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _toggleTrip,
                    child: Text(
                      _isTripStarted ? 'END TRIP' : 'START TRIP',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
