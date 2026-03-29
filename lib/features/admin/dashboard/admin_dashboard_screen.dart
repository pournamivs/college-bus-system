import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/custom_gradient_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  Map<String, dynamic> _financialStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _firestoreService.getAdminFinancialStats();
    setState(() {
      _financialStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _seedBuses() async {
    setState(() => _isLoading = true);
    try {
      final db = FirebaseFirestore.instance.collection('buses');
      for (int i = 1; i <= 10; i++) {
        await db.doc(i.toString()).set({
          'name': 'Bus $i',
          'capacity': 50,
          'status': 'offline',
          'currentTripId': null,
          'driverId': null,
        }, SetOptions(merge: true));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buses 1 to 10 Seeded Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seeding Failed: $e')));
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.password),
            tooltip: 'Change Password',
            onPressed: () => context.push('/change-password'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () async {
              await _authService.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinancialOverview(),
                  const SizedBox(height: 32),
                  const Text('Vehicle Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  CustomGradientButton(
                    text: 'LIVE MONITOR ON MAP',
                    icon: Icons.map_outlined,
                    onPressed: () => context.push('/admin/tracking'),
                  ),
                  const SizedBox(height: 32),
                  const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _actionButton('Payments', Icons.payments_outlined, () => context.push('/admin/payments'))),
                      const SizedBox(width: 12),
                      Expanded(child: _actionButton('Users', Icons.people_outline, () => context.push('/admin/users'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _actionButton('Manage Buses', Icons.directions_bus, () => Navigator.pushNamed(context, '/admin/buses'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _actionButton('Emergencies', Icons.warning_amber_rounded, () => context.push('/admin/emergencies'))),
                      const SizedBox(width: 12),
                      Expanded(child: _actionButton('Drivers', Icons.drive_eta, () => context.push('/admin/drivers'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _actionButton('Maintenance', Icons.build_circle_outlined, () => context.push('/admin/maintenance'))),
                      const SizedBox(width: 12),
                      Expanded(child: _actionButton('Staff CRM', Icons.badge_outlined, () => context.push('/admin/staff'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _actionButton('Seed Buses', Icons.upload_file, _seedBuses)),
                      const SizedBox(width: 12),
                      Expanded(child: _actionButton('Reports', Icons.bar_chart, () => context.push('/admin/reports'))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Active Fleet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildFleetList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFinancialOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Financial Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('FEES RECEIVED', '₹${_financialStats['totalReceived']?.toStringAsFixed(0) ?? '0'}', AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('PENDING DUES', '₹${_financialStats['totalPending']?.toStringAsFixed(0) ?? '0'}', AppColors.error)),
          ],
        ),
        const SizedBox(height: 12),
        _statCard('TOTAL PENALTY COLLECTED', '₹${_financialStats['totalPenalty']?.toStringAsFixed(0) ?? '0'}', AppColors.warning, isWide: true),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, {bool isWide = false}) {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.streamBuses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final buses = snapshot.data!;
        if (buses.isEmpty) return const Text('No buses registered.');
        
        return Column(
          children: buses.map((bus) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => context.push('/admin/buses/${bus['id']}'),
              leading: const Icon(Icons.directions_bus, color: AppColors.primary),
              title: Text('Bus ${bus['number'] ?? 'N/A'}'),
              subtitle: Text('Status: ${bus['status']?.toUpperCase() ?? 'OFFLINE'}'),
              trailing: Icon(
                Icons.circle, 
                color: bus['status'] == 'active' ? AppColors.success : Colors.grey,
                size: 12,
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}

