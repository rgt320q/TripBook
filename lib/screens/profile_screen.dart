import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/providers/theme_provider.dart';
import 'package:tripbook/screens/home_location_picker_screen.dart';
import 'package:tripbook/screens/avatar_selection_screen.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbook/services/connectivity_service.dart';
import 'package:tripbook/utils/avatar_utils.dart';
import 'package:tripbook/utils/brand_colors.dart';
import 'package:tripbook/services/auth_service.dart';
import 'package:tripbook/widgets/loading_overlay.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<User?>? _authSubscription;

  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deleteAccountPasswordController = TextEditingController();

  String? _selectedLanguage;
  GeoPoint? _homeLocation;
  DateTime? _birthDate;
  String? _gender;
  ThemeMode _selectedThemeMode = ThemeMode.system;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _selectedAvatarPath; // Seçili avatar

  // Görünürlük ayarları
  bool _showFullNameInPublic = true;
  bool _showNicknameInPublic = true;
  String _displayNameInPublic = 'nickname'; // Paylaşımlarda hangi isim görünecek
  bool _showBioInPublic = false;
  bool _showProfileImageInPublic = true;
  bool _showPhoneInPublic = false;
  bool _showBirthDateInPublic = false;
  bool _showGenderInPublic = false;

  late Future<UserProfile?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    _userProfileFuture = _loadUserProfile().then((profile) async {
      if (profile != null && mounted) {
        _fullNameController.text = profile.fullName ?? '';
        // Migration: Eski firstName+lastName alanlarından fullName oluştur.
        if (profile.fullName?.isEmpty ?? true) {
          final firstName = profile.firstName ?? '';
          final lastName = profile.lastName ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            _fullNameController.text = '$firstName $lastName'.trim();
          }
        }
        _nicknameController.text = profile.nickname ?? '';
        _phoneController.text = profile.phone ?? '';
        _bioController.text = profile.bio ?? '';
        _selectedLanguage = profile.languageCode ?? 'tr';
        _birthDate = profile.birthDate?.toDate();
        _gender = profile.gender;
        _selectedAvatarPath = profile.selectedAvatarPath ?? AvatarUtils.getDefaultAvatar();

        // Görünürlük ayarlarını yükle
        _showFullNameInPublic = profile.showFullNameInPublic;
        _showNicknameInPublic = profile.showNicknameInPublic;
        _displayNameInPublic = profile.displayNameInPublic;
        _showBioInPublic = profile.showBioInPublic;
        _showProfileImageInPublic = profile.showProfileImageInPublic;
        _showPhoneInPublic = profile.showPhoneInPublic;
        _showBirthDateInPublic = profile.showBirthDateInPublic;
        _showGenderInPublic = profile.showGenderInPublic;

        setState(() {
          _homeLocation = profile.homeLocation;
        });
      }
      return profile;
    });

    // Listen for auth changes to pop the screen on logout.
    _authSubscription = AuthService().authStateChanges.listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<UserProfile?> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await _firestoreService.getUserProfile().first;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _fullNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deleteAccountPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await ConnectivityService().executeWithConnectivityCheck(
        context,
        () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          final fullName = _fullNameController.text.trim();

          final userProfile = UserProfile(
            uid: user.uid,
            name: fullName.isNotEmpty ? fullName : null, // Backward compatibility için
            fullName: fullName.isNotEmpty ? fullName : null,
            nickname: _nicknameController.text.trim().isNotEmpty ? _nicknameController.text.trim() : null,
            phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
            bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
            languageCode: _selectedLanguage,
            homeLocation: _homeLocation,
            birthDate: _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
            gender: _gender,
            selectedAvatarPath: _selectedAvatarPath,
            showFullNameInPublic: _showFullNameInPublic,
            showNicknameInPublic: _showNicknameInPublic,
            displayNameInPublic: _displayNameInPublic,
            showBioInPublic: _showBioInPublic,
            showProfileImageInPublic: _showProfileImageInPublic,
            showPhoneInPublic: _showPhoneInPublic,
            showBirthDateInPublic: _showBirthDateInPublic,
            showGenderInPublic: _showGenderInPublic,
          );

          try {
            await _firestoreService.updateUserProfile(userProfile);
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              if (_selectedLanguage != null) {
                Provider.of<LocaleProvider>(
                  context,
                  listen: false,
                ).setLocale(Locale(_selectedLanguage!));
              }
              await Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).setThemeMode(_selectedThemeMode);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(
                content: Text(l10n.profileSaveSuccess),
                backgroundColor: Colors.green,
              ));
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(
                content: Text(l10n.error(e.toString())),
                backgroundColor: Colors.red,
              ));
            }
          }
        },
      );
    }
  }

  void _pickHomeLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeLocationPickerScreen(
          initialLocation: _homeLocation != null
              ? LatLng(_homeLocation!.latitude, _homeLocation!.longitude)
              : null,
        ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _homeLocation = GeoPoint(
          pickedLocation.latitude,
          pickedLocation.longitude,
        );
      });
    }
  }

  void _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.changePassword),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isNewPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.fieldRequired;
                    }
                    if (value.length < 6) {
                      return l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPassword,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.fieldRequired;
                    }
                    if (value != _newPasswordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _performPasswordChange();
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _performPasswordChange() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
          if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordChangedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.passwordChangeError;
        if (e.toString().contains('wrong-password')) {
          errorMessage = l10n.wrongCurrentPassword;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[600]),
            const SizedBox(width: 8),
            Flexible(child: Text(l10n.deleteAccountConfirmationTitle)),
          ],
        ),
        content: Text(l10n.deleteAccountConfirmationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _showDeleteAccountReauthDialog();
    }
  }

  Future<void> _showDeleteAccountReauthDialog() async {
    final l10n = AppLocalizations.of(context)!;
    _deleteAccountPasswordController.clear();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.red[600]),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.deleteAccountReauthTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountReauthContent),
              const SizedBox(height: 16),
              TextField(
                controller: _deleteAccountPasswordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.currentPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isEmpty) return;
                  Navigator.of(dialogContext).pop();
                  _performDeleteAccount();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (_deleteAccountPasswordController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                _performDeleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    LoadingOverlay.show(context, message: l10n.deleteAccountInProgress);

    final String? error;
    try {
      error = await AuthService().deleteAccount(
        password: _deleteAccountPasswordController.text,
      );
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteAccountError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    LoadingOverlay.hide(context);

    if (error != null) {
      String message = l10n.deleteAccountError;
      if (error.contains('wrong-password') ||
          error == 'invalid-credential') {
        message = l10n.wrongCurrentPassword;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // On success the authStateChanges listener in initState pops this screen
    // back to the root, where AuthWrapper shows the auth screen.
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(l10n.logoutConfirmationTitle),
          ],
        ),
        content: Text(l10n.logoutConfirmationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  void _selectBirthDate() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: l10n.selectBirthDate,
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _selectAvatar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarSelectionScreen(
          currentSelectedAvatar: _selectedAvatarPath,
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedAvatarPath = result;
      });

      // Seçimi kaydet
      await _saveAvatarSelection(result);
    }
  }

  Future<void> _saveAvatarSelection(String avatarPath) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Mevcut profili al ve avatar güncelle
      final currentProfile = await _firestoreService.getUserProfile().first;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          selectedAvatarPath: avatarPath,
        );

        await _firestoreService.updateUserProfile(updatedProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.avatarUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error("")} ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profileScreenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brandAppBarBlue(Theme.of(context).brightness),
                Colors.blue[900]!,
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<UserProfile?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return _buildForm(
                l10n,
                UserProfile(uid: user.uid, languageCode: 'tr'),
              );
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
    final colorScheme = Theme.of(context).colorScheme;
    final headerName = _nicknameController.text.trim().isNotEmpty
        ? _nicknameController.text.trim()
        : (_fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : l10n.profileUsernameLabel);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(l10n, user, headerName),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kişisel Bilgiler
                  _buildSectionCard(
                    title: l10n.personalInfo,
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _fullNameController,
                          label: l10n.fullNameLabel,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nicknameController,
                          label: l10n.nicknameLabel,
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 16),
                        _buildDisplayNamePreference(l10n),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: l10n.phone,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(l10n),
                        const SizedBox(height: 16),
                        _buildGenderField(l10n),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hakkında
                  _buildSectionCard(
                    title: l10n.aboutMe,
                    icon: Icons.description_outlined,
                    child: TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 200,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: l10n.introduceYourself,
                        hintText: l10n.writeBioHint,
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Gizlilik ve Görünürlük
                  _buildSectionCard(
                    title: l10n.privacySectionTitle,
                    icon: Icons.visibility_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.privacyNotice,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildPrivacySwitch(
                          value: _showProfileImageInPublic,
                          icon: Icons.account_circle_outlined,
                          label: l10n.profilePhoto,
                          onChanged: (v) =>
                              setState(() => _showProfileImageInPublic = v),
                        ),
                        _buildPrivacySwitch(
                          value: _showPhoneInPublic,
                          icon: Icons.phone_outlined,
                          label: l10n.phone,
                          onChanged: (v) => setState(() => _showPhoneInPublic = v),
                        ),
                        _buildPrivacySwitch(
                          value: _showBirthDateInPublic,
                          icon: Icons.cake_outlined,
                          label: l10n.birthDate,
                          onChanged: (v) =>
                              setState(() => _showBirthDateInPublic = v),
                        ),
                        _buildPrivacySwitch(
                          value: _showGenderInPublic,
                          icon: Icons.people_outline,
                          label: l10n.gender,
                          onChanged: (v) => setState(() => _showGenderInPublic = v),
                        ),
                        _buildPrivacySwitch(
                          value: _showBioInPublic,
                          icon: Icons.description_outlined,
                          label: l10n.aboutMe,
                          onChanged: (v) => setState(() => _showBioInPublic = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ayarlar
                  _buildSectionCard(
                    title: l10n.settings,
                    icon: Icons.settings_outlined,
                    child: Column(
                      children: [
                        _buildHomeLocationTile(l10n),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          decoration: InputDecoration(
                            labelText: l10n.language,
                            prefixIcon: const Icon(Icons.language),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          items: [
                            DropdownMenuItem(value: 'tr', child: Text(l10n.languageTurkish)),
                            DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ThemeMode>(
                          initialValue: _selectedThemeMode,
                          decoration: InputDecoration(
                            labelText: l10n.theme,
                            prefixIcon: const Icon(Icons.dark_mode_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text(l10n.themeSystem),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text(l10n.themeLight),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text(l10n.themeDark),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedThemeMode = value ?? ThemeMode.system;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Güvenlik
                  _buildSectionCard(
                    title: l10n.security,
                    icon: Icons.security_outlined,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_outline),
                        label: Text(l10n.changePassword),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildActionButtons(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n, User? user, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            brandButtonBlue(Theme.of(context).brightness),
            isDark ? Colors.blue[900]! : Colors.blue[50]!,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white70, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedAvatarPath != null
                      ? SvgPicture.asset(
                          _selectedAvatarPath!,
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                          placeholderBuilder: (context) => Icon(
                            Icons.person,
                            size: 56,
                            color: Colors.blue[600],
                          ),
                        )
                      : Icon(Icons.person, size: 56, color: Colors.blue[600]),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _selectAvatar,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: brandButtonBlue(Theme.of(context).brightness),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user!.email!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildDisplayNamePreference(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.displayNamePreference,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'nickname',
                label: Text(l10n.useNickname),
                icon: const Icon(Icons.alternate_email, size: 18),
              ),
              ButtonSegment(
                value: 'fullName',
                label: Text(l10n.useFullName),
                icon: const Icon(Icons.badge_outlined, size: 18),
              ),
            ],
            selected: {_displayNameInPublic == 'fullName' ? 'fullName' : 'nickname'},
            onSelectionChanged: (selection) {
              setState(() {
                _displayNameInPublic = selection.first;
                if (_displayNameInPublic == 'fullName') {
                  _showFullNameInPublic = true;
                } else {
                  _showNicknameInPublic = true;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _selectBirthDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.birthDate,
          prefixIcon: const Icon(Icons.cake_outlined),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          _birthDate != null
              ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
              : l10n.select,
          style: TextStyle(
            fontSize: 16,
            color: _birthDate != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: ['Erkek', 'Kadın', 'Diğer'].contains(_gender) ? _gender : null,
      decoration: InputDecoration(
        labelText: l10n.gender,
        prefixIcon: const Icon(Icons.people),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      items: [
        DropdownMenuItem(value: 'Erkek', child: Text(l10n.male)),
        DropdownMenuItem(value: 'Kadın', child: Text(l10n.female)),
        DropdownMenuItem(value: 'Diğer', child: Text(l10n.other)),
      ],
      onChanged: (value) {
        setState(() {
          _gender = value;
        });
      },
    );
  }

  Widget _buildPrivacySwitch({
    required bool value,
    required IconData icon,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: colorScheme.primary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildHomeLocationTile(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickHomeLocation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _homeLocation != null
                        ? l10n.homeLocation
                        : l10n.notSet,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_homeLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_homeLocation!.latitude.toStringAsFixed(4)}, '
                      '${_homeLocation!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save, size: 20),
            label: Text(
              l10n.save,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandButtonBlue(Theme.of(context).brightness),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: Icon(Icons.logout, color: Colors.red[600], size: 20),
            label: Text(
              l10n.logout,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red[600]!, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _confirmDeleteAccount,
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
            label: Text(
              l10n.deleteAccount,
              style: TextStyle(fontSize: 15, color: Colors.red[400]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: child,
          ),
        ],
      ),
    );
  }
}
