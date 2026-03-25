import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  double _totalCollected = 0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/payments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        double total = 0;
        for (var p in data) {
          total += (p['amount'] ?? 0);
        }
        if (mounted) {
          setState(() {
            _payments = data;
            _totalCollected = total;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddFineDialog() {
    final studentIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue Fine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: studentIdCtrl, decoration: const InputDecoration(labelText: 'Student ID'), keyboardType: TextInputType.number),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (\$)'), keyboardType: TextInputType.number),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              try {
                await http.post(
                  Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/fines'),
                  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                  body: jsonEncode({
                    'student_id': int.tryParse(studentIdCtrl.text) ?? 0,
                    'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                    'reason': reasonCtrl.text,
                  }),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fine issued successfully'), backgroundColor: AppColors.success));
                }
              } catch (e) {
                debugPrint('Error issuing fine: $e');
              }
            },
            child: const Text('ISSUE FINE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.receipt), onPressed: _showAddFineDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPayments),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Collected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${_totalCollected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _payments.length,
                  itemBuilder: (ctx, i) {
                    final p = _payments[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.monetization_on, color: AppColors.success),
                        title: Text('Student ID: ${p['student_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${p['status']} | Date: ${p['payment_date']}'),
                        trailing: Text('+\$${p['amount']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
