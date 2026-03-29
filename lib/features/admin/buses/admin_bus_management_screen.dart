import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

class AdminBusManagementScreen extends StatefulWidget {
  const AdminBusManagementScreen({super.key});

  @override
  State<AdminBusManagementScreen> createState() =>
      _AdminBusManagementScreenState();
}

class _AdminBusManagementScreenState extends State<AdminBusManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _buses = [];

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    setState(() => _isLoading = true);
    final snapshot = await _db.collection('buses').get();
    _buses = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    setState(() => _isLoading = false);
  }

  Future<void> _showBusDialog({Map<String, dynamic>? bus}) async {
    final idCtrl = TextEditingController(text: bus?['id'] ?? '');
    String driverId = bus?['driverId'] ?? '';
    String status = bus?['status'] ?? 'active';
    List<Map<String, dynamic>> drivers = [];
    final driverSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    drivers = driverSnap.docs
        .map((d) => {'id': d.id.toString(), ...d.data()})
        .toList();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bus == null ? 'Add New Bus' : 'Edit Bus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(labelText: 'Bus ID'),
              enabled: bus == null, // Only allow editing bus_id on add
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: driverId.isNotEmpty ? driverId : null,
              items: drivers
                  .map(
                    (d) => DropdownMenuItem<String>(
                      value: d['id'] as String,
                      child: Text((d['name'] ?? d['id']).toString()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => driverId = val ?? '',
              decoration: const InputDecoration(
                labelText: 'Assign Driver (optional)',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              items: ['active', 'inactive']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => status = val ?? 'active',
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final busId = idCtrl.text.trim();
              if (busId.isEmpty) return;
              final data = {'driverId': driverId, 'status': status};
              if (bus == null) {
                await _db.collection('buses').doc(busId).set(data);
              } else {
                await _db.collection('buses').doc(busId).update(data);
              }
              // Update driver assignment in users
              if (driverId.isNotEmpty) {
                await _db.collection('users').doc(driverId).update({
                  'busId': busId,
                });
              }
              if (mounted) {
                Navigator.pop(ctx);
                _fetchBuses();
              }
            },
            child: Text(bus == null ? 'ADD' : 'SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBus(Map<String, dynamic> bus) async {
    final busId = bus['id'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Are you sure you want to delete bus $busId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // Remove bus reference from users
    final users = await _db
        .collection('users')
        .where('busId', isEqualTo: busId)
        .get();
    for (var user in users.docs) {
      await user.reference.update({'busId': ''});
    }
    await _db.collection('buses').doc(busId).delete();
    if (mounted) _fetchBuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Management'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buses.isEmpty
          ? const Center(child: Text('No buses found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _buses.length,
              itemBuilder: (ctx, i) {
                final bus = _buses[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_bus,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      bus['id'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Driver: ${bus['driverId'] ?? 'Unassigned'}\nStatus: ${(bus['status'] ?? 'inactive').toString().toUpperCase()}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showBusDialog(bus: bus),
                          tooltip: 'Edit Bus',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBus(bus),
                          tooltip: 'Delete Bus',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBusDialog(),
        child: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        tooltip: 'Add New Bus',
      ),
    );
  }
}
