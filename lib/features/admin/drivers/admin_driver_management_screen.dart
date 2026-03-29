import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';

class AdminDriverManagementScreen extends StatefulWidget {
  const AdminDriverManagementScreen({super.key});

  @override
  State<AdminDriverManagementScreen> createState() => _AdminDriverManagementScreenState();
}

class _AdminDriverManagementScreenState extends State<AdminDriverManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _toggleSalaryStatus(String uid, bool currentCredited) async {
    final newCredited = !currentCredited;
    try {
      await _db.collection('users').doc(uid).update({
        'salary_credited': newCredited,
        'salary_status': newCredited ? 'Paid' : 'Not Paid', // Backwards compatibility for list
        'last_credited_date': newCredited ? FieldValue.serverTimestamp() : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newCredited ? 'Salary Credited!' : 'Salary Revoked!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _assignBusId(String uid, String currentBus) async {
    final busesSnapshot = await FirebaseFirestore.instance.collection('buses').get();
    final List<String> availableBuses = busesSnapshot.docs.map((d) => d.id).toList();
    if (availableBuses.isEmpty) availableBuses.add('1');

    String selectedBus = currentBus.isNotEmpty && availableBuses.contains(currentBus)
        ? currentBus
        : availableBuses.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Bus ID'),
            content: DropdownButtonFormField<String>(
              value: selectedBus,
              items: availableBuses
                  .map((b) => DropdownMenuItem(value: b, child: Text('Bus $b')))
                  .toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => selectedBus = val);
              },
              decoration: const InputDecoration(labelText: 'Select Bus'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await _firestoreService.assignBusToDriver(uid, selectedBus);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Salary Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').where('role', isEqualTo: 'driver').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No drivers found.'));
          }

          final drivers = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index].data() as Map<String, dynamic>;
              final uid = drivers[index].id;
              final status = driver['salary_status'] ?? 'Not Paid';
              final isPaid = driver['salary_credited'] ?? (status == 'Paid');
              final amount = driver['salary_amount'] ?? 15000.0;
              final currentBus = (driver['busId'] ?? '').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.edit_location_alt, color: AppColors.primary),
                    onPressed: () => _assignBusId(uid, currentBus),
                    tooltip: 'Assign Bus ID',
                  ),
                  title: Text(driver['name'] ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Bus: ${currentBus.isEmpty ? 'Unassigned' : currentBus}\nSalary: ₹$amount'),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                    ),
                    child: Switch(
                      value: isPaid,
                      activeColor: AppColors.success,
                      onChanged: (val) => _toggleSalaryStatus(uid, isPaid),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
