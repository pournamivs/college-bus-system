import 'package:go_router/go_router.dart';
import '../features/auth/auth_wrapper.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/change_password_screen.dart';
import '../features/student/payments/student_payment_screen.dart';
import '../features/student/payments/payment_status_screen.dart';
import '../features/student/attendance/student_attendance_screen.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/dashboard/admin_live_tracking_screen.dart';
import '../features/admin/drivers/admin_drivers_screen.dart';
import '../features/admin/payments/admin_payments_screen.dart';
import '../features/admin/students/admin_students_screen.dart';
import '../features/admin/dashboard/admin_sos_screen.dart';
import '../features/admin/drivers/admin_driver_management_screen.dart';
import '../features/student/complaints/student_complaint_screen.dart';
import '../features/driver/complaints/driver_complaint_screen.dart';
import '../features/admin/maintenance/admin_maintenance_screen.dart';
import '../features/admin/buses/admin_bus_drilldown_screen.dart';
import '../features/admin/staff/admin_staff_management_screen.dart';
import '../features/admin/settings/admin_settings_screen.dart';
import '../features/admin/admin_reports_screen.dart';
import '../features/driver/driver_dashboard.dart';
import '../features/driver/driver_attendance_screen.dart';
import '../features/driver/driver_profile_screen.dart';
import '../features/student/student_dashboard.dart';
import '../features/student/notifications/student_notifications_screen.dart';
import '../features/staff/dashboard/staff_dashboard_screen.dart';
import '../features/admin/buses/admin_bus_management_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'root_auth',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/change-password',
      name: 'change_password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/student',
      name: 'student_home',
      builder: (context, state) => const StudentDashboard(),
    ),
    GoRoute(
      path: '/staff',
      name: 'staff_home',
      builder: (context, state) => const StaffDashboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin_home',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/tracking',
      name: 'admin_tracking',
      builder: (context, state) => const AdminLiveTrackingScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      name: 'admin_reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin/payments',
      name: 'admin_payments',
      builder: (context, state) => const AdminPaymentsScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      name: 'admin_users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/admin/emergencies',
      name: 'admin_emergencies',
      builder: (context, state) => const AdminSOSScreen(),
    ),
    GoRoute(
      path: '/admin/drivers',
      name: 'admin_drivers_management',
      builder: (context, state) => const AdminDriverManagementScreen(),
    ),
    GoRoute(
      path: '/driver',
      name: 'driver_home',
      builder: (context, state) => const DriverDashboard(),
    ),
    GoRoute(
      path: '/driver/attendance',
      name: 'driver_attendance',
      builder: (context, state) => const DriverAttendanceScreen(),
    ),
    GoRoute(
      path: '/driver/profile',
      name: 'driver_profile',
      builder: (context, state) => const DriverProfileScreen(),
    ),

    GoRoute(
      path: '/student/fees',
      name: 'student_fees_route',
      builder: (context, state) => const StudentPaymentScreen(),
    ),
    GoRoute(
      path: '/student/payment-status',
      name: 'payment_status',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        return PaymentStatusScreen(
          isSuccess: extra['isSuccess'] ?? false,
          message: extra['message'] ?? '',
          transactionId: extra['transactionId'],
        );
      },
    ),
    GoRoute(
      path: '/student/attendance',
      name: 'student_attendance',
      builder: (context, state) => const StudentAttendanceScreen(),
    ),

    GoRoute(
      path: '/student/complaints',
      name: 'student_complaints',
      builder: (context, state) => const StudentComplaintScreen(),
    ),
    GoRoute(
      path: '/driver/complaints',
      name: 'driver_complaints',
      builder: (context, state) => const DriverComplaintScreen(),
    ),
    GoRoute(
      path: '/admin/maintenance',
      name: 'admin_maintenance',
      builder: (context, state) => const AdminMaintenanceScreen(),
    ),
    GoRoute(
      path: '/admin/staff',
      name: 'admin_staff',
      builder: (context, state) => const AdminStaffManagementScreen(),
    ),
    GoRoute(
      path: '/admin/buses',
      name: 'admin_bus_management',
      builder: (context, state) => AdminBusManagementScreen(),
    ),
    GoRoute(
      path: '/admin/buses/:busId',
      name: 'admin_bus_drilldown',
      builder: (context, state) => AdminBusDrilldownScreen(busId: state.pathParameters['busId']!),
    ),
    GoRoute(
      path: '/student/notifications',
      name: 'student_notifications',
      builder: (context, state) => const StudentNotificationsScreen(),
    ),
  ],
);
