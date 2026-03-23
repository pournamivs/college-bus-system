import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_gradient_button.dart';
import '../../../core/services/websocket_service.dart';

class StudentTrackingScreen extends StatefulWidget {
  const StudentTrackingScreen({super.key});

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  final WebSocketService _wsService = WebSocketService();
  final MapController _mapController = MapController();
  
  LatLng _currentBusPosition = const LatLng(10.0276, 76.3084);
  final LatLng _studentStop = const LatLng(10.0070, 76.3533);
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  StreamSubscription? _dataSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _initWS();
  }

  void _initWS() {
    _wsService.connect('102');
    _statusSub = _wsService.statusStream.listen((status) {
      if (mounted) setState(() => _connectionStatus = status);
    });
    _dataSub = _wsService.dataStream.listen((data) {
      if (mounted && data['lat'] != null && data['lng'] != null) {
        setState(() {
          _currentBusPosition = LatLng(data['lat'], data['lng']);
        });
      }
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void _centerOnBus() {
    _mapController.move(_currentBusPosition, 15.0);
  }

  void _centerOnStop() {
    _mapController.move(_studentStop, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primary),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentBusPosition,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackmybus.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _studentStop,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                  ),
                  Marker(
                    point: _currentBusPosition,
                    width: 70,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))],
                        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 35),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Floating Info Card
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: GlassMorphicCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bus KL-07-CB-4567', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _connectionStatus == ConnectionStatus.connected ? 'Tracking Active' : 'Connecting...',
                            style: TextStyle(color: _connectionStatus == ConnectionStatus.connected ? AppColors.success : AppColors.warning),
                          ),
                        ],
                      ),
                      StatusBadge(status: _connectionStatus == ConnectionStatus.connected ? BusStatus.moving : BusStatus.offline),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildMapAction('Center Bus', Icons.my_location, _centerOnBus),
                      const SizedBox(width: 12),
                      _buildMapAction('Your Stop', Icons.tour, _centerOnStop),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CustomGradientButton(
                    text: 'CONTACT DRIVER',
                    icon: Icons.phone_in_talk,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapAction(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

