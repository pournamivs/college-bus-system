import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_my_bus/core/constants/api_constants.dart';
import 'package:track_my_bus/core/constants/app_colors.dart';
import 'package:track_my_bus/core/widgets/stat_card.dart';
import 'package:track_my_bus/core/widgets/section_header.dart';
import 'package:track_my_bus/core/widgets/app_button.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _buses = [];
  List<dynamic> _drivers = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final busRes = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/buses'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final driverRes = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/drivers'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (busRes.statusCode == 200 && driverRes.statusCode == 200) {
        setState(() {
          _buses = jsonDecode(busRes.body);
          _drivers = jsonDecode(driverRes.body);
        });
      }
    } catch (e) {
      debugPrint("Admin fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateUserDialog(String role) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New ${role.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              final res = await http.post(
                Uri.parse('${ApiConstants.apiBaseUrl}/api/auth/register'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                body: jsonEncode({
                  'name': nameCtrl.text,
                  'email': emailCtrl.text,
                  'password': passwordCtrl.text,
                  'role': role.toLowerCase(),
                }),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                _fetchData();
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: Text('CREATE'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchData),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatCard(label: 'Total Students', value: '12', icon: Icons.school, backgroundColor: AppColors.primary),
                      StatCard(label: 'Total Buses', value: '${_buses.length}', icon: Icons.directions_bus, backgroundColor: AppColors.success),
                      StatCard(label: 'Active Drivers', value: '${_drivers.length}', icon: Icons.person, backgroundColor: AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'User Management'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppButton(text: 'Add Student', onPressed: () => _showCreateUserDialog('student'))),
                    const SizedBox(width: 12),
                    Expanded(child: AppButton(text: 'Add Driver', onPressed: () => _showCreateUserDialog('driver'))),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Fleet Overview'),
                const SizedBox(height: 12),
                if (_buses.isEmpty) Center(child: Text('No buses registered')),
                ..._buses.map((bus) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.directions_bus, color: AppColors.primary),
                    title: Text('${bus['name']} (${bus['number_plate']})'),
                    subtitle: Text('Driver: ${bus['driver_name'] ?? 'Unassigned'}'),
                    trailing: Icon(Icons.edit, size: 18),
                  ),
                )),
              ],
            ),
          ),
    );
  }
}

