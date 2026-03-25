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
import '../../shared/role_feature_panel.dart';
import '../../shared/role_feature_catalog.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  final WebSocketService _wsService = WebSocketService();
  final AuthService _authService = AuthService();

  bool _isTripStarted = false;
  bool _isTripPaused = false;
  StreamSubscription<Position>? _positionStream;
  LatLng _currentLocation = const LatLng(10.0276, 76.3084);
  Map<String, dynamic>? _assignedBus;
  String _statusMessage = 'Fetching assigned bus...';
  int _passengerCount = 0;

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

  void _togglePause() {
    if (!_isTripStarted) return;
    setState(() {
      _isTripPaused = !_isTripPaused;
      _statusMessage = _isTripPaused
          ? 'Trip Paused'
          : 'Broadcasting Location...';
    });
  }

  final LocationService _locationService = LocationService();

  Future<void> _startTrip() async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission/service is required. Please enable GPS.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isTripStarted = true;
      _isTripPaused = false;
      _statusMessage = 'Broadcasting Location...';
    });

    final busId = _assignedBus?['id']?.toString() ?? '102';
    _wsService.connect(busId);

    _positionStream = _locationService.getPositionStream().listen((position) {
      if (mounted) {
        if (_isTripPaused) return;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _wsService.send({
          'lat': position.latitude,
          'lng': position.longitude,
          'speed': position.speed,
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
      _isTripPaused = false;
      _statusMessage = 'Trip Ended';
    });
  }

  Future<void> _showMaintenanceReportDialog() async {
    String issueType = 'engine';
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maintenance Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: issueType,
              items: const [
                DropdownMenuItem(value: 'engine', child: Text('Engine')),
                DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                DropdownMenuItem(value: 'delay', child: Text('Delay')),
              ],
              onChanged: (value) => issueType = value ?? 'engine',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(hintText: 'Describe issue'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final token = await _authService.getToken();
              try {
                await http.post(
                  Uri.parse(
                    '${ApiConstants.apiBaseUrl}/api/driver/maintenance',
                  ),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'bus_id': _assignedBus?['id'] ?? 102,
                    'driver_id':
                        0, // Backend will use current user ideally, or we can send it here.
                    'issue_description':
                        '${issueType.toUpperCase()}: ${noteCtrl.text}',
                  }),
                );
              } catch (e) {
                debugPrint('Maintenance report submission failed: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to submit report. Please try again.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report submitted: $issueType'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) context.go('/login');
              },
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
                        const Icon(
                          Icons.directions_bus,
                          color: AppColors.primary,
                          size: 35,
                        ),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _isTripStarted
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        status: _isTripStarted
                            ? (_isTripPaused
                                  ? BusStatus.delayed
                                  : BusStatus.moving)
                            : BusStatus.offline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(
                            _isTripPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(_isTripPaused ? 'Resume' : 'Pause'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showMaintenanceReportDialog,
                          icon: const Icon(Icons.build_circle_outlined),
                          label: const Text('Report'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () => _passengerCount = (_passengerCount - 1).clamp(
                            0,
                            999,
                          ),
                        ),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        'Passenger Count: $_passengerCount',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _passengerCount += 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const RoleFeaturePanel(
                    role: AppRole.driver,
                    title: 'Driver Feature Readiness',
                  ),
                  const SizedBox(height: 16),
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
