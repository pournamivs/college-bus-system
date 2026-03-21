import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  bool _isTripStarted = false;

  void _toggleTrip() {
    setState(() {
      _isTripStarted = !_isTripStarted;
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
              options: const MapOptions(
                initialCenter: LatLng(10.02, 76.32), // Ernakulam approximate
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        const Text('Route A - Ernakulam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_isTripStarted ? 'Trip in progress - Sharing Location' : 'Trip not started', 
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
