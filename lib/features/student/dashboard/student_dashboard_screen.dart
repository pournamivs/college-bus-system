import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_gradient_button.dart';
import '../../../core/widgets/sos_button.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/auth_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final WebSocketService _wsService = WebSocketService();
  final AuthService _authService = AuthService();
  final MapController _mapController = MapController();
  
  LatLng _busLocation = const LatLng(10.0276, 76.3084);
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Map<String, dynamic>? _etaData;
  String _userName = 'Student';
  bool _attendanceMarked = false;
  StreamSubscription? _dataSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initWS();
  }

  Future<void> _loadUser() async {
    final name = await _authService.getName();
    if (mounted) setState(() => _userName = name ?? 'Student');
  }

  void _initWS() {
    _wsService.connect('102'); // Example Bus ID
    _statusSub = _wsService.statusStream.listen((status) {
      if (mounted) setState(() => _connectionStatus = status);
    });
    _dataSub = _wsService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          if (data['lat'] != null && data['lng'] != null) {
            _busLocation = LatLng(data['lat'], data['lng']);
            _mapController.move(_busLocation, 15.0);
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
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  _buildLiveStatusCard(),
                  const SizedBox(height: 24),
                  _buildBusInfoCard(),
                  const SizedBox(height: 24),
                  _buildAttendanceSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const SOSButton(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _userName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ],
        ),
        _buildConnectionDot(),
      ],
    );
  }

  Widget _buildConnectionDot() {
    Color dotColor = Colors.grey;
    if (_connectionStatus == ConnectionStatus.connected) dotColor = AppColors.success;
    if (_connectionStatus == ConnectionStatus.connecting) dotColor = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dotColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _connectionStatus.name.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dotColor),
          ),
        ],
      ),
    );
  }

  // ... (QuickStats, ActionBtn, StatItem remain mostly UI-only placeholders for now)
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Attendance', '92%', Icons.calendar_today)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Fine', '₹0', Icons.account_balance_wallet_outlined)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLiveStatusCard() {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(24),
      color: AppColors.primary.withOpacity(0.08),
      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: _connectionStatus == ConnectionStatus.connected ? BusStatus.moving : BusStatus.offline),
              Text(
                _etaData != null ? 'ETA: ${_etaData!['eta_minutes']} mins' : 'Scanning...',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
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
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Next: ${_etaData?['next_stop'] ?? 'Fetching route...'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bus_alert_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bus KL-07-CB-4567', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Driver: Suresh Kumar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.phone_in_talk, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Daily Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        CustomGradientButton(
          text: _attendanceMarked ? 'ATTENDANCE MARKED' : 'MARK ATTENDANCE',
          icon: _attendanceMarked ? Icons.check_circle : Icons.fingerprint,
          onPressed: _attendanceMarked ? null : () {
            setState(() => _attendanceMarked = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance Recorded Successfully!'), backgroundColor: AppColors.success),
            );
          },
        ),
      ],
    );
  }
}
