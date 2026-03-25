import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';

class StudentPaymentScreen extends StatefulWidget {
  const StudentPaymentScreen({super.key});

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  List<dynamic> _fines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFines();
  }

  Future<void> _fetchFines() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/student/fines'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => _fines = jsonDecode(res.body));
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  Future<void> _payFine(dynamic fine) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/student/pay'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'fine_id': fine['id'],
          'amount': fine['amount'],
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final paymentReceipt = jsonDecode(res.body);
        _fetchFines();
        if (mounted) {
          _showReceipt(paymentReceipt, fine['reason']);
        }
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  void _showReceipt(dynamic payment, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 60),
            const SizedBox(height: 10),
            Text('Receipt ID: ${payment['id']}'),
            Text('Amount: \$${payment['amount']}'),
            Text('Reason: $reason'),
            Text('Date: ${payment['payment_date'] ?? DateTime.now().toString()}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Fines & Dues')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _fines.length,
            itemBuilder: (ctx, i) {
              final f = _fines[i];
              final isPaid = f['status'] == 'paid';
              return Card(
                color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(isPaid ? Icons.check_circle : Icons.warning, color: isPaid ? AppColors.success : AppColors.error),
                  title: Text(f['reason'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Amount: \$${f['amount']} | Status: ${f['status'].toUpperCase()}'),
                  trailing: isPaid 
                    ? const Text('PAID', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))
                    : ElevatedButton(
                        onPressed: () => _payFine(f),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('PAY NOW'),
                      ),
                ),
              );
            },
          ),
    );
  }
}
