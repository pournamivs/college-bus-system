import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, String> _attendanceMap = {};
  bool _isLoading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    _uid = await _authService.getUid();
    if (_uid != null && mounted) {
      _firestoreService.streamAttendanceRecords(_uid!).listen((snapshot) {
        if (!mounted) return;
        Map<DateTime, String> newMap = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = doc.id; // YYYY-MM-DD
          try {
            final date = DateTime.parse(dateStr);
            // Normalize to UTC midnight for table_calendar
            final normalizedDate = DateTime.utc(date.year, date.month, date.day);
            newMap[normalizedDate] = data['status'] ?? 'absent';
          } catch (e) {
            debugPrint('Date parse err: $e');
          }
        }
        setState(() {
          _attendanceMap = newMap;
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildCell(day);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildCell(day, isToday: true);
                    },
                  ),
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                const SizedBox(height: 32),
                _buildLegend(),
              ],
            ),
          ),
    );
  }

  Widget _buildCell(DateTime day, {bool isToday = false}) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final status = _attendanceMap[normalizedDay];
    
    Color bgColor = Colors.transparent;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    if (status == 'present') {
      bgColor = AppColors.success.withOpacity(0.2);
      textColor = AppColors.success;
    } else if (status == 'absent') {
      bgColor = AppColors.error.withOpacity(0.2);
      textColor = AppColors.error;
    }

    if (isToday && status == null) {
      bgColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: textColor, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem('Present', AppColors.success),
        _legendItem('Absent', AppColors.error),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
