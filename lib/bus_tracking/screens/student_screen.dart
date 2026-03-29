import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/location_service.dart';
import '../services/notification_service.dart';

class StudentScreen extends StatefulWidget {
  final String busId;
  const StudentScreen({Key? key, required this.busId}) : super(key: key);

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  GoogleMapController? _mapController;
  Position? _studentPosition;
  
  BitmapDescriptor? _busIconMoving;
  BitmapDescriptor? _busIconSlow;
  BitmapDescriptor? _busIconStopped;

  // Track state for local notification triggers to avoid spam
  bool _hasNotifiedArrival = false;
  bool _wasActivePreviously = false;

  @override
  void initState() {
    super.initState();
    _initIcons();
    _getStudentLocationAndListen();
  }

  Future<void> _initIcons() async {
    _busIconMoving = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _busIconSlow = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    _busIconStopped = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    setState(() {});
  }

  Future<void> _getStudentLocationAndListen() async {
    bool hasPermission = await LocationService.handlePermission();
    if (!hasPermission) return;
    
    // Listen to personal location
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((Position pos) {
      if (!mounted) return;
      setState(() => _studentPosition = pos);
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // returns KM
  }

  void _handleNotifications(bool isActive, double distanceKm, int etaMins, String status) {
    if (!isActive && _wasActivePreviously) {
      NotificationService.showNotification(
        id: 1,
        title: 'Trip Ended',
        body: 'The driver has completed the trip for ${widget.busId}.',
      );
    } else if (isActive && !_wasActivePreviously) {
      NotificationService.showNotification(
        id: 2,
        title: 'Trip Started! 🚌',
        body: '${widget.busId} has started the route!',
      );
      _hasNotifiedArrival = false; // Reset proximity trigger
    }

    _wasActivePreviously = isActive;

    if (isActive && !_hasNotifiedArrival && distanceKm > 0 && distanceKm < 0.5) { // < 500 meters
      NotificationService.showNotification(
        id: 3,
        title: 'Bus Approaching! ⚠️',
        body: 'Your bus is within 500m. Please get ready!',
      );
      _hasNotifiedArrival = true;
    }

    if (isActive && etaMins > 30 && status == 'slow') {
        // Just an example logic for Delay notification
        // You would compare against an expected_arrival_time field for real delays 
        // We will just skip spamming delay locally for now outside of structured parameters.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Track ${widget.busId}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('locations').doc(widget.busId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          bool isActive = data['is_active'] ?? false;
          double busLat = data['latitude'] ?? 0.0;
          double busLng = data['longitude'] ?? 0.0;
          dynamic rawSpeed = data['speed'] ?? 0.0;
          double speed = rawSpeed is String ? double.tryParse(rawSpeed) ?? 0.0 : rawSpeed.toDouble();
          String status = data['status'] ?? 'stopped'; 

          LatLng busCurrentLatLng = LatLng(busLat, busLng);

          BitmapDescriptor markerIcon = _busIconStopped!;
          if (status == 'moving') markerIcon = _busIconMoving!;
          if (status == 'slow') markerIcon = _busIconSlow!;

          double distanceKm = 0.0;
          int etaMins = 0;

          if (_studentPosition != null && busLat != 0.0) {
             distanceKm = _calculateDistance(_studentPosition!.latitude, _studentPosition!.longitude, busLat, busLng);
             double assumedAvgSpeed = speed > 5 ? speed : 25.0; // fallback avg city speed context
             etaMins = ((distanceKm / assumedAvgSpeed) * 60).round();
          }

          // Trigger automated background push-styled local alerts
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _handleNotifications(isActive, distanceKm, etaMins, status);
          });

          DateTime now = DateTime.now();
          DateTime expectedPickup = now.add(Duration(minutes: etaMins));

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: busCurrentLatLng, zoom: 15),
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                padding: const EdgeInsets.only(bottom: 300), // Push Google logo up
                markers: {
                  if (busLat != 0.0)
                    Marker(
                      markerId: const MarkerId('bus_marker'),
                      position: busCurrentLatLng,
                      icon: markerIcon,
                      zIndex: 2,
                    ),
                  if (_studentPosition != null)
                    Marker(
                      markerId: const MarkerId('student_marker'),
                      position: LatLng(_studentPosition!.latitude, _studentPosition!.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      zIndex: 1,
                    )
                },
              ),
              
              if (!isActive)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Text("Bus is currently offline", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ),

              // Modern Floating Info Panel
              if (isActive)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 0, blurRadius: 30, offset: const Offset(0, -5))]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estimated Arrival', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                                Text('$etaMins mins', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: status == 'moving' ? Colors.green.withOpacity(0.1) : (status == 'slow' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.directions_bus, size: 16, color: status == 'moving' ? Colors.green : (status == 'slow' ? Colors.orange : Colors.red)),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: status == 'moving' ? Colors.green : (status == 'slow' ? Colors.orange : Colors.red)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(Icons.speed, 'Speed', '${speed.toStringAsFixed(1)} km/h'),
                            _buildMiniStat(Icons.map, 'Distance', '${distanceKm.toStringAsFixed(2)} km'),
                            _buildMiniStat(Icons.schedule, 'Pickup', _formatTime(expectedPickup)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
