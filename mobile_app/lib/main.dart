import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/driver_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/parent_dashboard.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase but don't let it block the app indefinitely
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint("Firebase init error or timeout: $e");
  }

  String? initialToken;
  String? initialRole;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    initialToken = prefs.getString('token');
    initialRole = prefs.getString('role');
  } catch (e) {
    debugPrint("SharedPreferences error: $e");
  }

  runApp(TrackMyBusApp(
    initialToken: initialToken,
    initialRole: initialRole,
  ));
}

class TrackMyBusApp extends StatelessWidget {
  final String? initialToken;
  final String? initialRole;

  TrackMyBusApp({this.initialToken, this.initialRole});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen = LoginScreen();
    
    if (initialToken != null && initialRole != null) {
      if (initialRole == 'driver') initialScreen = DriverDashboard();
      else if (initialRole == 'student') initialScreen = StudentDashboard();
      else if (initialRole == 'staff') initialScreen = StaffDashboard();
      else if (initialRole == 'parent') initialScreen = ParentDashboard();
      else if (initialRole == 'admin') initialScreen = AdminDashboard();
    }

    return MaterialApp(
      title: 'TrackMyBus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
      routes: {
        '/login': (context) => LoginScreen(),
        '/driver': (context) => DriverDashboard(),
        '/student': (context) => StudentDashboard(),
        '/staff': (context) => StaffDashboard(),
        '/parent': (context) => ParentDashboard(),
        '/register': (context) => RegisterScreen(),
        '/admin': (context) => AdminDashboard(),
      },
    );
  }
}
