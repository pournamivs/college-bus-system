import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_gradient_button.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/auth_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final WebSocketService _wsService = WebSocketService();
  final AuthService _authService = AuthService();
  
  List<dynamic> _children = [];
  bool _isLoading = true;
  LatLng _busLocation = const LatLng(10.0276, 76.3084);
  bool _isTracking = false;
  String? _trackingChildName;
  StreamSubscription? _dataSub;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    final token = await _authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/auth/children'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _children = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTracking(dynamic child) {
    _wsService.disconnect();
    _dataSub?.cancel();
    
    setState(() {
      _isTracking = true;
      _trackingChildName = child['name'];
    });
    
    _wsService.connect('102'); // Example Bus ID for Child
    _dataSub = _wsService.dataStream.listen((data) {
      if (mounted && data['lat'] != null && data['lng'] != null) {
        setState(() {
          _busLocation = LatLng(data['lat'], data['lng']);
        });
      }
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          FlutterMap(
            options: MapOptions(
              initialCenter: _busLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackmybus.app',
              ),
              if (_isTracking)
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 30),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Parent Connect',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                    child: const Icon(Icons.logout, color: AppColors.error, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildChildSelector(),
                const SizedBox(height: 16),
                if (_isTracking) _buildTrackingInfoCard(),
              ],
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT CHILD TO TRACK',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: _children.isEmpty 
              ? const Center(child: Text('No children linked', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  final isSelected = _trackingChildName == child['name'];
                  return GestureDetector(
                    onTap: () => _startTracking(child),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                            child: Icon(Icons.person, color: isSelected ? Colors.white : AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child['name'],
                                  style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  child['assigned_stop'] ?? 'No Stop',
                                  style: TextStyle(color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary, fontSize: 10),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfoCard() {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(24),
      color: AppColors.primary.withOpacity(0.08),
      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRACKING: $_trackingChildName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              const StatusBadge(status: BusStatus.moving),
            ],
          ),
          const SizedBox(height: 12),
          const CustomGradientButton(
            text: 'View Full Route Details',
            icon: Icons.alt_route_rounded,
          ),
        ],
      ),
    );
  }
}
