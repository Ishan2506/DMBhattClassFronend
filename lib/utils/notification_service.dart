import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? get _fcm {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (_) {}
    return null;
  }

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  Future<void> initialize() async {
    final fcm = _fcm;
    if (fcm == null) {
      if (kDebugMode) {
        print('Firebase is not initialized, skipping notification initialization.');
      }
      return;
    }

    // 1. Request Permission
    NotificationSettings settings = await fcm.requestPermission(
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

    // 3. Subscribe to the 'all' topic
    await fcm.subscribeToTopic('all');

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

  Future<void> subscribeToStandardTopic(String standard) async {
    if (standard.isEmpty || standard == 'N/A') {
      if (kDebugMode) print('Standard is not available, skipping topic subscription');
      return;
    }

    final fcm = _fcm;
    if (fcm == null) {
      if (kDebugMode) print('Firebase not initialized, skipping std topic subscription');
      return;
    }

    final topic = 'std_$standard';
    try {
      await fcm.subscribeToTopic(topic);
      if (kDebugMode) print('Subscribed to topic: $topic');
    } catch (e) {
      if (kDebugMode) print('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> subscribeToUserTopic(String userId) async {
    if (userId.isEmpty) {
      if (kDebugMode) print('UserId is not available, skipping user topic subscription');
      return;
    }

    final fcm = _fcm;
    if (fcm == null) {
      if (kDebugMode) print('Firebase not initialized, skipping user topic subscription');
      return;
    }

    final topic = 'user_$userId';
    try {
      await fcm.subscribeToTopic(topic);
      if (kDebugMode) print('Subscribed to user topic: $topic');
    } catch (e) {
      if (kDebugMode) print('Error subscribing to user topic $topic: $e');
    }
  }
}
