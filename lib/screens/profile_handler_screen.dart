import 'package:flutter/material.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/firestore_service.dart';

class ProfileHandlerScreen extends StatefulWidget {
  const ProfileHandlerScreen({super.key});

  @override
  State<ProfileHandlerScreen> createState() => _ProfileHandlerScreenState();
}

class _ProfileHandlerScreenState extends State<ProfileHandlerScreen> {
  @override
  void initState() {
    super.initState();
    _processProfileAndNavigate();
  }

  Future<void> _processProfileAndNavigate() async {
    // Ensure the context is mounted before using it.
    if (!mounted) return;

    // Single declaration at the top.
    final firestoreService = FirestoreService();

    try {
      // Wait for the first valid profile data from the stream.
      await firestoreService.getUserProfile().first;

      // If the widget is no longer in the tree after the await, do nothing.
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MapScreen(key: UniqueKey())),
          );
        }
      });
    } catch (e) {
      // If there is any error, navigate to the map screen anyway to not get stuck.
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Use the same firestoreService instance declared at the top.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MapScreen(key: UniqueKey())),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the profile is being fetched and processed.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}