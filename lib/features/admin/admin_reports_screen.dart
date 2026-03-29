import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/constants/app_colors.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  Map<String, dynamic> _reportsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    try {
      // Load payments data
      final paymentsQuery = await FirebaseFirestore.instance.collection('payments').get();
      double totalRevenue = 0;
      int totalPayments = paymentsQuery.docs.length;
      for (var doc in paymentsQuery.docs) {
        final data = doc.data();
        totalRevenue += (data['amount'] ?? 0).toDouble();
      }

      // Load attendance data
      final attendanceQuery = await FirebaseFirestore.instance.collection('attendance').get();
      int totalAttendanceRecords = attendanceQuery.docs.length;
      int presentCount = attendanceQuery.docs.where((doc) => doc.data()['present'] == true).length;

      // Load SOS data
      final sosQuery = await FirebaseFirestore.instance.collection('sos').get();
      int totalSOS = sosQuery.docs.length;

      // Load users data
      final usersQuery = await FirebaseFirestore.instance.collection('users').get();
      int totalStudents = usersQuery.docs.where((doc) => doc.data()['role'] == 'student').length;
      int totalDrivers = usersQuery.docs.where((doc) => doc.data()['role'] == 'driver').length;

      // Load buses data
      final busesQuery = await FirebaseFirestore.instance.collection('buses').get();
      int totalBuses = busesQuery.docs.length;
      int activeBuses = busesQuery.docs.where((doc) => doc.data()['status'] == 'active').length;

      setState(() {
        _reportsData = {
          'payments': {
            'totalRevenue': totalRevenue,
            'totalPayments': totalPayments,
          },
          'attendance': {
            'totalRecords': totalAttendanceRecords,
            'presentCount': presentCount,
            'absentCount': totalAttendanceRecords - presentCount,
          },
          'sos': {
            'totalSOS': totalSOS,
          },
          'users': {
            'totalStudents': totalStudents,
            'totalDrivers': totalDrivers,
          },
          'buses': {
            'totalBuses': totalBuses,
            'activeBuses': activeBuses,
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = [
        ['Report Type', 'Metric', 'Value'],
        ['Payments', 'Total Revenue', '₹${_reportsData['payments']?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'],
        ['Payments', 'Total Payments', '${_reportsData['payments']?['totalPayments'] ?? 0}'],
        ['Attendance', 'Total Records', '${_reportsData['attendance']?['totalRecords'] ?? 0}'],
        ['Attendance', 'Present Days', '${_reportsData['attendance']?['presentCount'] ?? 0}'],
        ['Attendance', 'Absent Days', '${_reportsData['attendance']?['absentCount'] ?? 0}'],
        ['Attendance', 'Attendance Rate', '${_reportsData['attendance']?['totalRecords'] != null && _reportsData['attendance']['totalRecords'] > 0 ? ((_reportsData['attendance']['presentCount'] / _reportsData['attendance']['totalRecords']) * 100).toStringAsFixed(1) : 0}%'],
        ['Emergency', 'Total SOS Alerts', '${_reportsData['sos']?['totalSOS'] ?? 0}'],
        ['Users', 'Total Students', '${_reportsData['users']?['totalStudents'] ?? 0}'],
        ['Users', 'Total Drivers', '${_reportsData['users']?['totalDrivers'] ?? 0}'],
        ['Fleet', 'Total Buses', '${_reportsData['buses']?['totalBuses'] ?? 0}'],
        ['Fleet', 'Active Buses', '${_reportsData['buses']?['activeBuses'] ?? 0}'],
        ['Fleet', 'Inactive Buses', '${(_reportsData['buses']?['totalBuses'] ?? 0) - (_reportsData['buses']?['activeBuses'] ?? 0)}'],
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/bus_system_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(file.path)], text: 'Bus System Report - CSV Export');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV report exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Bus System Reports Dashboard',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: ${DateTime.now().toString()}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                pw.SizedBox(height: 30),

                // Payments Section
                pw.Text('Payments & Revenue',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Total Revenue: ₹${_reportsData['payments']?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
                pw.Text('Total Payments: ${_reportsData['payments']?['totalPayments'] ?? 0}'),
                pw.SizedBox(height: 20),

                // Attendance Section
                pw.Text('Student Attendance',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Total Records: ${_reportsData['attendance']?['totalRecords'] ?? 0}'),
                pw.Text('Present Days: ${_reportsData['attendance']?['presentCount'] ?? 0}'),
                pw.Text('Absent Days: ${_reportsData['attendance']?['absentCount'] ?? 0}'),
                pw.Text('Attendance Rate: ${_reportsData['attendance']?['totalRecords'] != null && _reportsData['attendance']['totalRecords'] > 0 ? ((_reportsData['attendance']['presentCount'] / _reportsData['attendance']['totalRecords']) * 100).toStringAsFixed(1) : 0}%'),
                pw.SizedBox(height: 20),

                // Emergency Section
                pw.Text('Emergency Reports',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Total SOS Alerts: ${_reportsData['sos']?['totalSOS'] ?? 0}'),
                pw.SizedBox(height: 20),

                // Users Section
                pw.Text('User Management',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Total Students: ${_reportsData['users']?['totalStudents'] ?? 0}'),
                pw.Text('Total Drivers: ${_reportsData['users']?['totalDrivers'] ?? 0}'),
                pw.SizedBox(height: 20),

                // Fleet Section
                pw.Text('Fleet Management',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Total Buses: ${_reportsData['buses']?['totalBuses'] ?? 0}'),
                pw.Text('Active Buses: ${_reportsData['buses']?['activeBuses'] ?? 0}'),
                pw.Text('Inactive Buses: ${(_reportsData['buses']?['totalBuses'] ?? 0) - (_reportsData['buses']?['activeBuses'] ?? 0)}'),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/bus_system_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Bus System Report - PDF Export');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reports Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export as CSV',
            onPressed: _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export as PDF',
            onPressed: _exportToPDF,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Payments Section
                  _buildReportSection(
                    'Payments & Revenue',
                    Icons.receipt_long,
                    [
                      _buildReportItem('Total Revenue', '₹${_reportsData['payments']?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
                      _buildReportItem('Total Payments', '${_reportsData['payments']?['totalPayments'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Attendance Section
                  _buildReportSection(
                    'Student Attendance',
                    Icons.calendar_today,
                    [
                      _buildReportItem('Total Records', '${_reportsData['attendance']?['totalRecords'] ?? 0}'),
                      _buildReportItem('Present Days', '${_reportsData['attendance']?['presentCount'] ?? 0}'),
                      _buildReportItem('Absent Days', '${_reportsData['attendance']?['absentCount'] ?? 0}'),
                      _buildReportItem('Attendance Rate', '${_reportsData['attendance']?['totalRecords'] != null && _reportsData['attendance']['totalRecords'] > 0 ? ((_reportsData['attendance']['presentCount'] / _reportsData['attendance']['totalRecords']) * 100).toStringAsFixed(1) : 0}%'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SOS Section
                  _buildReportSection(
                    'Emergency Reports',
                    Icons.warning,
                    [
                      _buildReportItem('Total SOS Alerts', '${_reportsData['sos']?['totalSOS'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Users Section
                  _buildReportSection(
                    'User Management',
                    Icons.people,
                    [
                      _buildReportItem('Total Students', '${_reportsData['users']?['totalStudents'] ?? 0}'),
                      _buildReportItem('Total Drivers', '${_reportsData['users']?['totalDrivers'] ?? 0}'),
                      _buildReportItem('Total Staff', '0'), // TODO: Add staff count
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buses Section
                  _buildReportSection(
                    'Fleet Management',
                    Icons.directions_bus,
                    [
                      _buildReportItem('Total Buses', '${_reportsData['buses']?['totalBuses'] ?? 0}'),
                      _buildReportItem('Active Buses', '${_reportsData['buses']?['activeBuses'] ?? 0}'),
                      _buildReportItem('Inactive Buses', '${(_reportsData['buses']?['totalBuses'] ?? 0) - (_reportsData['buses']?['activeBuses'] ?? 0)}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Activities Section
                  _buildReportSection(
                    'Recent Activities',
                    Icons.timeline,
                    [
                      _buildReportItem('Bus Trips Today', '0'), // TODO: Calculate from bus_locations
                      _buildReportItem('Location Updates', '0'), // TODO: Calculate from bus_locations
                      _buildReportItem('New Registrations', '0'), // TODO: Calculate from users with recent timestamps
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReportSection(String title, IconData icon, List<Widget> items) {
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
          ...items,
        ],
      ),
    );
  }

  Widget _buildReportItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}