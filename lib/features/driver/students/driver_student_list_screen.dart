import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class DriverStudentListScreen extends StatefulWidget {
  const DriverStudentListScreen({super.key});

  @override
  State<DriverStudentListScreen> createState() => _DriverStudentListScreenState();
}

class _DriverStudentListScreenState extends State<DriverStudentListScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _busId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusId();
  }

  Future<void> _loadBusId() async {
    final uid = await _authService.getUid();
    if (uid != null) {
      final doc = await _firestoreService.getUser(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _busId = data['busId'];
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_busId == null) {
      return const Scaffold(body: Center(child: Text('You are not assigned to any bus.')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Students - Bus $_busId')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('busId', isEqualTo: _busId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No students assigned to this bus.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final student = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(student['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(student['email'] ?? 'No email'),
                  trailing: const Icon(Icons.directions_bus, color: Colors.blueGrey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
