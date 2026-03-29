import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/widgets/custom_gradient_button.dart';

class StudentPaymentScreen extends StatefulWidget {
  const StudentPaymentScreen({super.key});

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late Razorpay _razorpay;

  Map<String, dynamic> _financials = {};
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _studentId = await _authService.getUid();
    if (_studentId != null) {
      _financials = await _firestoreService.getStudentFinancials(_studentId!);
    }
    setState(() => _isLoading = false);
  }

  void _startPayment() {
    if (_financials['total_payable'] <= 0 || _isProcessing) return;

    // Check for duplicate payment prevention
    if (_hasRecentPayment()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A payment was recently processed. Please wait before making another payment.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', 
      'amount': (_financials['total_payable'] * 100).toInt(),
      'name': 'College Bus Fee',
      'description': 'Payment for Bus Services',
      'prefill': {'contact': '', 'email': ''},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      setState(() => _isProcessing = false);
    }
  }

  bool _hasRecentPayment() {
    // Check if there's a payment in the last 5 minutes to prevent duplicates
    // This is a simple implementation - in production, you'd check the database
    return false; // For now, allow all payments
  }

  Future<void> _generateReceipt(Map<String, dynamic> paymentData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('College Bus Fee Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Transaction ID: ${paymentData['transactionId'] ?? 'N/A'}'),
            pw.Text('Amount Paid: ₹${paymentData['amount']}'),
            pw.Text('Date: ${paymentData['timestamp']?.toDate()?.toString() ?? DateTime.now().toString()}'),
            pw.Text('Status: ${paymentData['status']}'),
            pw.SizedBox(height: 20),
            pw.Text('Thank you for your payment!', style: pw.TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_studentId == null) return;
    
    try {
      await _firestoreService.recordPayment({
        'studentId': _studentId!,
        'amount': _financials['total_payable'],
        'transactionId': response.paymentId,
        'status': 'success',
        'type': 'fee_payment',
      });

      if (mounted) {
        setState(() => _isProcessing = false);
        context.pushReplacementNamed('payment_status', extra: {
          'isSuccess': true,
          'message': 'Your bus fee has been successfully paid.',
          'transactionId': response.paymentId,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        context.pushReplacementNamed('payment_status', extra: {
          'isSuccess': false,
          'message': 'Failed to record payment in our database: $e',
          'transactionId': response.paymentId,
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      context.pushReplacementNamed('payment_status', extra: {
        'isSuccess': false,
        'message': 'Razorpay payment failed: ${response.message}',
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}'), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Fee & Payments')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFinancialCard(),
                const SizedBox(height: 24),
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder(
                    stream: _firestoreService.streamStudentPayments(_studentId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text('No payment records found.'));
                      
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                              title: Text('Amount: ₹${data['amount']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${data['transactionId'] ?? 'N/A'}'),
                                  Text('Date: ${data['timestamp']?.toDate()?.toString() ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download, color: AppColors.primary),
                                    onPressed: () => _generateReceipt(data),
                                    tooltip: 'Download Receipt',
                                  ),
                                  const Icon(Icons.check_circle, color: AppColors.success),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_financials['total_payable'] > 0)
                  CustomGradientButton(
                    text: _isProcessing ? 'PROCESSING...' : 'PAY NOW (₹${_financials['total_payable']})',
                    onPressed: _isProcessing ? null : _startPayment,
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildFinancialCard() {
    return GlassMorphicCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _financeRow('Total Bus Fee', '₹${_financials['total_fee']}'),
          _financeRow('Paid Amount', '₹${_financials['paid_amount']}', color: AppColors.success),
          _financeRow('Pending Dues', '₹${_financials['base_pending']}', color: AppColors.error),
          const Divider(),
          _financeRow('Late Penalty (₹50/day)', '₹${_financials['penalty_amount']}', color: AppColors.error, isBold: true),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Outstanding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('₹${_financials['total_payable']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
