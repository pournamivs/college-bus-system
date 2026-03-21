import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/student/dashboard/student_main_screen.dart';
import '../features/student/attendance/student_attendance_screen.dart';
import '../features/student/fees/student_fines_screen.dart';
import '../features/student/fees/student_fees_screen.dart';
import '../features/student/tracking/student_tracking_screen.dart';
import '../features/student/notifications/student_notifications_screen.dart';
import '../features/admin/dashboard/admin_main_screen.dart';
import '../features/driver/dashboard/driver_main_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/student',
      name: 'student_home',
      builder: (context, state) => const StudentMainScreen(),
    ),
    GoRoute(
      path: '/student/tracking',
      name: 'student_tracking',
      builder: (context, state) => const StudentTrackingScreen(),
    ),
    GoRoute(
      path: '/student/fees',
      name: 'student_fees_route',
      builder: (context, state) => const StudentFeesScreen(),
    ),
    GoRoute(
      path: '/student/attendance',
      name: 'student_attendance',
      builder: (context, state) => const StudentAttendanceScreen(),
    ),
    GoRoute(
      path: '/student/fines',
      name: 'student_fines',
      builder: (context, state) => const StudentFinesScreen(),
    ),
    GoRoute(
      path: '/student/notifications',
      name: 'student_notifications',
      builder: (context, state) => const StudentNotificationsScreen(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin_home',
      builder: (context, state) => const AdminMainScreen(),
    ),
    GoRoute(
      path: '/driver',
      name: 'driver_home',
      builder: (context, state) => const DriverMainScreen(),
    ),
  ],
);
