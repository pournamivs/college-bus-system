import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentListScreen extends StatefulWidget {
  const AdminPaymentListScreen({super.key});

  @override
  State<AdminPaymentListScreen> createState() => _AdminPaymentListScreenState();
}

class _AdminPaymentListScreenState extends State<AdminPaymentListScreen> {
//  final FirestoreService _firestoreService = FirestoreService();
  String _filter = 'All'; // All, Paid, Pending, Overdue
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Payments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Name or Email',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: ['All', 'Paid', 'Pending', 'Overdue'].map((f) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (selected) => setState(() => _filter = f),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _filter == f ? Colors.white : Colors.black),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final students = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);
            
            if (!matchesSearch) return false;

            final double pending = (data['pending_amount'] ?? 0.0).toDouble();
            final Timestamp? dueDate = data['dueDate'];
            bool isOverdue = false;
            if (dueDate != null && pending > 0) {
              isOverdue = DateTime.now().isAfter(dueDate.toDate());
            }

            if (_filter == 'Paid') return pending <= 0;
            if (_filter == 'Pending') return pending > 0 && !isOverdue;
            if (_filter == 'Overdue') return isOverdue;
            return true;
          }).toList();

          if (students.isEmpty) return const Center(child: Text('No students found matching filters.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>;
              final double pending = (data['pending_amount'] ?? 0.0).toDouble();
              final Timestamp? dueDate = data['dueDate'];
              bool isOverdue = false;
              if (dueDate != null && pending > 0) {
                isOverdue = DateTime.now().isAfter(dueDate.toDate());
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOverdue ? AppColors.error : (pending <= 0 ? AppColors.success : AppColors.warning),
                    child: Icon(isOverdue ? Icons.priority_high : (pending <= 0 ? Icons.check : Icons.hourglass_empty), color: Colors.white),
                  ),
                  title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Pending: ₹$pending\nDue: ${dueDate != null ? dueDate.toDate().toString().split(' ')[0] : 'N/A'}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isOverdue ? 'OVERDUE' : (pending <= 0 ? 'PAID' : 'PENDING'),
                        style: TextStyle(
                          color: isOverdue ? AppColors.error : (pending <= 0 ? AppColors.success : AppColors.warning),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    // Navigate to student details or specific payment history
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
