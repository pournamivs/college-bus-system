import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/constants/app_theme.dart';
import 'core/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/discovery_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'dart:async';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
    await DiscoveryService.discoverApi();
  } catch (e) {
    debugPrint("Init error: $e");
  }
  
  runApp(const ProviderScope(child: TrackMyBusApp()));
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
