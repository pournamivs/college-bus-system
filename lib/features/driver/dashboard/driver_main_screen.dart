import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_gradient_button.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  final WebSocketService _wsService = WebSocketService();
  final AuthService _authService = AuthService();
  
  bool _isTripStarted = false;
  StreamSubscription<Position>? _positionStream;
  LatLng _currentLocation = const LatLng(10.0276, 76.3084);
  Map<String, dynamic>? _assignedBus;
  String _statusMessage = 'Fetching assigned bus...';

  @override
  void initState() {
    super.initState();
    _fetchAssignedBus();
  }

  Future<void> _fetchAssignedBus() async {
    final token = await _authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/driver/my-bus'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _assignedBus = jsonDecode(response.body);
            _statusMessage = 'Ready on ${_assignedBus!['name']}';
          });
        }
      } else {
        if (mounted) setState(() => _statusMessage = 'No bus assigned');
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Offline - Check Backend');
    }
  }

  void _toggleTrip() async {
    if (_isTripStarted) {
      _stopTrip();
    } else {
      await _startTrip();
    }
  }

  final LocationService _locationService = LocationService();

  Future<void> _startTrip() async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) return;
    
    setState(() {
      _isTripStarted = true;
      _statusMessage = 'Broadcasting Location...';
    });

    final busId = _assignedBus?['id']?.toString() ?? '102';
    _wsService.connect(busId);

    _positionStream = _locationService.getPositionStream().listen((position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _wsService.send({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _stopTrip() {
    _positionStream?.cancel();
    _wsService.disconnect();
    setState(() {
      _isTripStarted = false;
      _statusMessage = 'Trip Ended';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
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
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map View
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackmybus.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(Icons.directions_bus, color: AppColors.primary, size: 35),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Floating Controls Area
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: GlassMorphicCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _assignedBus?['name'] ?? 'Bus Not Assigned',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusMessage, 
                            style: TextStyle(
                              color: _isTripStarted ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        status: _isTripStarted ? BusStatus.moving : BusStatus.offline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomGradientButton(
                    text: _isTripStarted ? 'STOP TRIP' : 'START TRIP',
                    onPressed: _toggleTrip,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
