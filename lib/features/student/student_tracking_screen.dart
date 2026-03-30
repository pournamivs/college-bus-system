import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_card.dart';

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final lat = begin!.latitude + (end!.latitude - begin!.latitude) * t;
    final lng = begin!.longitude + (end!.longitude - begin!.longitude) * t;
    return LatLng(lat, lng);
  }
}

class StudentTrackingScreen extends StatefulWidget {
  const StudentTrackingScreen({super.key});

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription<DocumentSnapshot>? _locationSub;

  static const LatLng _defaultCenter = LatLng(10.8505, 76.2711);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  AnimationController? _animationController;
  Animation<LatLng>? _markerAnimation;
  LatLng? _oldPosition;
  double _currentSpeedKmh = 0.0;
  
  bool _isLoading = true;
  String _driverName = "Loading...";
  String _driverPhone = "";
  String _busNumber = "Loading...";
  String _routeName = "Loading...";
  String _status = "Loading";
  String _lastUpdated = "Just now";
  String _eta = "Calculating...";
  double _distance = 0.0;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController!.addListener(() {
      if (_markerAnimation != null && mounted) {
        _updateMarkerUI(_markerAnimation!.value, _currentSpeedKmh);
      }
    });
    _initTracking();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('userPhone');
    
    if (userPhone == null) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch user data to get assigned route
      final userDoc = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: userPhone).limit(1).get();
      if (userDoc.docs.isEmpty) throw Exception('User not found');
      
      final userData = userDoc.docs.first.data();
      final assignedRoute = userData['route'] ?? 'Unknown Route';
      
      if(mounted) setState(() => _routeName = assignedRoute);

      // 2. Fetch driver assigned to that route
      final driverQuery = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('route', isEqualTo: assignedRoute)
          .limit(1).get();
          
      String targetDriverPhone = '';
      
      if (driverQuery.docs.isNotEmpty) {
        final driverData = driverQuery.docs.first.data();
        targetDriverPhone = driverData['phone'] ?? '';
        if(mounted) {
          setState(() {
            _driverName = driverData['name'] ?? 'Assigned Driver';
            _driverPhone = targetDriverPhone;
            _busNumber = driverData['busNumber'] ?? 'Bus Info Unavailable';
          });
        }
      } else {
        if(mounted) {
          setState(() {
            _driverName = 'Driver Not Found';
            _driverPhone = 'Unavailable';
            _busNumber = 'Unknown';
            _status = 'No Driver Assigned';
            _isLoading = false;
          });
        }
        return; // Don't try to listen to empty phone location
      }

      // 3. Listen to active trip location for that driver
      _locationSub = FirebaseFirestore.instance.collection('locations').doc(targetDriverPhone).snapshots().listen((docSnapshot) {
        if (!docSnapshot.exists) return;
        
        final data = docSnapshot.data()!;
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final speed = data['speed'] as double? ?? 0.0;
        final timestamp = data['timestamp'] as Timestamp?;
        
        if (lat != null && lng != null) {
          _updateMapLocation(LatLng(lat, lng), speed, timestamp?.toDate());
        }
      });
      
      if(mounted) setState(() => _isLoading = false);
      
    } catch (e) {
      debugPrint('Error init tracking: $e');
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMapLocation(LatLng position, double speedKmh, DateTime? timestamp) async {
    _currentSpeedKmh = speedKmh;

    if (_oldPosition == null) {
      _oldPosition = position;
      _updateMarkerUI(position, speedKmh);
    } else {
      _markerAnimation = LatLngTween(begin: _oldPosition!, end: position).animate(CurvedAnimation(
        parent: _animationController!, curve: Curves.linear));
      _animationController!.forward(from: 0.0);
      _oldPosition = position;
    }

    if (timestamp != null) {
      final diff = DateTime.now().difference(timestamp);
      if (diff.inMinutes == 0) _lastUpdated = 'Just now';
      else _lastUpdated = '${diff.inMinutes} mins ago';
    }

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _updateMarkerUI(LatLng position, double speedKmh) {
    if (speedKmh > 10) {
      _statusColor = Colors.green;
      _status = 'Moving';
    } else if (speedKmh > 0 && speedKmh <= 10) {
      _statusColor = Colors.orange;
      _status = 'Slow';
    } else {
      _statusColor = Colors.red;
      _status = 'Stopped';
    }

    _distance = _calculateDistance(_defaultCenter.latitude, _defaultCenter.longitude, position.latitude, position.longitude);
    if (_status == 'Moving') {
      int minutes = (_distance / 30.0 * 60).round(); 
      _eta = '$minutes Mins';
    } else {
      _eta = 'Delayed';
    }

    if(mounted) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('bus_marker'),
            position: position,
            infoWindow: InfoWindow(title: 'Bus: $_busNumber', snippet: 'Speed: ${speedKmh.toStringAsFixed(1)} km/h'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _status == 'Moving' ? BitmapDescriptor.hueGreen : 
              _status == 'Slow' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
            ),
          )
        };
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_defaultCenter, position],
            color: AppColors.primary,
            width: 4,
          )
        };
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
          math.cos(lat1 * p) * math.cos(lat2 * p) * 
          (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Stack(
        children: [
          // Google Map Background
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 14.4746,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Top Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: _initTracking,
                      tooltip: 'Refresh Location',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arriving in',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            Text(
                              _eta,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _statusColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_bus, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('${_distance.toStringAsFixed(1)} km', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Status: $_status • Updated $_lastUpdated', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$_driverName ($_driverPhone)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                    Text('$_routeName • Bus $_busNumber', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.call, color: AppColors.primary),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
