import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:track_my_bus/core/constants/api_constants.dart';
import 'package:track_my_bus/core/constants/app_colors.dart';

class StudentTrackingScreen extends StatefulWidget {
  const StudentTrackingScreen({super.key});

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  final MapController _mapController = MapController();
  WebSocketChannel? _channel;
  LatLng _currentBusPosition = const LatLng(10.02, 76.32);
  final LatLng _studentStop = const LatLng(10.0070, 76.3533);
  String _busId = '102';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    _channel = WebSocketChannel.connect(
      Uri.parse('${ApiConstants.wsBaseUrl}/ws/bus/bus_$_busId'),
    );
    _channel?.stream.listen((message) {
      final data = jsonDecode(message);
      if (mounted) {
        setState(() {
          _currentBusPosition = LatLng(data['lat'], data['lng']);
          _isConnected = true;
        });
      }
    }, onError: (e) {
      debugPrint("WebSocket Error: $e");
      setState(() => _isConnected = false);
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
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
              initialCenter: _studentStop,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackmybus.app',
              ),
              // PolylineLayer removed or should be dynamic
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bus #$_busId - Live Location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(_isConnected ? 'Connected' : 'Waiting for bus...', 
                            style: TextStyle(fontSize: 16, color: _isConnected ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
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

