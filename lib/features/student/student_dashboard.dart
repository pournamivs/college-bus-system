import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_directions_service.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/custom_gradient_button.dart';
import '../../../core/widgets/stat_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleDirectionsService _directionsService = GoogleDirectionsService();

  String? _busIdString;
  String? _driverIdString;
  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _driverData;
  String _statusMessage = 'Initializing Tracker...';

  bool _permissionsGranted = false;
  LatLng _currentBusPosition = const LatLng(10.0276, 76.3084);
  LatLng _studentPosition = const LatLng(10.0276, 76.3084);
  final MapController _mapController = MapController();

  StreamSubscription<DocumentSnapshot>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _driverSubscription;

  List<LatLng> _routePoints = [];
  Map<String, dynamic>? _directionsData;
  double _distanceToBus = 0.0;
  bool _isLoadingRoute = false;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeEnvironment();
  }

  Future<void> _initializeEnvironment() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      if (mounted) setState(() => _permissionsGranted = true);
      _fetchStudentData();
    } else {
      if (mounted)
        setState(() => _statusMessage = 'Location permissions denied');
      _fetchStudentData();
    }
  }

  Future<void> _fetchStudentData() async {
    final uid = await _authService.getUid();
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _busIdString = (data['busId'] ?? '').toString();
        _driverIdString = (data['driverId'] ?? '').toString();

        if (_busIdString != null && _busIdString!.isNotEmpty) {
          _fetchBusInfo();
          _listenToBusPlatform();
        } else {
          if (mounted) setState(() => _statusMessage = 'No Bus Assigned');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Error Fetching Profile');
    }
  }

  Future<void> _fetchBusInfo() async {
    final busDoc = await FirebaseFirestore.instance
        .collection('buses')
        .doc(_busIdString)
        .get();
    if (busDoc.exists && mounted) {
      setState(() {
        _busData = busDoc.data();
      });
    }
  }

  void _calculateDistance() {
    if (_permissionsGranted) {
      Geolocator.getCurrentPosition()
          .then((position) {
            setState(() {
              _studentPosition = LatLng(position.latitude, position.longitude);
            });
            _fetchDirectionsAndDistance();
          })
          .catchError((error) {
            debugPrint('Error getting student position: $error');
          });
    }
  }

  Future<void> _fetchDirectionsAndDistance() async {
    if (_currentBusPosition.latitude == 10.0276 &&
        _currentBusPosition.longitude == 76.3084)
      return;
    setState(() => _isLoadingRoute = true);

    try {
      const LatLng destination = LatLng(9.9833, 76.2833);
      final directionsData = await _directionsService.getDirections(
        _currentBusPosition,
        destination,
      );

      if (directionsData != null && mounted) {
        final routePoints = _directionsService.decodePolyline(
          directionsData['routes'][0]['overview_polyline']['points'],
        );
        final distance = _directionsService.getRouteDistance(directionsData);
        setState(() {
          _directionsData = directionsData;
          _routePoints = routePoints;
          _distanceToBus = distance;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      final distance =
          Geolocator.distanceBetween(
            _studentPosition.latitude,
            _studentPosition.longitude,
            _currentBusPosition.latitude,
            _currentBusPosition.longitude,
          ) /
          1000;
      setState(() {
        _distanceToBus = distance;
        _isLoadingRoute = false;
      });
    }
  }

  void _listenToBusPlatform() {
    _locationSubscription = FirebaseFirestore.instance
        .collection('bus_locations')
        .doc(_busIdString)
        .snapshots()
        .listen((snap) {
          if (snap.exists && snap.data() != null) {
            final data = snap.data()!;
            final double lat = (data['lat'] is num)
                ? (data['lat'] as num).toDouble()
                : 10.0276;
            final double lng = (data['lng'] is num)
                ? (data['lng'] as num).toDouble()
                : 76.3084;
            final newPos = LatLng(lat, lng);

            if (mounted) {
              setState(() {
                _currentBusPosition = newPos;
                _statusMessage = 'Live Tracking Active';
                _mapController.move(_currentBusPosition, 16.0);
              });
              _calculateDistance();
            }
          } else {
            if (mounted) setState(() => _statusMessage = 'Bus Offline');
          }
        });

    _driverSubscription = FirebaseFirestore.instance
        .collection('buses')
        .doc(_busIdString)
        .snapshots()
        .listen((snap) async {
          if (snap.exists && snap.data() != null) {
            final busInfo = snap.data()!;
            final driverIdFromBus = (busInfo['driverId'] ?? '').toString();
            String? driverIdToResolve = driverIdFromBus.isNotEmpty
                ? driverIdFromBus
                : _driverIdString;

            if (driverIdToResolve != null && driverIdToResolve.isNotEmpty) {
              final dDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(driverIdToResolve)
                  .get();
              if (dDoc.exists && mounted) {
                setState(() {
                  _driverData = dDoc.data();
                  _statusMessage =
                      'Driver: ${_driverData?['name'] ?? 'Assigned'}';
                });
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _driverSubscription?.cancel();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      context.push('/student/fees'); // Assuming Fees route exists
    } else if (index == 3) {
      setState(() => _currentIndex = index);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // Body Content based on index
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeTab(),
                  _buildTrackBusTab(),
                  const Center(
                    child: Text('Fees Tab'),
                  ), // Handled via push usually, but here as fallback
                  _buildProfileTab(),
                ],
              ),
            ),

            // Custom Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => _onBottomNavTapped(0),
                    child: _navBarItem(Icons.home, 'Home', _currentIndex == 0),
                  ),
                  InkWell(
                    onTap: () => _onBottomNavTapped(1),
                    child: _navBarItem(
                      Icons.directions_bus,
                      'Track Bus',
                      _currentIndex == 1,
                    ),
                  ),
                  InkWell(
                    onTap: () => _onBottomNavTapped(2),
                    child: _navBarItem(
                      Icons.account_balance_wallet,
                      'Fees',
                      _currentIndex == 2,
                    ),
                  ),
                  InkWell(
                    onTap: () => _onBottomNavTapped(3),
                    child: _navBarItem(
                      Icons.person,
                      'Profile',
                      _currentIndex == 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Greeting header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Good Morning, Student',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      size: 28,
                      color: Color(0xFF6A1B9A),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 4, height: 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stat cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Expanded(
                  child: StatCard(
                    label: 'Attendance',
                    value: '85%',
                    icon: Icons.verified_user,
                    backgroundColor: Color(0xFF6A1B9A),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Pending Fees',
                    value: '₹12,500',
                    icon: Icons.account_balance_wallet,
                    backgroundColor: Color(0xFFFF9800),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Active Fines',
                    value: '₹200',
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // My Bus Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Color(0xFF6A1B9A),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route A – Ernakulam',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bus No: ${_busData?['name'] ?? 'KL-07-AB-1234'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Driver: ${_driverData?['name'] ?? 'Rajesh M'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '(+91 9876543210)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFF6A1B9A)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: CustomGradientButton(
                    text: 'Track Bus',
                    onPressed: () =>
                        setState(() => _currentIndex = 1), // switch to map
                    colors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/student/fees'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6A1B9A),
                      shadowColor: Colors.black12,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Color(0xFF6A1B9A),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Pay Fees',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Notifications
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recent Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF6A1B9A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _notificationCard(
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFD32F2F),
                  title: 'Fine Alert',
                  message: 'Please pay your pending fine of ₹200',
                  time: '2h ago',
                ),
                const SizedBox(height: 8),
                _notificationCard(
                  icon: Icons.info_outline,
                  color: const Color(0xFF6A1B9A),
                  title: 'General Notification',
                  message: 'Reminder: Tomorrow regular schedule',
                  time: '2h ago',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrackBusTab() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentBusPosition,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.trackmybus.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: const Color(0xFF6A1B9A),
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentBusPosition,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6A1B9A),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Color(0xFF6A1B9A),
                      size: 28,
                    ),
                  ),
                ),
                Marker(
                  point: _studentPosition,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Return to location FAB
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Color(0xFF6A1B9A)),
            onPressed: () => _mapController.move(_currentBusPosition, 16.0),
          ),
        ),

        // Bottom Map Info Card
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Route A - KL-07',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '~${_distanceToBus.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2D4F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF6A1B9A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver: ${_driverData?['name'] ?? 'Rajesh M'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            '+91 9876543210',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.phone, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFE2D4F0),
              child: const Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rahul Kumar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'SNCCE/22/CS/1234',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          _profileMenuTile('Academic Info', Icons.school),
          _profileMenuTile('Personal Info', Icons.person_outline),
          _profileMenuTile('Transport Info', Icons.directions_bus),
          _profileMenuTile(
            'Change Password',
            Icons.lock_outline,
            onTap: () => context.push('/change-password'),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await _authService.logout();
                if (mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileMenuTile(String title, IconData icon, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF6A1B9A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _navBarItem(IconData icon, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFF6A1B9A) : Colors.black38,
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF6A1B9A) : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
