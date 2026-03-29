import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Centralized service handling both FCM Push Notifications and Local Device Alerts
/// Refactored to utilize named arguments guaranteeing compatibility with the latest flutter_local_notifications API.
class NotificationService {
  // Singleton Pattern for global access
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 1. Initialization Config
  static Future<void> initialize() async {
    // Request permission explicitly for Firebase (Required for iOS & Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Platform-specific Initialization settings
    // Requires a valid drawable icon at android/app/src/main/res/drawable/app_icon.png
    // Defaulting to Flutter launcher icon for now
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // [FIX APPLIED] Modern named arguments mapping for `initialize()`
    // We attach `onDidReceiveNotificationResponse` to capture the payload when the user taps on the alert.
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          debugPrint('Notification Payload Triggered: ${response.payload}');
          // TODO: Implement navigation routing or state changes based on payload String here.
        }
      },
    );

    // Set up foreground listener so we catch Push Notifications instantly while inside the app
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
          payload: message.data
              .toString(), // Passes FCM payload data to flutter_local_notifications handler
        );
      }
    });
  }

  /// 2. Notification Execution Engine
  /// Generates a local, visible push alert.
  /// [FIX APPLIED] Removed all positional arguments and replaced with strictly named parameters mapping to modern API structures.
  static Future<void> showNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
    String channelId = 'bus_tracking_priority_channel',
    String channelName = 'Realtime Bus Tracking',
    String channelDescription =
        'Provides critical alerts for approaching buses and route delays.',
  }) async {
    // Define exact Android notification channel details and behaviors
    AndroidNotificationDetails
    androidChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance
          .max, // Max Importance forces popup banner (Heads-up notification)
      priority: Priority.high, // High Priority alerts the lockscreen natively
      playSound: true,
      enableVibration: true,
      showWhen: true, // Show timestamp
      styleInformation: const BigTextStyleInformation(''), // Scales dynamically
    );

    const DarwinNotificationDetails iosChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    // Assigning Notification Details via clean wrapper
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidChannelSpecifics,
      iOS: iosChannelSpecifics,
    );

    // Invoke via strictly named parameters per modern constraints (0 positionals)
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  /// 3. Clear/Utility Operations
  /// Cancels an active specific notification by its ID
  static Future<void> cancelSpecificNotification({required int id}) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  /// Cancels all pushed notifications actively shown
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
