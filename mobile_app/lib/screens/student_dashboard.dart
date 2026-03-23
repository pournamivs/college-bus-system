import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import '../widgets/sos_button.dart';
import 'dart:async';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'package:http/http.dart' as http; // Added for http.get

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final MapController _mapController = MapController();
  WebSocketChannel? _channel;
  LatLng _busLocation = LatLng(10.0238, 76.3129); // Mock starting pos
  bool _isConnected = false;
  Map<String, dynamic>? _etaData;
  String _assignedStop = 'Not Assigned';
  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  final LocalAuthentication auth = LocalAuthentication();
  bool _attendanceMarked = false;
  List<dynamic> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _connectWebSocket();
    _fetchLinkingRequests();
  }

  Future<void> _fetchLinkingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/linking-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() => _pendingRequests = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching requests: $e");
    }
  }

  Future<void> _approveRequest(int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/approve-linking/$requestId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Linked successfully!')));
        _fetchLinkingRequests();
      }
    } catch (e) {
      print("Error approving: $e");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _assignedStop = prefs.getString('assigned_stop') ?? 'Not Assigned';
    });
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
      }, onDone: () {
        _handleDisconnect();
      }, onError: (e) {
        _handleDisconnect();
      });
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (!mounted) return;
    setState(() {
      _isConnected = false;
      if (!_isReconnecting) {
        _isReconnecting = true;
        _reconnectTimer = Timer(Duration(seconds: 5), () {
          if (mounted) {
            _isReconnecting = false;
            _connectWebSocket();
          }
        });
      }
    });
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

  Future<void> _markAttendance() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      
      if (!isSupported || !canCheckBiometrics) {
        // Mock success for testing without actual hardware
        setState(() => _attendanceMarked = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated Attendance Success (Scanner off)')));
        return;
      }
      
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please scan your fingerprint to mark attendance on the bus',
        biometricOnly: true,
      );
      
      if (didAuthenticate) {
        // Here we would call the REST API: POST /api/student/attendance
        setState(() => _attendanceMarked = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance Marked Successfully!')));
      }
    } catch (e) {
      print(e);
      // Fallback/Mock success for the emulator
      setState(() => _attendanceMarked = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated Success (Emulator bypassing scanner)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TrackMyBus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo.shade800,
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
              color: Colors.indigo.shade800,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LIVE TRACKING', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green.shade400 : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_isConnected ? 'CONNECTED' : 'OFFLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR STOP', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(_assignedStop, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isConnected && _etaData != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile('NEXT STOP', _etaData!['next_stop'], Icons.next_plan),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile('ARRIVAL', '${_etaData!['eta_minutes']} MIN', Icons.timer),
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
                        child: Icon(Icons.directions_bus, color: Colors.indigo, size: 36),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Boarding Actions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.indigo.shade900)),
                SizedBox(height: 8),
                Text('Mark your biometric attendance once inside the bus.', style: TextStyle(color: Colors.grey.shade600)),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _attendanceMarked ? null : _markAttendance,
                  icon: Icon(_attendanceMarked ? Icons.check_circle : Icons.fingerprint, size: 36),
                  label: Text(_attendanceMarked ? 'Attendance Recorded' : 'Scan Fingerprint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: _attendanceMarked ? Colors.green : Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SOSButton(),
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
