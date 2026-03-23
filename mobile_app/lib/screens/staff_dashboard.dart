import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../widgets/sos_button.dart';
import 'dart:async';
import '../utils/theme.dart';
import '../utils/constants.dart';

class StaffDashboard extends StatefulWidget {
  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final MapController _mapController = MapController();
  WebSocketChannel? _channel;
  LatLng _busLocation = LatLng(10.0238, 76.3129);
  bool _isConnected = false;
  Map<String, dynamic>? _etaData;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConstants.wsBaseUrl}/ws/bus/bus_102'),
      );
      
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['lat'] != null && data['lng'] != null) {
          setState(() {
            _busLocation = LatLng(data['lat'], data['lng']);
            _isConnected = true;
            if (data['eta'] != null) {
              _etaData = data['eta'];
            }
          });
          _mapController.move(_busLocation, 15.0);
        }
      }, onDone: () => setState(() => _isConnected = false),
         onError: (e) => setState(() => _isConnected = false));
    } catch (e) {
      print("WS Error: $e");
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fleet Manager', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.shade800,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            decoration: BoxDecoration(
              color: Colors.teal.shade800,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FLEET STATUS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green.shade400 : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_isConnected ? 'LIVE' : 'OFFLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (_isConnected && _etaData != null) ...[
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile('ACTIVE BUS', 'Bus 102', Icons.directions_bus),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile('NEXT STOP', _etaData!['next_stop'], Icons.next_plan),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _busLocation,
                initialZoom: 14.0,
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
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.directions_bus, color: Colors.teal, size: 36),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: SOSButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 12),
              SizedBox(width: 4),
              Text(label, style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 2),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
