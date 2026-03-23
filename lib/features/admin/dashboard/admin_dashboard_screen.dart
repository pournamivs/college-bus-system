import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/custom_gradient_button.dart';

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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
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
            child: const Text('CREATE'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard('Students', '12', Icons.school, AppColors.primary),
                      _buildStatCard('Buses', '${_buses.length}', Icons.directions_bus, AppColors.success),
                      _buildStatCard('Drivers', '${_drivers.length}', Icons.person, AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'User Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: CustomGradientButton(text: 'Add Student', onPressed: () => _showCreateUserDialog('student'))),
                    const SizedBox(width: 12),
                    Expanded(child: CustomGradientButton(text: 'Add Driver', onPressed: () => _showCreateUserDialog('driver'))),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Fleet Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_buses.isEmpty) const Center(child: Text('No buses registered')),
                ..._buses.map((bus) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_bus, color: AppColors.primary),
                    ),
                    title: Text('${bus['name']} (${bus['number_plate']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Driver: ${bus['driver_name'] ?? 'Unassigned'}'),
                    trailing: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  ),
                )),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassMorphicCard(
      width: 140,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

