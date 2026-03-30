import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:async';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Map'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.streamBuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final buses = snapshot.data ?? [];
          final Set<Marker> markers = buses.map((bus) {
            final lat = bus['currentLat'] as double? ?? 10.0276;
            final lng = bus['currentLng'] as double? ?? 76.3084;
            final name = bus['name'] as String? ?? 'Bus';
            
            return Marker(
              markerId: MarkerId(bus['id'] ?? name),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
            );
          }).toSet();
          
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.0276, 76.3084),
              zoom: 14.0,
            ),
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
          );
        },
      ),
    );
  }
}
