import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_gradient_button.dart';
import '../../../core/widgets/sos_button.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:http/http.dart' as http;

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final WebSocketService _wsService = WebSocketService();
  final AuthService _authService = AuthService();
  final MapController _mapController = MapController();
  
  LatLng _busLocation = const LatLng(10.0276, 76.3084);
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Map<String, dynamic>? _etaData;
  String? _busIdString;
  StreamSubscription? _dataSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _fetchAndConnectBus();
  }

  Future<void> _fetchAndConnectBus() async {
    final token = await _authService.getToken();
    try {
      // In a real app, staff might manage multiple buses. For demo, we fetch one.
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/driver/my-bus'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _busIdString = data['id'].toString();
        _initWS();
      }
    } catch (e) {
      _busIdString = '102';
      _initWS();
    }
  }

  void _initWS() {
    if (_busIdString == null) return;
    _wsService.connect(_busIdString!);
 // Example Fleet Bus
    _statusSub = _wsService.statusStream.listen((status) {
      if (mounted) setState(() => _connectionStatus = status);
    });
    _dataSub = _wsService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          if (data['lat'] != null && data['lng'] != null) {
            _busLocation = LatLng(data['lat'], data['lng']);
            _mapController.move(_busLocation, 14.0);
          }
          if (data['eta'] != null) {
            _etaData = data['eta'];
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fleet Manager'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error),
              onPressed: () async {
                await _authService.logout();
                if (mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _busLocation,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(flags: 0),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackmybus.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _busLocation,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 30),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: GlassMorphicCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fleet Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      StatusBadge(status: _connectionStatus == ConnectionStatus.connected ? BusStatus.moving : BusStatus.offline),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoTile('ACTIVE BUSES', '1/1', Icons.directions_bus),
                      const SizedBox(width: 12),
                      _buildInfoTile('ALERTS', '0', Icons.warning_amber_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: GlassMorphicCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _etaData?['next_stop'] ?? 'Scanning...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              'Current Bus Location',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomGradientButton(
                    text: 'ATTENDANCE OVERRIDE',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manual Attendance Override Triggered')),
                      );
                    },
                    icon: Icons.edit_calendar_rounded,
                  ),
                  const SizedBox(height: 12),
                  CustomGradientButton(
                    text: 'Send Route Alert',
                    onPressed: () {},
                    icon: Icons.send_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const SOSButton(),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
