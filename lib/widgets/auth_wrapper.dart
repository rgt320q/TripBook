import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/screens/auth_screen.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/auth_service.dart';
import 'package:tripbook/services/firestore_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStream;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _authStream = AuthService().authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          // User is logged in, now handle the profile and locale.
          return FutureBuilder<UserProfile?>(
            future: _firestoreService.getUserProfile().first,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final langCode = profileSnapshot.data?.languageCode ?? 'tr';
              final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
              final currentLangCode = localeProvider.locale?.languageCode;

              // Check if the locale needs to be changed.
              if (currentLangCode != langCode) {
                // The locale needs to change. We schedule the change and show a
                // loading indicator. The MaterialApp rebuild will trigger this
                // builder to run again. On the next run, the locales will match
                // and the app will proceed to the MapScreen.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  localeProvider.setLocale(Locale(langCode));
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // If we reach here, the locale is correct. We can show the map.
              return const MapScreen();
            },
          );
        } else {
          // User is not logged in.
          return const AuthScreen();
        }
      },
    );
  }
}