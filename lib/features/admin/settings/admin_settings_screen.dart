import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import 'dart:convert';

class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      _routes = await _firestoreService.getAllRoutes();
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
              try {
                final List<dynamic> stopsJson = jsonDecode(stopsCtrl.text);
                final List<Map<String, dynamic>> stops = stopsJson.cast<Map<String, dynamic>>();
                
                await _firestoreService.addRoute(nameCtrl.text, stops);
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
