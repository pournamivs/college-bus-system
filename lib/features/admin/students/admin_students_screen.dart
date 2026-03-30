import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_student_bulk_upload_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  Future<void> _editUserDialog(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['name'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    String role = user['role'] ?? 'student';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: role,
              items: ['admin', 'driver', 'student', 'staff', 'parent']
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => role = v ?? 'student',
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Username/Email'),
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
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user['id'])
                    .update({
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'role': role,
                    });
                _fetchUsers();
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
                  );
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _firestoreService.getAllUsers();
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(String id) async {
    try {
      await _firestoreService.deleteUser(id);
      _fetchUsers();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> _assignBusId(Map<String, dynamic> user) async {
    final String uid = user['id'];
    final String role = (user['role'] ?? '').toString();
    final String currentBus = (user['busId'] ?? '').toString();
    final String currentDriver = (user['driverId'] ?? '').toString();

    final busesSnapshot = await FirebaseFirestore.instance
        .collection('buses')
        .get();
    final List<String> availableBuses = busesSnapshot.docs
        .map((d) => d.id)
        .toList();
    if (availableBuses.isEmpty) availableBuses.add('1');

    String selectedBus =
        currentBus.isNotEmpty && availableBuses.contains(currentBus)
        ? currentBus
        : availableBuses.first;

    List<Map<String, dynamic>> drivers = [];
    String selectedDriver = currentDriver;
    if (role == 'student') {
      final driverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();
      drivers = driverSnapshot.docs
        .map((d) => {'id': d.id, ...d.data()})
          .toList();
      if (selectedDriver.isEmpty && drivers.isNotEmpty) {
        selectedDriver = drivers.first['id'];
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Bus & Driver'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedBus,
                  items: availableBuses
                      .map(
                        (b) =>
                            DropdownMenuItem(value: b, child: Text('Bus $b')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedBus = val);
                  },
                  decoration: const InputDecoration(labelText: 'Select Bus'),
                ),
                const SizedBox(height: 16),
                if (role == 'student')
                  DropdownButtonFormField<String>(
                    value: selectedDriver,
                    items: drivers
                        .map(
                          (d) => DropdownMenuItem(
                            value: (d['id'] ?? '').toString(),
                            child: Text(
                              (d['name'] ?? 'Unnamed Driver').toString(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedDriver = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Driver',
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (role == 'driver') {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'busId': selectedBus});
                    await FirebaseFirestore.instance
                        .collection('buses')
                        .doc(selectedBus)
                        .set({'driverId': uid}, SetOptions(merge: true));
                  } else {
                    final driverId = selectedDriver.isNotEmpty
                        ? selectedDriver
                        : '';
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'busId': selectedBus, 'driverId': driverId});
                    if (driverId.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('buses')
                          .doc(selectedBus)
                          .set({'driverId': driverId}, SetOptions(merge: true));
                    }
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _fetchUsers();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: role,
              items: ['admin', 'driver', 'student', 'staff', 'parent']
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => role = v ?? 'student',
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Username/Email'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number (e.g. 9876543210)'),
              keyboardType: TextInputType.phone,
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
                try {
                  String formattedPhone = phoneCtrl.text.trim();
                  if (!formattedPhone.startsWith('+91') && formattedPhone.length == 10) {
                    formattedPhone = '+91$formattedPhone';
                  }
                  
                  await FirebaseFirestore.instance.collection('users').add({
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': formattedPhone,
                    'role': role,
                    'busId': '',
                    'driverId': '',
                    'route': '',
                    'status': 'active',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                _fetchUsers();
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create user: $e')),
                  );
                }
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
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Bulk Upload',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminStudentBulkUploadScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final u = _users[i];
                final currentBus = (u['busId'] ?? '').toString();
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      u['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${u['email']} | Role: ${u['role']}\nBus: ${currentBus.isEmpty ? 'Unassigned' : currentBus}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _editUserDialog(u),
                          tooltip: 'Edit User',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_location_alt,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _assignBusId(u),
                          tooltip: 'Assign Bus ID',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.error,
                          ),
                          onPressed: () => _deleteUser(u['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
