import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  
  String _currentFilter = 'All'; // All, Paid, Pending, Overdue

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
          
      List<Map<String, dynamic>> students = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final double pending = (data['pending_amount'] ?? 0.0).toDouble();
        final Timestamp? dueDateTimestamp = data['dueDate'];
        
        bool isOverdue = false;
        double penalty = 0.0;
        
        if (dueDateTimestamp != null && pending > 0) {
          final dueDate = dueDateTimestamp.toDate();
          final now = DateTime.now();
          if (now.isAfter(dueDate)) {
            final daysLate = now.difference(dueDate).inDays;
            if (daysLate > 0) {
              penalty = daysLate * 50.0;
              isOverdue = true;
            }
          }
        }
        
        String status = 'Paid';
        if (pending > 0) status = 'Pending';
        if (isOverdue) status = 'Overdue';
        
        students.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? 'Unknown',
          'busId': data['busId'] ?? 'N/A',
          'total_fee': (data['total_fee'] ?? 0.0).toDouble(),
          'paid_amount': (data['paid_amount'] ?? 0.0).toDouble(),
          'pending_amount': pending,
          'penalty': penalty,
          'status': status,
        });
      }
      
      if (mounted) {
        setState(() {
          _allStudents = students;
          _applyFilter(_currentFilter);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching payment monitor data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      if (filter == 'All') {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((s) => s['status'] == filter).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Monitoring'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: _filteredStudents.isEmpty
                    ? Center(child: Text('No students found in "$_currentFilter" filter.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (ctx, i) {
                          final student = _filteredStudents[i];
                          final status = student['status'];
                          
                          Color statusColor = AppColors.success;
                          if (status == 'Pending') statusColor = AppColors.warning;
                          if (status == 'Overdue') statusColor = AppColors.error;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.2),
                                child: Icon(
                                  status == 'Paid' ? Icons.check_circle : (status == 'Overdue' ? Icons.warning : Icons.pending_actions),
                                  color: statusColor,
                                ),
                              ),
                              title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black87, height: 1.5),
                                  children: [
                                    TextSpan(text: 'Bus: ${student['busId']}\n'),
                                    TextSpan(text: 'Paid: ₹${student['paid_amount']}  |  Pending: ₹${student['pending_amount']}'),
                                    if (student['penalty'] > 0)
                                      TextSpan(
                                        text: '\nPenalty: ₹${student['penalty']} (Late)',
                                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Chip(
                                label: Text(status),
                                backgroundColor: statusColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                side: BorderSide.none,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['All', 'Paid', 'Pending', 'Overdue'].map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              label: Text(filter, style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              selected: isSelected,
              onSelected: (_) => _applyFilter(filter),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade200,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
