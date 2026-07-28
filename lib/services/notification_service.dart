import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tripbook/services/firestore_service.dart';

// Needs to be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(); // THIS IS VITAL for background message handling
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }

  // On Android, if the message has a notification payload, the system handles it.
  // We should not show a second notification.
  if (defaultTargetPlatform == TargetPlatform.android &&
      message.notification != null) {
    if (kDebugMode) {
      print("Notification payload already present, system will handle it.");
    }
    return;
  }

  // Use the local notification service to show the notification.
  // We create a new instance because this is a separate isolate.
  final title =
      message.data['title'] ?? message.notification?.title ?? 'New Message';
  final body = message.data['body'] ?? message.notification?.body ?? '';

  if (!kIsWeb) {
    await NotificationService().showNotification(
      title,
      body,
      payload: message.data['payload'] as String?,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init({
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (!kIsWeb) {
      // --- Local Notifications Initialization ---
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            onDidReceiveBackgroundNotificationResponse,
      );
    }

    // --- Firebase Messaging Initialization ---
    await _requestPermissions();
    // await _getAndSaveToken(); // DO NOT CALL THIS HERE. It will be called on login.
    _listenForTokenRefresh();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
        if (!kIsWeb) {
          showNotification(
            message.notification?.title ?? 'New Message',
            message.notification?.body ?? '',
            payload: message.data['payload'] as String?,
          );
        } else {
          // On web, we could use native browser notifications if we wanted, 
          // but for now we'll just log it as FirebaseMessaging usually handles 
          // notifications automatically if the app is in the background.
          if (kDebugMode) {
            print('Web notification received in foreground: ${message.notification?.title}');
          }
        }
      }
    });

    // Set the background message handler
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _getAndSaveToken() async {
    final user = _auth.currentUser;
    if (user == null) return; // No user logged in

    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print("FCM Token: $token");
        }
        // Save the token to the user's profile in Firestore
        final userProfile = await _firestoreService.getUserProfile().first;
        if (userProfile != null) {
          final updatedProfile = userProfile.copyWith(fcmToken: token);
          await _firestoreService.updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting or saving FCM token: $e");
      }
    }
  }

  void _listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print("FCM Token refreshed: $newToken");
      }
      _getAndSaveToken(); // Re-save the new token
    }).onError((err) {
      if (kDebugMode) {
        print("Error on token refresh: $err");
      }
    });
  }

  Future<void> showNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // channel id (matches AndroidManifest)
      'High Importance Notifications', // channel name
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.toUnsigned(31),
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  // Call this method on user login
  Future<void> onUserLogin() async {
    if (kIsWeb) return;
    await _getAndSaveToken();
  }

  // Call this method on user logout
  Future<void> onUserLogout() async {
    if (kIsWeb) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // It's good practice to clear the token on logout
      final userProfile = await _firestoreService.getUserProfile().first;
      if (userProfile != null && userProfile.fcmToken != null) {
        final updatedProfile = userProfile.copyWith(fcmToken: ''); // Clear token
        await _firestoreService.updateUserProfile(updatedProfile);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing FCM token on logout: $e");
      }
    }
  }
}