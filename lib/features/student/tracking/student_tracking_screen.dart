import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';

class StudentTrackingScreen extends StatefulWidget {
  const StudentTrackingScreen({super.key});

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _timer;
  
  // Dummy route points in Kerala
  final List<LatLng> _routePoints = [
    const LatLng(9.9816, 76.2999), // Kakkanad
    const LatLng(9.9926, 76.3262), // InfoPark
    const LatLng(10.0070, 76.3533), // Kizhakkambalam
    const LatLng(10.0150, 76.3887), // Pattimattom
    const LatLng(10.0211, 76.4338), // Kadayiruppu (College)
  ];
  
  int _currentRouteIndex = 0;
  late LatLng _currentBusPosition;
  final LatLng _studentStop = const LatLng(10.0070, 76.3533); // Example: Kizhakkambalam

  @override
  void initState() {
    super.initState();
    _currentBusPosition = _routePoints[_currentRouteIndex];
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentRouteIndex < _routePoints.length - 1) {
          _currentRouteIndex++;
          _currentBusPosition = _routePoints[_currentRouteIndex];
        } else {
          _currentRouteIndex = 0; // Loop back for demo
          _currentBusPosition = _routePoints[_currentRouteIndex];
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnBus() {
    _mapController.move(_currentBusPosition, 14.0);
  }

  void _centerOnStop() {
    _mapController.move(_studentStop, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _routePoints[0],
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackmybus',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Student Stop
                  Marker(
                    point: _studentStop,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                  ),
                  // Bus Position
                  Marker(
                    point: _currentBusPosition,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                      ),
                      child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 30),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Info Bottom Sheet via DraggableScrollableSheet
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.4,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Route A - KL-07-AB-1234', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('10 mins ETA', style: TextStyle(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.person, color: AppColors.primary)),
                      title: Text('Driver: Rajesh M'),
                      subtitle: Text('+91 9876543210'),
                      trailing: Icon(Icons.call, color: AppColors.success),
                    ),
                    const Divider(),
                    const Text('Last updated: Just now', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          // Map Controls
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'btn1',
                  backgroundColor: Colors.white,
                  onPressed: _centerOnBus,
                  child: const Icon(Icons.my_location, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btn2',
                  backgroundColor: Colors.white,
                  onPressed: _centerOnStop,
                  child: const Icon(Icons.tour, color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 240.0), // Above bottom sheet
        child: FloatingActionButton(
          heroTag: 'refresh',
          backgroundColor: AppColors.primary,
          onPressed: () {
            setState(() {
              // Force refresh
            });
          },
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }
}

