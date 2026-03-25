import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  // For demo, we just show a static centered map with refresh pulling buses
  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/buses'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        // Success
      }
    } catch (e) {
      debugPrint('Error fetching buses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Map')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(10.0276, 76.3084),
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.trackmybus.app',
          ),
          // We can overlay a static marker for demo
          const MarkerLayer(
            markers: [
              Marker(
                point: LatLng(10.0276, 76.3084),
                width: 40, height: 40,
                child: Icon(Icons.directions_bus, color: Colors.purple, size: 30),
              )
            ],
          ),
        ],
      ),
    );
  }
}
