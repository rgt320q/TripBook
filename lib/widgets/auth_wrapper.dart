import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tripbook/screens/auth_screen.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = AuthService().authStateChanges;
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

        // If the user is logged in, show the main MapScreen.
        // The MapScreen will be responsible for loading its own data.
        if (snapshot.hasData) {
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
