import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/firebase_options.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/non_web_script_loader.dart'
    if (dart.library.html) 'package:tripbook/web_script_loader.dart';
import 'package:tripbook/providers/community_routes_provider.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/providers/theme_provider.dart';
import 'package:tripbook/services/navigation_service.dart';
import 'package:tripbook/services/notification_service.dart';
import 'package:tripbook/utils/brand_colors.dart';
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

  if (kIsWeb) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey != null) {
      loadGoogleMapsScript(apiKey);
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up Crashlytics, but not for the web
  if (!kIsWeb) {
    if (kDebugMode) {
      // Force enable Crashlytics collection for debugging purposes
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } else {
      // Handle Crashlytics collection in release mode
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

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
        ChangeNotifierProvider(
          create: (context) => ThemeProvider()..loadThemeMode(),
        ),
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
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              // Use the navigatorKey from our singleton NavigationService.
              navigatorKey: NavigationService().navigatorKey,
              title: 'Trip Book',
              theme: buildAppTheme(Brightness.light),
              darkTheme: buildAppTheme(Brightness.dark),
              themeMode: themeProvider.themeMode,
              locale: provider.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AuthWrapper(),
            );
          },
        );
      },
    );
  }
}

/// Builds the app theme for the given [brightness]. Brand colors (blue) stay
/// consistent across light and dark mode; surfaces/text adapt via the
/// generated [ColorScheme].
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blue.shade700,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF121212)
        : colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandButtonBlue(brightness),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brandButtonBlue(brightness),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: brandAppBarBlue(brightness),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? colorScheme.surfaceContainerHighest
          : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF303030) : Colors.grey[900],
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? Colors.white24 : Colors.grey[300],
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Colors.blue.shade600,
    ),
  );
}
