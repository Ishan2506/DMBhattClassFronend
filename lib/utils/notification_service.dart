import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    }

    // 2. Initialize Local Notifications for Foreground Popups
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // Create High Importance Channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Subscribe to topics
    await _fcm.subscribeToTopic('all');

    // Subscribe to student's standard topic if available
    final studentStd = await _getStudentStandard();
    if (studentStd != null && studentStd.isNotEmpty) {
      await _fcm.subscribeToTopic('std_$studentStd');
    }

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }

      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
    });

    // 5. Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification clicked! Opening app...');
      }
    });
  }

  Future<String?> _getStudentStandard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('std');
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student standard: $e');
      }
      return null;
    }
  }

  /// Subscribe to topic based on student's standard
  /// Call this after student logs in to subscribe to their standard topic
  Future<void> subscribeToStudentTopic() async {
    try {
      final studentStd = await _getStudentStandard();
      if (studentStd != null && studentStd.isNotEmpty) {
        await _fcm.subscribeToTopic('std_$studentStd');
        if (kDebugMode) {
          print('Subscribed to topic: std_$studentStd');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to student topic: $e');
      }
    }
  }

  /// Unsubscribe from old topic when student logs out
  Future<void> unsubscribeFromStudentTopic(String? std) async {
    try {
      if (std != null && std.isNotEmpty) {
        await _fcm.unsubscribeFromTopic('std_$std');
        if (kDebugMode) {
          print('Unsubscribed from topic: std_$std');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from student topic: $e');
      }
    }
  }
}
