import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';

class AdminEmergenciesScreen extends StatefulWidget {
  const AdminEmergenciesScreen({super.key});

  @override
  State<AdminEmergenciesScreen> createState() => _AdminEmergenciesScreenState();
}

class _AdminEmergenciesScreenState extends State<AdminEmergenciesScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/emergency/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _alerts = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Control'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAlerts),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _alerts.length,
            itemBuilder: (ctx, i) {
              final a = _alerts[i];
              return Card(
                color: AppColors.error.withOpacity(0.1),
                borderOnForeground: true,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: AppColors.error),
                  title: Text('SOS from Role: ${a['user_role']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${a['status']} | Type: ${a['alert_type']}\nLocation: ${a['latitude']}, ${a['longitude']}'),
                  trailing: ElevatedButton(
                    onPressed: () {}, // Backend resolve logic 
                    child: const Text('RESOLVE'),
                  ),
                ),
              );
            },
          ),
    );
  }
}
