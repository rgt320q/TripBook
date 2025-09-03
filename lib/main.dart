import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tripbook/firebase_options.dart';
import 'package:tripbook/services/navigation_service.dart';
import 'package:tripbook/services/notification_service.dart';
import 'package:tripbook/widgets/auth_wrapper.dart';

// This needs to be a top-level function (or a static method) for background isolate registration.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // This function is called on a separate isolate when the app is in the background.
  // We pass the payload to our navigation service to handle it on the main isolate.
  NavigationService().handleNotificationPayload(response.payload);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up the navigation service to listen for navigation events.
  NavigationService().setup();

  // Initialize the notification service with separate handlers for foreground and background.
  await NotificationService().init(
    onDidReceiveNotificationResponse: (response) {
      // This is for when the app is in the foreground.
      NavigationService().handleNotificationPayload(response.payload);
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use the navigatorKey from our singleton NavigationService.
      navigatorKey: NavigationService().navigatorKey,
      title: 'Trip Book',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}