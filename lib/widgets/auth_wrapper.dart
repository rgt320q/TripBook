import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/screens/auth_screen.dart';
import 'package:tripbook/screens/email_verification_screen.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/auth_service.dart';
import 'package:tripbook/services/connectivity_service.dart';
import 'package:tripbook/services/notification_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStream;
  bool _notificationsHandled = false;

  @override
  void initState() {
    super.initState();
    // idTokenChanges also emits when the ID token is refreshed (e.g. right
    // after the user verifies their email), so the gate below flips to the
    // main app as soon as the verification is confirmed.
    _authStream = AuthService().idTokenChanges;
    
    // Initialize connectivity service at the start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConnectivityService().initialize(context);
    });
  }

  /// Asks for notification permission once the user is signed in (the opt-in
  /// moment), and on web explains how to unblock it if the browser denied it.
  void _handleNotifications() {
    if (_notificationsHandled) return;
    _notificationsHandled = true;
    NotificationService().requestPermission().then((settings) {
      if (!mounted) return;
      if (kIsWeb && settings.authorizationStatus == AuthorizationStatus.denied) {
        final l10n = AppLocalizations.of(context);
        if (l10n == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationsBlockedMessage),
            action: SnackBarAction(
              label: l10n.ok,
              onPressed: () {},
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    ConnectivityService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // While waiting for the auth state, show a loading indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Block unverified accounts from the app: after sign-up (or a sign-in
        // with a still-unverified email) the user must confirm their email
        // before reaching the main app.
        final user = snapshot.data;
        if (user != null && !user.emailVerified) {
          return EmailVerificationScreen(email: user.email ?? '');
        }

        // If the user is logged in and verified, show the main MapScreen.
        // The MapScreen will be responsible for loading its own data.
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNotifications();
          });
          return const MapScreen();
        } 
        // If the user is not logged in, show the AuthScreen.
        else {
          return const AuthScreen();
        }
      },
    );
  }
}
