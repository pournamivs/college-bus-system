import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import '../utils/theme.dart';

class ParentDashboard extends StatefulWidget {
  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  List<dynamic> _children = [];
  bool _isLoading = true;
  WebSocketChannel? _channel;
  LatLng _busLocation = LatLng(10.0238, 76.3129);
  bool _isTracking = false;
  String? _trackingChildName;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/children'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _children = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching children: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startTracking(dynamic child) {
    _channel?.sink.close();
    setState(() {
      _isTracking = true;
      _trackingChildName = child['name'];
      _isConnected = false;
    });
    
    _channel = WebSocketChannel.connect(
      Uri.parse('${AppConstants.wsBaseUrl}/ws/bus/bus_102'),
    );
    
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['lat'] != null && data['lng'] != null) {
        setState(() {
          _busLocation = LatLng(data['lat'], data['lng']);
        });
      }
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Connect', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple.shade800,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (_children.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.child_care, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No children linked yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showLinkRequestDialog(),
                          child: Text('Link a Student'),
                        )
                      ],
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade800,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SELECT CHILD TO TRACK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          IconButton(
                            onPressed: () => _showLinkRequestDialog(),
                            icon: Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                          )
                        ],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _children.length,
                          itemBuilder: (context, index) {
                            final child = _children[index];
                            final isSelected = _trackingChildName == child['name'];
                            return GestureDetector(
                              onTap: () => _startTracking(child),
                              child: Container(
                                width: 140,
                                margin: EdgeInsets.only(right: 12),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isSelected ? Colors.deepPurple.shade50 : Colors.white10,
                                      child: Icon(Icons.person, color: isSelected ? Colors.deepPurple : Colors.white70, size: 20),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(child['name'], style: TextStyle(color: isSelected ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                          Text(child['assigned_stop'] ?? 'No Stop', style: TextStyle(color: isSelected ? Colors.black54 : Colors.white70, fontSize: 10)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _busLocation,
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.trackmybus.app',
                          ),
                          if (_isTracking)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _busLocation,
                                  width: 60,
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.directions_bus, color: Colors.deepPurple, size: 36),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (!_isTracking)
                        Container(
                          color: Colors.black45,
                          child: Center(
                            child: Text(
                              'Select a child to track their bus',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (_isTracking)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TRACKING: $_trackingChildName', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                Text('Bus Status: Active', style: TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ]
            ],
          ),
    );
  }

  void _showLinkRequestDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link a Student'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(hintText: 'Student Email Address'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              final response = await http.post(
                Uri.parse('${AppConstants.apiBaseUrl}/api/auth/link-student'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({'student_email': emailController.text}),
              );
              Navigator.pop(context);
              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request sent to Student!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Student not found or already linked')));
              }
            },
            child: Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
