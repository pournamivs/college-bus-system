import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/constants/app_colors.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  State<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _busIdString;
  List<Map<String, dynamic>> _students = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _busIdString = userData['busId']?.toString();
          });
          if (_busIdString != null) {
            await _loadStudents();
          }
        }
      }
    } catch (e) {
      print('Error loading driver data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_busIdString == null) return;

    try {
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('busId', isEqualTo: _busIdString)
          .get();

      setState(() {
        _students = studentsQuery.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });

      await _loadAttendanceForDate(_selectedDate);
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    if (_busIdString == null) return;

    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('busId', isEqualTo: _busIdString)
          .where('date', isEqualTo: dateKey)
          .get();

      final attendanceMap = <String, String>{};
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        attendanceMap[data['studentId']] = data['status'] ?? '';
      }

      setState(() {
        _attendanceStatus = attendanceMap;
      });
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  Future<void> _markAttendance(String studentId, String status) async {
    if (_busIdString == null) return;

    final dateKey = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      await _firestoreService.markStudentAttendance(
        studentId,
        _busIdString!,
        dateKey,
        status,
      );

      setState(() {
        _attendanceStatus[studentId] = status;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance marked as $status'),
          backgroundColor: _getStatusColor(status),
        ),
      );
    } catch (e) {
      print('Error marking attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark attendance'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.warning;
      case 'half-day':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String _getCurrentStatus(String studentId) {
    return _attendanceStatus[studentId] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Calendar
                  GlassMorphicCard(
                    padding: const EdgeInsets.all(16),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _selectedDate,
                      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() => _selectedDate = selectedDay);
                        _loadAttendanceForDate(selectedDay);
                      },
                      calendarStyle: const CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Students List
                  Text(
                    'Students on Bus ${_busIdString ?? ''}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_students.isEmpty)
                    const Center(child: Text('No students assigned to this bus'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['id'];
                        final isPresent = _attendanceStatus[studentId] ?? false;

                        return GlassMorphicCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  student['name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'] ?? 'Unknown Student',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      student['email'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _markAttendance(studentId, 'present'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _getCurrentStatus(studentId) == 'present' ? AppColors.success : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Present', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _markAttendance(studentId, 'late'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _getCurrentStatus(studentId) == 'late' ? AppColors.warning : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Late', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _markAttendance(studentId, 'half-day'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _getCurrentStatus(studentId) == 'half-day' ? AppColors.secondary : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Half-day', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _markAttendance(studentId, 'absent'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _getCurrentStatus(studentId) == 'absent' ? AppColors.error : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Absent', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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