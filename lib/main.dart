import 'package:tripbook/providers/community_routes_provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/firebase_options.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/services/navigation_service.dart';
import 'package:tripbook/services/notification_service.dart';
import 'package:tripbook/widgets/auth_wrapper.dart';

// This needs to be a top-level function for background isolate registration.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // This function is called on a separate isolate when a notification is tapped and the app is in the background.
  // We pass the payload to our navigation service to handle it on the main isolate.
  // Note: You might need a robust way to ensure NavigationService() is initialized if it holds state.
  NavigationService().handleNotificationPayload(response.payload);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up the navigation service to listen for navigation events.
  final navigationService = NavigationService();
  navigationService.setup();

  // Initialize the notification service.
  await NotificationService().init(
    onDidReceiveNotificationResponse: (response) {
      // This handles taps on notifications when the app is in the foreground.
      navigationService.handleNotificationPayload(response.payload);
    },
    // Provide the top-level function for background taps.
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => CommunityRoutesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          // Use the navigatorKey from our singleton NavigationService.
          navigatorKey: NavigationService().navigatorKey,
          title: 'Trip Book',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue.shade700,
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 2,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
          ),
          locale: provider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthWrapper(),
        );
      },
    );
  }
}
