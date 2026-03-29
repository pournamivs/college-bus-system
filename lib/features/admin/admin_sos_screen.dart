import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/widgets/glass_morphic_card.dart';
import '../../../core/constants/app_colors.dart';

class AdminSOSScreen extends StatefulWidget {
  const AdminSOSScreen({super.key});

  @override
  State<AdminSOSScreen> createState() => _AdminSOSScreenState();
}

class _AdminSOSScreenState extends State<AdminSOSScreen> {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings);
  }

  Future<void> _showSOSNotification(String userId, double lat, double lng) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS Alerts',
      channelDescription: 'Emergency SOS alerts from users',
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.error,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      0,
      'EMERGENCY SOS ALERT',
      'User $userId sent SOS from location: $lat, $lng',
      details,
    );
  }

  Future<void> _resolveSOS(String sosId) async {
    await FirebaseFirestore.instance.collection('sos').doc(sosId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SOS Emergency Alerts'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos')
            .where('status', isEqualTo: 'active')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sosAlerts = snapshot.data!.docs;

          if (sosAlerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text(
                    'No Active SOS Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All emergency situations are under control',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Show notification for new alerts
          for (var doc in sosAlerts) {
            final data = doc.data() as Map<String, dynamic>;
            final location = data['location'] as Map<String, dynamic>;
            _showSOSNotification(
              data['userId'],
              location['lat'],
              location['lng'],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sosAlerts.length,
            itemBuilder: (context, index) {
              final sosDoc = sosAlerts[index];
              final data = sosDoc.data() as Map<String, dynamic>;
              final location = data['location'] as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp).toDate();

              return GlassMorphicCard(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMERGENCY SOS ALERT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                              Text(
                                'User ID: ${data['userId']}',
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location: ${location['lat'].toStringAsFixed(6)}, ${location['lng'].toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Time: ${timestamp.toString()}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _resolveSOS(sosDoc.id),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark as Resolved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement call functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Call feature coming soon')),
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}