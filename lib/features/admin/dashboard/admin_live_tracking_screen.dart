import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';

class AdminLiveTrackingScreen extends StatefulWidget {
  const AdminLiveTrackingScreen({super.key});

  @override
  State<AdminLiveTrackingScreen> createState() => _AdminLiveTrackingScreenState();
}

class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946), // Default to Bangalore or project location
    zoom: 12,
  );

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> buses) {
    final markers = <Marker>{};
    for (var bus in buses) {
      final double? latitude = (bus['currentLat'] is num)
          ? (bus['currentLat'] as num).toDouble()
          : (bus['latitude'] is num ? (bus['latitude'] as num).toDouble() : null);
      final double? longitude = (bus['currentLng'] is num)
          ? (bus['currentLng'] as num).toDouble()
          : (bus['longitude'] is num ? (bus['longitude'] as num).toDouble() : null);

      if (latitude != null && longitude != null) {
        final markerId = MarkerId(bus['id']);
        final marker = Marker(
          markerId: markerId,
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            bus['status'] == 'active' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed
          ),
          infoWindow: InfoWindow(
            title: 'Bus ${bus['number'] ?? 'N/A'}',
            snippet: 'Status: ${bus['status']?.toUpperCase() ?? 'OFFLINE'} | Speed: ${bus['speed']?.toStringAsFixed(1) ?? 0} km/h',
          ),
        );
        markers.add(marker);
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Fleet Monitoring'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.streamBuses(),
        builder: (context, snapshot) {
          final Set<Marker> markers = snapshot.hasData ? _buildMarkers(snapshot.data!) : {};
          
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialPosition,
                onMapCreated: _onMapCreated,
                markers: markers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              _buildOverlayStats(snapshot.data?.length ?? 0, markers),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlayStats(int count, Set<Marker> markers) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total Buses', '$count', Icons.directions_bus),
              _statItem('Active', '${markers.where((m) => m.icon == BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)).length}', Icons.bolt, color: AppColors.success),
              _statItem('Offline', '${markers.where((m) => m.icon == BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)).length}', Icons.power_off, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 20),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
