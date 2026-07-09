import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Payload of a notification tapped while the app was terminated. Consumed
  /// once by [takePendingTap] after the first screen is ready to route.
  Map<String, dynamic>? _pendingTap;

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
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _handleTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (e) {
          if (kDebugMode) print('Bad notification payload: $e');
        }
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
          payload: jsonEncode(message.data),
        );
      }

      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
    });

    // 5. Tap while the app was backgrounded but still alive.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleTap(message.data);
    });

    // 6. Tap that cold-started the app. No stream fires for this case, so the
    // message is only ever available from this one-shot call. Stash it until a
    // navigator exists.
    final initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) {
      _pendingTap = initialMessage.data;
    }
  }

  /// Returns the payload of a tap that launched the app from a terminated
  /// state, or null. Clears it so it is only ever routed once.
  Map<String, dynamic>? takePendingTap() {
    final tap = _pendingTap;
    _pendingTap = null;
    return tap;
  }

  void _handleTap(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('Notification tapped, data: $data');
    }
    // The app is already in the foreground by the time this runs; add
    // deep-link routing off `data` here when the payload defines a target.
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
