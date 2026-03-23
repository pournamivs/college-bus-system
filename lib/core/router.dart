import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:track_my_bus/features/auth/splash_screen.dart';
import 'package:track_my_bus/features/auth/login_screen.dart';
import 'package:track_my_bus/features/student/dashboard/student_dashboard_screen.dart';
import 'package:track_my_bus/features/student/attendance/student_attendance_screen.dart';
import 'package:track_my_bus/features/student/fees/student_fines_screen.dart';
import 'package:track_my_bus/features/student/fees/student_fees_screen.dart';
import 'package:track_my_bus/features/student/tracking/student_tracking_screen.dart';
import 'package:track_my_bus/features/student/notifications/student_notifications_screen.dart';
import 'package:track_my_bus/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:track_my_bus/features/driver/dashboard/driver_main_screen.dart';
import 'package:track_my_bus/features/staff/dashboard/staff_dashboard_screen.dart';
import 'package:track_my_bus/features/parent/dashboard/parent_dashboard_screen.dart';

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
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/staff',
      name: 'staff_home',
      builder: (context, state) => const StaffDashboardScreen(),
    ),
    GoRoute(
      path: '/parent',
      name: 'parent_home',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin_home',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/driver',
      name: 'driver_home',
      builder: (context, state) => const DriverMainScreen(),
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
      path: '/student/notifications',
      name: 'student_notifications',
      builder: (context, state) => const StudentNotificationsScreen(),
    ),
  ],
);
