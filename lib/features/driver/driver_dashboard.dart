import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/custom_gradient_button.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  bool _isTripStarted = false;
  bool _isMockModeEnabled = false;
  bool _isLoading = true; // Add loading state
  StreamSubscription<Position>? _positionStream;
  Timer? _mockTimer;
  
  double _mockLat = 10.0276;
  double _mockLng = 76.3084;
  
  Map<String, dynamic>? _assignedBus;
  String? _busIdString;
  String _statusMessage = 'Fetching assigned bus...';
  bool _isSalaryCredited = false;

  LatLng _busPosition = const LatLng(10.0276, 76.3084);
  StreamSubscription<DocumentSnapshot>? _busLocationSubscription;
  final MapController _mapController = MapController();
  int _studentCount = 55; // Placeholder matching the UI, can be updated dynamically
  int _currentIndex = 2; // For Bottom Nav (Trip active in image)

  // Mock list of students
  final List<Map<String, String>> _mockStudents = [
    {'name': 'Anshul Kumar', 'adm': '1234', 'route': 'Route A', 'time': '2 mins ago'},
    {'name': 'Rohit Sharma', 'adm': '1235', 'route': 'Route A', 'time': '2 mins ago'},
    {'name': 'Rajesh Menon', 'adm': '1236', 'route': 'Route A', 'time': '2 mins ago'},
  ];

  
  // Network connectivity
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _isOnline = false;

  // Location optimization
  LatLng? _lastSentPosition;
  static const double _minDistanceThreshold = 10.0; // meters
  Timer? _locationUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    debugPrint('[DRIVER DASHBOARD] Mounted natively. Isolating Student components.');
    _fetchAssignedBus();
    _fetchDriverProfile();
    _initConnectivity();
  }

  Future<void> _fetchDriverProfile() async {
    final uid = await _authService.getUid();
    if (uid == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _isSalaryCredited = userDoc.data()?['salary_credited'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('[DRIVER DASHBOARD] Error fetching profile: $e');
    }
  }

  Future<void> _fetchAssignedBus() async {
    final uid = await _authService.getUid();
    if (uid == null) return;

    try {
      final busData = await _firestoreService.getMyBus(uid);
      if (busData != null && mounted) {
        setState(() {
          _assignedBus = busData;
          _busIdString = busData['id'];
          debugPrint('[DRIVER DASHBOARD] Linked to Bus ID: $_busIdString');
          _statusMessage = 'Ready on ${_assignedBus!['name']}';
          _isLoading = false; // Set loading to false
        });
        _startBusLocationListener();
      } else {
        if (mounted) setState(() {
          _statusMessage = 'No bus assigned';
          _isLoading = false; // Set loading to false
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _statusMessage = 'Offline - Check Firestore';
        _isLoading = false; // Set loading to false
      });
    }
  }

  void _startBusLocationListener() {
    if (_busIdString == null || _busIdString!.isEmpty) return;
    _busLocationSubscription?.cancel();

    _busLocationSubscription = _firestoreService.streamBusLocation(_busIdString!).listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final lat = (data['lat'] is num) ? (data['lat'] as num).toDouble() : null;
      final lng = (data['lng'] is num) ? (data['lng'] as num).toDouble() : null;
      if (lat != null && lng != null) {
        setState(() {
          _busPosition = LatLng(lat, lng);
        });
        _mapController.move(_busPosition, 14.0);
      }
    });
  }

  Future<void> _startTrip() async {
    if (!_isMockModeEnabled) {
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required to broadcast live.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    if (_busIdString == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start trip: No specific Bus ID assigned to your profile!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isTripStarted = true;
      _statusMessage = _isMockModeEnabled 
          ? 'Trip Active: MOCK GEO-SPOOFING...'
          : 'Trip Active: Broadcasting Location...';
    });

    // Write Trip Open status metadata
    await _firestoreService.updateBusStatus(_busIdString!, 'active');

    if (_isMockModeEnabled) {
      // Artificial Demo Spoofer
      _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_isTripStarted) return;
        // Increment coordinate artificially
        _mockLat += 0.0001; // Drift north
        _mockLng += 0.0001; // Drift east
        debugPrint('[DRIVER SPOOF] Simulating lat/lng: $_mockLat, $_mockLng to $_busIdString');
        _firestoreService.updateBusLocation(_busIdString!, _mockLat, _mockLng);
      });
    } else {
      // Subscribe to accurate GeoLocator continuous ticking interval with optimization
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 2), // Check every 2 seconds
        ),
      ).listen((Position position) {
        if (!_isTripStarted) return;

        final currentPos = LatLng(position.latitude, position.longitude);

        // Only send update if moved more than threshold or first update
        if (_lastSentPosition == null ||
            Geolocator.distanceBetween(
              _lastSentPosition!.latitude,
              _lastSentPosition!.longitude,
              currentPos.latitude,
              currentPos.longitude,
            ) >= _minDistanceThreshold) {

          debugPrint('[DRIVER STREAM] Pushing lat/lng: ${position.latitude}, ${position.longitude} to bus_locations/$_busIdString');
          _firestoreService.updateBusLocation(_busIdString!, position.latitude, position.longitude);

          _lastSentPosition = currentPos;
          _mockLat = position.latitude;
          _mockLng = position.longitude;
          setState(() {
            _busPosition = currentPos;
          });
          _mapController.move(_busPosition, 14.0);
        }
      });
    }
  }

  Future<void> _stopTrip() async {
    setState(() {
      _isTripStarted = false;
      _statusMessage = 'Trip Stopped';
    });

    await _positionStream?.cancel();
    _positionStream = null;
    _mockTimer?.cancel();
    _mockTimer = null;
    _lastSentPosition = null; // Reset for next trip

    if (_busIdString != null) {
      await _firestoreService.updateBusStatus(_busIdString!, 'maintenance');
      debugPrint('[DRIVER DASHBOARD] Trip Terminated cleanly.');
    }
  }

  void _toggleTrip() async {
    if (_isTripStarted) {
      await _stopTrip();
    } else {
      await _startTrip();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mockTimer?.cancel();
    _busLocationSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(results);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    setState(() {
      _connectivityResult = result;
      _isOnline = result != ConnectivityResult.none;
    });

    debugPrint('[DRIVER DASHBOARD] Connectivity changed: $_connectivityResult (Online: $_isOnline)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text('Driver Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP CARDS ROW ---
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_bus, color: Color(0xFF6A1B9A), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Assigned Bus', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(_assignedBus?['name'] ?? 'KL-07-AB-1234', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    const Text('Route A - Ernakulam', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF6A1B9A), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total\nStudents', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text('$_studentCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF6A1B9A))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // --- STATUS DOTS ROW ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusPill('Moving', Colors.green),
                      _buildStatusPill('Slow', Colors.orange),
                      _buildStatusPill('Stopped', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // --- TRIP CONTROLS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trip Controls', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.tune, size: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Trip Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _startTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Start Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Segmented Controls Block
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSegmentButton('Stop Trip', true, _stopTrip)),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        Expanded(child: _buildSegmentButton('Report Issue', false, () => context.push('/driver/complaints'))),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        Expanded(child: _buildSegmentButton('Refresh', false, () { setState(() {}); })),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // --- STUDENT LIST SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Student List ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Icon(Icons.refresh, size: 16, color: const Color(0xFF6A1B9A)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: const [
                            Icon(Icons.filter_list, size: 16, color: Colors.black54),
                            SizedBox(width: 4),
                            Icon(Icons.sort, size: 16, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Students List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mockStudents.length,
                    itemBuilder: (context, index) {
                      final student = _mockStudents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2D4F0), width: 1.5), // Light purple border
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2D4F0), // Soft purple background
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Color(0xFF6A1B9A), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text('Adm.No: ${student['adm']} - ${student['route']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text(student['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6A1B9A),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 4) {
            // Settings -> mock functionality logout for now just to have an action
            _authService.logout().then((_) => context.go('/login'));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Trip'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(title == 'Stop Trip' ? 12 : 0),
            right: Radius.circular(title == 'Refresh' ? 12 : 0),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
