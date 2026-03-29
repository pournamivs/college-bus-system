import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_service.dart';

class DriverScreen extends StatefulWidget {
  final String busId;
  const DriverScreen({Key? key, required this.busId}) : super(key: key);

  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isTripActive = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  GoogleMapController? _mapController;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    DocumentSnapshot busDoc = await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.busId)
        .get();
        
    if (busDoc.exists) {
      bool active = busDoc.get('is_active') ?? false;
      setState(() => _isTripActive = active);
      if (active) {
        _startTrip();
      }
    }
  }

  Future<void> _toggleTrip() async {
    if (_isTripActive) {
      await _stopTrip();
    } else {
      await _startTrip();
    }
  }

  Future<void> _startTrip() async {
    bool hasPermission = await LocationService.handlePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are required.')),
      );
      return;
    }

    setState(() => _isTripActive = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 15, // update every 15 meters to save battery
      ),
    ).listen((Position position) {
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
        _currentSpeed = position.speed * 3.6; // m/s to km/h
      });
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
              bearing: position.heading, // rotate map to heading direction
            )
          ),
        );
      }

      _updateLocationInFirebase(position);
    });

    // We can trigger an FCM notification cloud function here 
    // or handle trip start locally via listeners on Student app side.
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.busId)
        .set({'is_active': true, 'status': 'moving'}, SetOptions(merge: true));
  }

  Future<void> _stopTrip() async {
    setState(() {
      _isTripActive = false;
      _currentSpeed = 0.0;
    });
    await _positionStream?.cancel();
    
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.busId)
        .set({
      'is_active': false,
      'status': 'stopped',
    }, SetOptions(merge: true));
  }

  Future<void> _updateLocationInFirebase(Position pos) async {
    double speedKmh = pos.speed * 3.6;
    String status = 'stopped';
    
    if (speedKmh > 10) status = 'moving';
    else if (speedKmh > 0 && speedKmh <= 10) status = 'slow';

    await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.busId)
        .set({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'speed': speedKmh.toStringAsFixed(1), // optimize storage payload string
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
      'is_active': true,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Trip Dashboard - ${widget.busId}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              await _stopTrip();
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapType: MapType.normal,
                ),
                
          // Modern Floating Bottom Panel
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
                ]
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
                          Text('Current Speed', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                          Text('${_currentSpeed.toStringAsFixed(1)} km/h', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isTripActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isTripActive ? 'Live Broadcasting' : 'Trip Stopped',
                          style: TextStyle(
                            color: _isTripActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _toggleTrip,
                    child: Text(
                      _isTripActive ? 'END TRIP' : 'START TRIP',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
