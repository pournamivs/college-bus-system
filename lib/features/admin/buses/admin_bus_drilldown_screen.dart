import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_service.dart';

class AdminBusDrilldownScreen extends StatefulWidget {
  final String busId;
  const AdminBusDrilldownScreen({super.key, required this.busId});

  @override
  State<AdminBusDrilldownScreen> createState() => _AdminBusDrilldownScreenState();
}

class _AdminBusDrilldownScreenState extends State<AdminBusDrilldownScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _driverData;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _complaints = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBusMetrics();
  }

  Future<void> _fetchBusMetrics() async {
    try {
      // 1. Bus Data
      final busDoc = await _db.collection('buses').doc(widget.busId).get();
      if (busDoc.exists) {
        _busData = busDoc.data();
      }

      // 2. Driver Data via assigned driverId or bus driverId
      String? driverId = _busData?['driverId']?.toString();
      if (driverId != null && driverId.isNotEmpty) {
        final driverDoc = await _db.collection('users').doc(driverId).get();
        if (driverDoc.exists) _driverData = driverDoc.data();
      } else {
        final driverQuery = await _db.collection('users').where('role', isEqualTo: 'driver').where('busId', isEqualTo: widget.busId).limit(1).get();
        if (driverQuery.docs.isNotEmpty) {
          _driverData = driverQuery.docs.first.data();
          driverId = driverQuery.docs.first.id;
        }
      }

      // Update bus driverId if we found one
      if (driverId != null && driverId.isNotEmpty) {
        await _db.collection('buses').doc(widget.busId).set({'driverId': driverId}, SetOptions(merge: true));
      }

      // 3. Students assigned to this bus
      final studentQuery = await _db.collection('users').where('role', isEqualTo: 'student').where('busId', isEqualTo: widget.busId).get();
      _students = studentQuery.docs.map((e) => {'id': e.id, ...e.data()}).toList();

      // 4. Complaints for this bus route (filtering on client side since complaints schema only has user id, 
      // but let's query actively where role is driver and we match the driverId if it existed.
      // Alternatively, just grab all maintenance where busId matches)
      final maintenanceQuery = await _db.collection('maintenance').where('busId', isEqualTo: widget.busId).get();
      _complaints = maintenanceQuery.docs.map((e) => e.data()).toList();

    } catch (e) {
      debugPrint('Drilldown Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Bus ${widget.busId} Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    int pendingStudents = _students.where((s) => (s['pending_amount'] ?? 0) > 0).length;
    double totalPending = _students.fold(0, (sum, s) => sum + ((s['pending_amount'] ?? 0) as num).toDouble());
    double totalFines = _students.fold(0, (sum, s) => sum + ((s['penalty'] ?? 0) as num).toDouble());

    return Scaffold(
      appBar: AppBar(
        title: Text('${_busData?['name'] ?? widget.busId} Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Driver Details'),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(_driverData?['name'] ?? 'Unassigned'),
                subtitle: Text('Status: ${_driverData?['salary_status'] ?? 'Unknown'}'),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Student Attendance & Fees'),
            Row(
              children: [
                Expanded(child: _statCard('Total Students', _students.length.toString(), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Pending Fees', pendingStudents.toString(), AppColors.warning)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _statCard('Total Dues', '₹${totalPending.toStringAsFixed(0)}', AppColors.error)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Total Fines', '₹${totalFines.toStringAsFixed(0)}', AppColors.error)),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Active Route Complaints'),
            if (_complaints.isEmpty)
              const Text('No complaints registered for this vehicle.', style: TextStyle(color: Colors.grey))
            else
              ..._complaints.map((c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: AppColors.warning),
                  title: Text(c['status']?.toString().toUpperCase() ?? 'REPORTED'),
                  subtitle: Text(c['description'] ?? 'No Description'),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
