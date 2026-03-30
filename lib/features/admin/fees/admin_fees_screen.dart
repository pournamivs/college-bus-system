import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';

class AdminEmergenciesScreen extends StatefulWidget {
  const AdminEmergenciesScreen({super.key});

  @override
  State<AdminEmergenciesScreen> createState() => _AdminEmergenciesScreenState();
}

class _AdminEmergenciesScreenState extends State<AdminEmergenciesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    try {
      _alerts = await _firestoreService.getAllAlerts();
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
                color: AppColors.error.withValues(alpha: 0.1),
                borderOnForeground: true,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: AppColors.error),
                  title: Text('SOS from User ID: ${a['userId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${a['status']} | Type: ${a['type']}\nLocation: ${a['latitude']}, ${a['longitude']}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _firestoreService.resolveAlert(a['id']);
                        _fetchAlerts();
                      } catch (e) {
                        debugPrint('Error resolving alert: $e');
                      }
                    },
                    child: const Text('RESOLVE'),
                  ),
                ),
              );
            },
          ),
    );
  }
}
