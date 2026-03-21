import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stat_card.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dummy attendance data
  final Map<DateTime, String> _attendanceMap = {
    DateTime.now().subtract(const Duration(days: 1)): 'Present',
    DateTime.now().subtract(const Duration(days: 2)): 'Absent',
    DateTime.now().subtract(const Duration(days: 3)): 'Late',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(child: StatCard(label: 'Present Days', value: '45', icon: Icons.check_circle, backgroundColor: AppColors.success)),
                Expanded(child: StatCard(label: 'Absent Days', value: '5', icon: Icons.cancel, backgroundColor: AppColors.error)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overall Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('90%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.9,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Calendar
            const Text('Monthly View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    // Match dummy data ignoring time
                    final matchingKey = _attendanceMap.keys.firstWhere(
                      (k) => isSameDay(k, date),
                      orElse: () => DateTime(1970),
                    );
                    
                    if (matchingKey.year != 1970) {
                      final status = _attendanceMap[matchingKey];
                      Color dotColor = AppColors.success;
                      if (status == 'Absent') dotColor = AppColors.error;
                      if (status == 'Late') dotColor = AppColors.warning;
                      
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                calendarStyle: const CalendarStyle(todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle)),
              ),
            ),
            const SizedBox(height: 24),

            // Logs
            const Text('Recent Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history, color: AppColors.textSecondary),
                  title: const Text('Biometric Punch-In'),
                  subtitle: const Text('08:45 AM - Main Gate'),
                  trailing: const Text('20 Mar 2026', style: TextStyle(fontSize: 12)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
