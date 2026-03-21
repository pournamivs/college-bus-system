import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';

class StudentFeesScreen extends StatelessWidget {
  const StudentFeesScreen({super.key});

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Semester 5 Fee'),
                  Text('₹12,500', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹12,500', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Confirm Payment via UPI',
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('upi://pay?pa=college@upi&pn=SNGCE&am=12500&cu=INR');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    // Ignore error on emulator without UPI app
                  }
                  if (context.mounted) _showSuccessDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 60),
              const SizedBox(height: 16),
              const Text('Payment Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your transaction ID is TXN987654321', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              AppButton(
                text: 'Print Receipt',
                onPressed: () {
                  Navigator.pop(context);
                  // Generate PDF logic would go here
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Fees & Payments', style: TextStyle(color: AppColors.textPrimary)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Paid History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pending Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Semester ${5 + index} Fee', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const StatusChip(label: 'Overdue'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Amount: ₹12,500', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Due Date: 15 Oct 2026', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showPaymentSheet(context),
                            child: const Text('Pay Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Paid History Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.receipt, color: AppColors.primary),
                    ),
                    title: const Text('Semester 4 Fee'),
                    subtitle: const Text('Paid on 10 Apr 2026\nTXN123456789'),
                    isThreeLine: true,
                    trailing: const Text('₹12,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onTap: () {
                      // View/Download receipt
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

