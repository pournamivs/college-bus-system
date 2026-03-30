import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSalaryScreen extends StatefulWidget {
  const DriverSalaryScreen({super.key});

  @override
  State<DriverSalaryScreen> createState() => _DriverSalaryScreenState();
}

class _DriverSalaryScreenState extends State<DriverSalaryScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalaryInfo();
  }

  Future<void> _loadSalaryInfo() async {
    final uid = await _authService.getUid();
    if (uid != null) {
      final doc = await _firestoreService.getUser(uid);
      if (doc.exists) {
        setState(() {
          _driverData = doc.data() as Map<String, dynamic>;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final amount = _driverData?['salary_amount'] ?? 0.0;
    final status = _driverData?['salary_status'] ?? 'Not Paid';
    final Timestamp? lastCredited = _driverData?['last_credited_date'];
    
    final dateStr = lastCredited != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(lastCredited.toDate()) 
        : 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('My Salary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GlassMorphicCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Current Month Salary', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('₹$amount', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: status == 'Paid' ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toString().toUpperCase(), 
                          style: TextStyle(
                            color: status == 'Paid' ? AppColors.success : AppColors.error, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Last Credited', style: TextStyle(fontSize: 16)),
                      Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
