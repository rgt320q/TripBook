import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/screens/home_location_picker_screen.dart';
import 'package:tripbook/screens/avatar_selection_screen.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbook/utils/avatar_utils.dart';
import 'package:tripbook/services/auth_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<User?>? _authSubscription;

  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final _usernameController = TextEditingController(); // Deprecated, backward compatibility için
  final _fullNameController = TextEditingController(); // Yeni tek alan
  final _firstNameController = TextEditingController(); // Migration için tutuyoruz
  final _lastNameController = TextEditingController(); // Migration için tutuyoruz
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedLanguage;
  GeoPoint? _homeLocation;
  DateTime? _birthDate;
  String? _gender;
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
    _userProfileFuture = _loadUserProfile().then((profile) async {
      if (profile != null && mounted) {
        _usernameController.text = profile.name ?? '';
        _fullNameController.text = profile.fullName ?? '';
        // Migration: Eğer fullName yoksa firstName+lastName'den oluştur
        if (profile.fullName?.isEmpty ?? true) {
          final firstName = profile.firstName ?? '';
          final lastName = profile.lastName ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            _fullNameController.text = '$firstName $lastName'.trim();
          }
        }
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _nicknameController.text = profile.nickname ?? '';
        _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
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
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userProfile = UserProfile(
        uid: user.uid,
        name: _usernameController.text.trim(), // Backward compatibility için
        fullName: _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : null,
        firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
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
                Colors.blue[700]!,
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

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[700]!,
                  Colors.blue[50]!,
                ],
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedAvatarPath != null
                            ? SvgPicture.asset(
                                _selectedAvatarPath!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholderBuilder: (context) => Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue[600],
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue[600],
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectAvatar,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showProfileImageInPublic = !_showProfileImageInPublic;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _showProfileImageInPublic ? Colors.green[600] : Colors.grey[600],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _showProfileImageInPublic ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _usernameController.text.isNotEmpty 
                    ? _usernameController.text 
                    : l10n.profileUsernameLabel,
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
          ),
          
          // Form Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  _buildSectionCard(
                    title: l10n.personalInfo,
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        // Ad Soyad ile göz simgesi
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fullNameController,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Ad Soyad',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _displayNameInPublic == 'fullName' ? Colors.blue[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _displayNameInPublic == 'fullName' ? Colors.blue[300]! : Colors.grey[300]!,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _displayNameInPublic == 'fullName' ? Icons.visibility : Icons.visibility_off,
                                  color: _displayNameInPublic == 'fullName' ? Colors.blue[600] : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _displayNameInPublic = 'fullName';
                                  });
                                },
                                tooltip: _displayNameInPublic == 'fullName' 
                                  ? 'Ad Soyad paylaşımlarda görünür' 
                                  : 'Ad Soyad paylaşımlarda görünmez',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Bağlantı çizgisi
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              // Sol boşluk (input field genişliği + spacing)
                              Expanded(child: Container()),
                              const SizedBox(width: 8),
                              // Göz simgeleri arası bağlantı
                              SizedBox(
                                width: 48, // IconButton genişliği
                                child: Column(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: 2,
                                      decoration: BoxDecoration(
                                        color: _displayNameInPublic == 'fullName' ? Colors.blue[300] : Colors.orange[300],
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        width: 2,
                                        child: CustomPaint(
                                          painter: DashedLinePainter(
                                            color: _displayNameInPublic == 'fullName' ? Colors.blue[300]! : Colors.orange[300]!,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 8,
                                      width: 2,
                                      decoration: BoxDecoration(
                                        color: _displayNameInPublic == 'nickname' ? Colors.orange[300] : Colors.blue[300],
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Takma İsim ile göz simgesi
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nicknameController,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: l10n.nicknameLabel,
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _displayNameInPublic == 'nickname' ? Colors.orange[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _displayNameInPublic == 'nickname' ? Colors.orange[300]! : Colors.grey[300]!,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _displayNameInPublic == 'nickname' ? Icons.visibility : Icons.visibility_off,
                                  color: _displayNameInPublic == 'nickname' ? Colors.orange[600] : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _displayNameInPublic = 'nickname';
                                  });
                                },
                                tooltip: _displayNameInPublic == 'nickname' 
                                  ? 'Takma İsim paylaşımlarda görünür' 
                                  : 'Takma İsim paylaşımlarda görünmez',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Username (Eski sistem için backward compatibility)
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: '${l10n.profileUsernameLabel} (Eski)',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            helperText: 'Eski sistem için - yeni kullanıcılar yukarıdaki alanları kullanın',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone
                        _buildInputWithPrivacy(
                          controller: _phoneController,
                          labelText: l10n.profileEmailLabel, // Reusing email label as phone/contact
                          icon: Icons.phone,
                          isPublic: _showPhoneInPublic,
                          onPrivacyChanged: (value) {
                            setState(() {
                              _showPhoneInPublic = value;
                            });
                          },
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        // Birth Date
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectBirthDate,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.birthDate,
                                    prefixIcon: const Icon(Icons.cake),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  child: Text(
                                    _birthDate != null 
                                      ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                      : l10n.select,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _birthDate != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _showBirthDateInPublic ? Colors.green[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showBirthDateInPublic ? Colors.green[300]! : Colors.grey[300]!,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _showBirthDateInPublic ? Icons.visibility : Icons.visibility_off,
                                  color: _showBirthDateInPublic ? Colors.green[600] : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showBirthDateInPublic = !_showBirthDateInPublic;
                                  });
                                },
                                tooltip: _showBirthDateInPublic ? l10n.visibleToPublic : l10n.visibleToOnlyYou,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Gender
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: ['Erkek', 'Kadın', 'Diğer'].contains(_gender) ? _gender : null,
                                decoration: InputDecoration(
                                  labelText: l10n.gender,
                                  prefixIcon: const Icon(Icons.people),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
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
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _showGenderInPublic ? Colors.green[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showGenderInPublic ? Colors.green[300]! : Colors.grey[300]!,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _showGenderInPublic ? Icons.visibility : Icons.visibility_off,
                                  color: _showGenderInPublic ? Colors.green[600] : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showGenderInPublic = !_showGenderInPublic;
                                  });
                                },
                                tooltip: _showGenderInPublic ? l10n.visibleToPublic : l10n.visibleToOnlyYou,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bio Section
                  _buildSectionCard(
                    title: l10n.aboutMe,
                    icon: Icons.description_outlined,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bioController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: l10n.introduceYourself,
                              hintText: l10n.writeBioHint,
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              alignLabelWithHint: true,
                            ),
                            maxLength: 200,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: _showBioInPublic ? Colors.green[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showBioInPublic ? Colors.green[300]! : Colors.grey[300]!,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _showBioInPublic ? Icons.visibility : Icons.visibility_off,
                              color: _showBioInPublic ? Colors.green[600] : Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _showBioInPublic = !_showBioInPublic;
                              });
                            },
                            tooltip: _showBioInPublic ? l10n.visibleToPublic : l10n.visibleToOnlyYou,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Settings Section
                  _buildSectionCard(
                    title: l10n.settings,
                    icon: Icons.settings_outlined,
                    child: Column(
                      children: [
                        // Home Location
                        InkWell(
                          onTap: _pickHomeLocation,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
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
                                          '${_homeLocation!.latitude.toStringAsFixed(4)}, ${_homeLocation!.longitude.toStringAsFixed(4)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Language
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          decoration: InputDecoration(
                            labelText: l10n.language,
                            prefixIcon: const Icon(Icons.language),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
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
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Security Section
                  _buildSectionCard(
                    title: l10n.security,
                    icon: Icons.security_outlined,
                    child: Column(
                      children: [
                        // Change Password Button
                        SizedBox(
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
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Action Buttons
                  Column(
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
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
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
                          },
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
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  Widget _buildInputWithPrivacy({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isPublic,
    required Function(bool) onPrivacyChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 16),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: labelText,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: validator,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: isPublic ? Colors.green[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPublic ? Colors.green[300]! : Colors.grey[300]!,
            ),
          ),
          child: IconButton(
            icon: Icon(
              isPublic ? Icons.visibility : Icons.visibility_off,
              color: isPublic ? Colors.green[600] : Colors.grey[600],
              size: 20,
            ),
            onPressed: () => onPrivacyChanged(!isPublic),
            tooltip: isPublic ? l10n.visibleToPublic : l10n.visibleToOnlyYou,
          ),
        ),
      ],
    );
  }
}

// Kesikli çizgi çizen custom painter sınıfı
class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0.0;
    
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
  