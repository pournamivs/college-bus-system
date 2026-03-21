import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
