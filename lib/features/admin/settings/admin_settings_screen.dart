import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  List<dynamic> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/routes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _routes = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching routes: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showAddRouteDialog() {
    final nameCtrl = TextEditingController();
    final stopsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Route Name')),
            TextField(controller: stopsCtrl, decoration: const InputDecoration(labelText: 'Stops JSON array', hintText: '[{"name":"Stop1","lat":10.0,"lng":76.0}]')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              try {
                await http.post(
                  Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/routes'),
                  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                  body: jsonEncode({
                    'name': nameCtrl.text,
                    'stops': stopsCtrl.text,
                  }),
                );
                _fetchRoutes();
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                debugPrint('Error creating route: $e');
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddRouteDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRoutes),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _routes.length,
            itemBuilder: (ctx, i) {
              final r = _routes[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tap to view stops'),
                ),
              );
            },
          ),
    );
  }
}
