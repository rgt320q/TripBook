import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbook/screens/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final _usernameController = TextEditingController();
  
  String? _selectedLanguage;
  // For simplicity, we'll handle home location as text for now.
  final _homeLocationController = TextEditingController(); 

  late Future<UserProfile?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _loadUserProfile().then((profile) {
      if (profile != null && mounted) {
        _usernameController.text = profile.username ?? '';
        _selectedLanguage = profile.languageCode ?? 'tr';
        _homeLocationController.text = profile.homeLocation?.toString() ?? '';
      }
      return profile;
    });
  }

  Future<UserProfile?> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    // No need to set locale here, it's handled by the AuthWrapper
    return await _firestoreService.getUserProfile().first;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _homeLocationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // TODO: Implement GeoPoint conversion for home location
      final userProfile = UserProfile(
        uid: user.uid,
        username: _usernameController.text,
        languageCode: _selectedLanguage,
      );

      try {
        await _firestoreService.updateUserProfile(userProfile);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          // Update the app's locale
          if (_selectedLanguage != null) {
            Provider.of<LocaleProvider>(context, listen: false)
                .setLocale(Locale(_selectedLanguage!));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profileSaveSuccess)),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileScreenTitle),
      ),
      body: FutureBuilder<UserProfile?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            // If no profile, create a default one to avoid errors
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return _buildForm(l10n, UserProfile(uid: user.uid, languageCode: 'tr'));
            }
            return Center(child: Text(l10n.profileLoadError));
          }

          final profile = snapshot.data!;
          return _buildForm(l10n, profile);
        },
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n, UserProfile profile) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (user?.email != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(l10n.profileEmailLabel),
                subtitle: Text(user!.email!),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: l10n.profileUsernameLabel),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.profileUsernameValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _homeLocationController,
              decoration: InputDecoration(labelText: l10n.profileHomeLocationLabel),
              // TODO: Add a map picker
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(labelText: l10n.profileLanguageLabel),
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text(l10n.save),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logoutConfirmationTitle),
                    content: Text(l10n.logoutConfirmationContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.yes),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => AuthScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                }
              },
              child: Text(
                l10n.logout,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}