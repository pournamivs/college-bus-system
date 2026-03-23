import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_theme.dart';
import 'core/router.dart';
import 'core/services/notification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  
  runApp(const TrackMyBusApp());
}

class TrackMyBusApp extends StatelessWidget {
  const TrackMyBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We will inject Providers here later if needed globally
    return MaterialApp.router(
      title: 'TrackMyBus',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
