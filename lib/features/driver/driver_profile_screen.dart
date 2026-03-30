import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/constants/app_colors.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _busData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _driverData = userData;
          });

          // Load bus data if assigned
          final busId = userData['busId']?.toString();
          if (busId != null) {
            final busDoc = await FirebaseFirestore.instance.collection('buses').doc(busId).get();
            if (busDoc.exists) {
              setState(() {
                _busData = busDoc.data();
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading driver profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header
                  GlassMorphicCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            _driverData?['name']?.toString().substring(0, 1).toUpperCase() ?? 'D',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverData?['name'] ?? 'Driver Name',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _driverData?['email'] ?? 'driver@email.com',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Bus Driver',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionCard(
                    'Personal Information',
                    Icons.person,
                    [
                      _buildInfoRow('Full Name', _driverData?['name'] ?? 'Not provided'),
                      _buildInfoRow('Email', _driverData?['email'] ?? 'Not provided'),
                      _buildInfoRow('Phone', _driverData?['phone'] ?? 'Not provided'),
                      _buildInfoRow('License Number', _driverData?['licenseNumber'] ?? 'Not provided'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transport Information
                  _buildSectionCard(
                    'Transport Information',
                    Icons.directions_bus,
                    [
                      _buildInfoRow('Bus Assigned', _busData?['name'] ?? 'Not assigned'),
                      _buildInfoRow('Bus Number', _busData?['number'] ?? 'Not assigned'),
                      _buildInfoRow('Route', _busData?['route'] ?? 'Not assigned'),
                      _buildInfoRow('Capacity', _busData?['capacity']?.toString() ?? 'Not specified'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bank Information
                  _buildSectionCard(
                    'Bank Information',
                    Icons.account_balance,
                    [
                      _buildInfoRow('Bank Name', _driverData?['bankName'] ?? 'Not provided'),
                      _buildInfoRow('Account Number', _driverData?['accountNumber'] ?? 'Not provided'),
                      _buildInfoRow('IFSC Code', _driverData?['ifscCode'] ?? 'Not provided'),
                      _buildInfoRow('Account Holder', _driverData?['accountHolderName'] ?? 'Not provided'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Attendance Information
                  _buildSectionCard(
                    'Attendance Summary',
                    Icons.calendar_today,
                    [
                      _buildInfoRow('Total Days', '30'), // This would be calculated from attendance records
                      _buildInfoRow('Present Days', '28'), // This would be calculated from attendance records
                      _buildInfoRow('Absent Days', '2'), // This would be calculated from attendance records
                      _buildInfoRow('Attendance %', '93.3%'), // This would be calculated from attendance records
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}