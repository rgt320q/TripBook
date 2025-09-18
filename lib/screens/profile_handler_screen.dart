import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/screens/map_screen.dart';
import 'package:tripbook/services/firestore_service.dart';

/// A screen that handles loading the user profile after login,
/// setting the correct locale, and then navigating to the main app screen.
class ProfileHandlerScreen extends StatefulWidget {
  const ProfileHandlerScreen({super.key});

  @override
  State<ProfileHandlerScreen> createState() => _ProfileHandlerScreenState();
}

class _ProfileHandlerScreenState extends State<ProfileHandlerScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfileAndNavigate();
  }

  Future<void> _loadProfileAndNavigate() async {
    // Fetch the user profile from Firestore.
    final UserProfile? profile = await FirestoreService().getUserProfile().first;

    // If the widget is no longer in the tree, do nothing.
    if (!mounted) return;

    // Determine the language code, defaulting to 'tr'.
    final String langCode = profile?.languageCode ?? 'tr';

    // Set the locale in the provider.
    Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(langCode));

    // Navigate to the main map screen, replacing the current screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the profile is being loaded.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}