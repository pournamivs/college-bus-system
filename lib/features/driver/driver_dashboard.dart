import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentIndex = 0;
  
  // The actual screens for bottom nav
  final List<Widget> _screens = [
    const DriverHomeScreen(),
    const Scaffold(body: Center(child: Text("My Route"))),
    const Scaffold(body: Center(child: Text("Alerts"))),
    const Scaffold(body: Center(child: Text("Settings"))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.route_rounded), label: 'My Route'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnTrip = false;
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng _center = const LatLng(10.8505, 76.2711);

  String _driverName = "Loading...";
  String _driverId = "Loading...";
  String _driverRoute = "Loading...";
  String _driverPhone = "";
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchDriverDetails();
  }

  Future<void> _fetchDriverDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('userPhone');
      if (phone == null) return;
      _driverPhone = phone;

      final doc = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).limit(1).get();
      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        if (mounted) {
          setState(() {
            _driverName = data['name'] ?? 'Driver';
            _driverId = data['busNumber'] ?? 'Unknown';
            _driverRoute = data['route'] ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching driver details: $e');
    }
  }

  Future<void> _toggleTrip() async {
    if (_isOnTrip) {
      // Stop trip
      _positionStream?.cancel();
      _positionStream = null;
      setState(() => _isOnTrip = false);
      
      if (_driverPhone.isNotEmpty) {
         FirebaseFirestore.instance.collection('locations').doc(_driverPhone).delete();
      }
    } else {
      // Start trip
      final hasPermission = await LocationService().checkPermissions();
      if (!hasPermission) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions required.')));
        }
        return;
      }
      setState(() => _isOnTrip = true);
      _positionStream = LocationService().getPositionStream().listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
        _updateLocationOnFirestore(position);
        
        // Update map
        if (_controller.isCompleted) {
          _controller.future.then((c) {
            c.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
          });
        }
      });
    }
  }

  void _updateLocationOnFirestore(Position position) {
    if (_driverPhone.isEmpty) return;
    FirebaseFirestore.instance.collection('locations').doc(_driverPhone).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed * 3.6, // m/s to km/h
      'heading': position.heading,
      'timestamp': FieldValue.serverTimestamp(),
      'busId': _driverId, 
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Profile Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Driver Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_outline, color: AppColors.primary),
                      onPressed: () {}, // Navigate to profile
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.local_shipping, size: 28, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ID: $_driverId • $_driverRoute',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          _driverPhone,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trip Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnTrip ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnTrip ? 'Status: On Trip' : 'Status: Idle',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    'Last updated: Just now',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Map Section
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null 
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _center,
                      zoom: 14.0,
                    ),
                    markers: _currentPosition != null ? {
                      Marker(
                        markerId: const MarkerId('driver_bus'),
                        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                      )
                    } : {},
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Speed', _isOnTrip && _currentPosition != null ? '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h' : '0 km/h', Icons.speed),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Occupancy', '25/40', Icons.people_alt_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Next Stop', _isOnTrip ? 'City Center' : '-', Icons.place_outlined),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('ETA', _isOnTrip ? '5 mins' : '-', Icons.access_time),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Trip Controls
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _toggleTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOnTrip ? AppColors.error : AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isOnTrip ? 'END TRIP' : 'START TRIP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions Grid
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction('Navigation', Icons.navigation_rounded, () {}),
                  _buildQuickAction('Call Admin', Icons.phone_in_talk_rounded, () {}),
                  _buildQuickAction('Attendance', Icons.how_to_reg_rounded, () {}),
                ],
              ),
              const SizedBox(height: 32),

              // Emergency Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.warning_rounded, size: 28),
                  label: const Text(
                    'EMERGENCY ALERT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
