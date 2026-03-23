import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _buses = [];
  List<dynamic> _routes = [];
  List<dynamic> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final headers = {'Authorization': 'Bearer $token'};

      final responses = await Future.wait([
        http.get(Uri.parse('${AppConstants.apiBaseUrl}/api/admin/buses'), headers: headers),
        http.get(Uri.parse('${AppConstants.apiBaseUrl}/api/admin/routes'), headers: headers),
        http.get(Uri.parse('${AppConstants.apiBaseUrl}/api/admin/drivers'), headers: headers),
      ]);

      if (mounted) {
        if (responses.any((r) => r.statusCode != 200)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Admin access denied or server down.')));
        }
        setState(() {
          _buses = jsonDecode(responses[0].body);
          _routes = jsonDecode(responses[1].body);
          _drivers = jsonDecode(responses[2].body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: Check backend connection.')));
      }
    }
  }

  Future<void> _updateBus(int busId, {int? driverId, int? routeId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/api/admin/buses/$busId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (driverId != null) 'driver_id': driverId,
          if (routeId != null) 'route_id': routeId,
        }),
      );
      if (response.statusCode == 200) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bus updated successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Control Panel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(icon: Icon(Icons.add_business, color: Colors.white), onPressed: _showCreateBusDialog),
          IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: _fetchData),
          IconButton(icon: Icon(Icons.logout, color: Colors.white), onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushReplacementNamed(context, '/login');
          }),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildSectionHeader('FLEET MANAGEMENT', Icons.bus_alert),
              ..._buses.map((bus) => _buildBusCard(bus)).toList(),
              SizedBox(height: 24),
              SizedBox(height: 24),
              _buildSectionHeader('USER MANAGEMENT', Icons.people),
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Icon(Icons.person_add, color: Colors.indigo)),
                  title: Text('Add New User'),
                  subtitle: Text('Register a student, driver, or staff member'),
                  trailing: Icon(Icons.add),
                  onTap: _showCreateUserDialog,
                ),
              ),
              SizedBox(height: 80), // Space for FAB
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRouteDialog(),
        label: Text('NEW ROUTE'),
        icon: Icon(Icons.add_location_alt),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildBusCard(dynamic bus) {
    final driver = _drivers.firstWhere((d) => d['id'] == bus['driver_id'], orElse: () => null);
    final route = _routes.firstWhere((r) => r['id'] == bus['route_id'], orElse: () => null);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bus['number_plate'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(bus['name'], style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Divider(height: 24),
            _buildManagementRow(
              'Driver', 
              driver != null ? driver['name'] : 'Unassigned',
              Icons.person,
              () => _showAssignmentDialog('Assign Driver', _drivers, (id) => _updateBus(bus['id'], driverId: id)),
            ),
            SizedBox(height: 12),
            _buildManagementRow(
              'Route', 
              route != null ? route['name'] : 'Unassigned',
              Icons.map,
              () => _showAssignmentDialog('Assign Route', _routes, (id) => _updateBus(bus['id'], routeId: id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementRow(String label, String value, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Icon(Icons.chevron_right, size: 16, color: Colors.indigo),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildRouteCard(dynamic route) {
    final stops = jsonDecode(route['stops']) as List;
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(route['name'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${stops.length} Stops: ${stops.map((s) => s['name']).join(' → ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.edit, size: 20),
      ),
    );
  }

  void _showAssignmentDialog(String title, List<dynamic> items, Function(int) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(items[i]['name'] ?? items[i]['number_plate'] ?? 'Item ${items[i]['id']}'),
              onTap: () {
                onSelect(items[i]['id']);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateRouteDialog() {
    final nameController = TextEditingController();
    List<Map<String, dynamic>> stops = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('New Delivery Route'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Route Name')),
                SizedBox(height: 16),
                Text('STOPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ...stops.asMap().entries.map((entry) => ListTile(
                  title: Text(entry.value['name']),
                  trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => setDialogState(() => stops.removeAt(entry.key))),
                )),
                TextButton.icon(
                  onPressed: () => _addStopDialog(context, (s) => setDialogState(() => stops.add(s))),
                  icon: Icon(Icons.add),
                  label: Text('Add Stop'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && stops.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  final response = await http.post(
                    Uri.parse('${AppConstants.apiBaseUrl}/api/admin/routes'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: jsonEncode({'name': nameController.text, 'stops': jsonEncode(stops)}),
                  );
                  if (response.statusCode == 200) {
                    _fetchData();
                    Navigator.pop(ctx);
                  }
                }
              }, 
              child: Text('SAVE ROUTE'),
            )
          ],
        ),
      ),
    );
  }

  void _addStopDialog(BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final sName = TextEditingController();
    final sLat = TextEditingController();
    final sLng = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Stop Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sName, decoration: InputDecoration(labelText: 'Stop Name')),
            TextField(controller: sLat, decoration: InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number),
            TextField(controller: sLng, decoration: InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () {
            onAdd({'name': sName.text, 'lat': double.parse(sLat.text), 'lng': double.parse(sLng.text)});
            Navigator.pop(ctx);
          }, child: Text('ADD'))
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: ['student', 'driver', 'staff', 'parent', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (v) => setDialogState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  final response = await http.post(
                    Uri.parse('${AppConstants.apiBaseUrl}/api/auth/register'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: jsonEncode({
                      'name': nameController.text,
                      'email': emailController.text,
                      'password': passwordController.text,
                      'role': role,
                    }),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    _fetchData();
                    Navigator.pop(ctx);
                  }
                }
              }, 
              child: Text('CREATE USER'),
            )
          ],
        ),
      ),
    );
  }

  void _showCreateBusDialog() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    final capController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Register New Bus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Bus Name (e.g. Bus 105)')),
            TextField(controller: plateController, decoration: InputDecoration(labelText: 'Number Plate')),
            TextField(controller: capController, decoration: InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && plateController.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');
                final response = await http.post(
                  Uri.parse('${AppConstants.apiBaseUrl}/api/admin/buses'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'name': nameController.text,
                    'number_plate': plateController.text,
                    'capacity': int.tryParse(capController.text) ?? 40,
                    'driver_id': _drivers.isNotEmpty ? _drivers.first['id'] : 1, // Default to first driver
                  }),
                );
                if (response.statusCode == 200 || response.statusCode == 201) {
                  _fetchData();
                  Navigator.pop(ctx);
                }
              }
            }, 
            child: Text('CREATE BUS'),
          )
        ],
      ),
    );
  }
}
