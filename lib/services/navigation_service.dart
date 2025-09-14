import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tripbook/screens/reached_locations_screen.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final StreamController<String> _navigationController =
      StreamController<String>.broadcast();

  void dispose() {
    _navigationController.close();
  }

  void handleNotificationPayload(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      _navigationController.add(payload);
    }
  }

  void setup() {
    _navigationController.stream.listen((payload) {
      if (payload.startsWith('open_logs_screen')) {
        final parts = payload.split(':');
        String? logId;
        if (parts.length > 1) {
          logId = parts[1];
        }

        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) =>
                  ReachedLocationsScreen(highlightedLogId: logId),
            ),
          );
        }
      }
    });
  }
}
