import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission (important for Android 13+ / iOS)
    await _messaging.requestPermission();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: settings);

    // Get & save FCM token
  try {
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  } catch (e) {
    print('Failed to get/save FCM token (will not block app startup): $e');
  }

    // Handle foreground push notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        channelId: 'flood_channel',
        channelName: 'Flood Alerts',
      );
    });
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }

  // 🔔 Generic Local Notification
  static Future<void> _showLocalNotification(
    String title,
    String body, {
    required String channelId,
    required String channelName,
    int? id,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: '$channelName channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // 🚨 Flood Alert (existing logic)
  static Future<void> showFloodAlert(String location) async {
    await _showLocalNotification(
      "🚨 High Flood Risk!",
      "Flood risk is HIGH in $location. Stay alert.",
      channelId: 'flood_channel',
      channelName: 'Flood Alerts',
    );
  }

  // 🌧 Rainfall Anomaly Alert (NEW)
  static Future<void> showRainfallAlert({
    required String location,
    required String anomalyType,
    required double rainfall,
  }) async {
    await _showLocalNotification(
      "🌧 Rainfall Anomaly Detected",
      "$location\n$anomalyType\nRainfall: ${rainfall.toStringAsFixed(1)} mm",
      channelId: 'rainfall_channel',
      channelName: 'Rainfall Alerts',
    );
  }

  // 🔔 Manual trigger (kept for compatibility)
  static Future<void> showNotification(String title, String body) async {
    await _showLocalNotification(
      title,
      body,
      channelId: 'flood_channel',
      channelName: 'Flood Alerts',
    );
  }
}