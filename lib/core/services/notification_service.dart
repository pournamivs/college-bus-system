import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    // Request permission for iOS/Android
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted FCM permission');
      await _saveDeviceToken();
      
      // Handle foreground notifications seamlessly
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null) {
          debugPrint('Notification Title: ${message.notification?.title}');
        }
      });
    }
  }

  Future<void> _saveDeviceToken() async {
    final String? uid = await _authService.getUid();
    if (uid == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(uid).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  /// Triggered by Driver during an Emergency
  Future<void> logSOSAlert(String busId, String driverId, String locationStr) async {
    await _db.collection('notifications').add({
      'type': 'sos_emergency',
      'busId': busId,
      'driverId': driverId,
      'title': 'Emergency SOS Alert',
      'body': 'Emergency reported on Bus $busId at location $locationStr',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // Can be picked up by Cloud Functions or SMS gateway (Twilio)
      'target': 'all_students_in_bus', // Identifies audience
    });
  }

  /// Triggered by System or Admin for Fee Collection
  Future<void> logFeeReminder(String studentId, String parentName, String parentPhone, double pendingAmount) async {
    await _db.collection('notifications').add({
      'type': 'fee_reminder',
      'studentId': studentId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'title': 'Bus Fee Reminder',
      'body': 'Dear $parentName, a bus fee of ₹$pendingAmount is pending for your ward.',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // SMS Gateway hook target
      'target': 'parent_sms',
    });
  }
}
