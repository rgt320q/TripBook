import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/services/database_service.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/services/notification_service.dart';
import 'package:tripbook/utils/image_storage_utils.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final NotificationService _notificationService;
  FirestoreService? _firestoreService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    NotificationService? notificationService,
    FirestoreService? firestoreService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? NotificationService(),
        _firestoreService = firestoreService;

  // Constructed lazily so creating an AuthService never touches Firestore
  // (keeps AuthService usable in tests that only exercise signIn/signOut).
  FirestoreService get _firestore => _firestoreService ??= FirestoreService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream that also emits when the current user's ID token is refreshed
  /// (e.g. after email verification). Used by the auth gate so an unverified
  /// user is moved into the app as soon as they verify their email.
  Stream<User?> get idTokenChanges => _firebaseAuth.idTokenChanges();

  /// Where users land after confirming their email (the Firebase Hosting web
  /// app). Kept in sync with the redirect choice for the verification email.
  static const String verificationRedirectUrl =
      'https://tripbook-68238.web.app/';

  /// Tells Firebase to redirect the user to [verificationRedirectUrl] after
  /// the email is verified instead of Firebase's generic confirmation page.
  ActionCodeSettings get _verificationActionCodeSettings => ActionCodeSettings(
        url: verificationRedirectUrl,
        handleCodeInApp: false,
      );

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _notificationService.onUserLogin(); // Save FCM token
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      return e.message ?? e.code; // Return error message or code
    } catch (e) {
      if (kDebugMode) {
        print('Unknown Auth Error: $e');
      }
      return e.toString();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    String? fullName,
    String? nickname,
    DateTime? birthDate,
    String? gender,
    String? languageCode,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      final trimmedLanguageCode = languageCode?.trim();
      final hasProfileFields =
          fullName?.trim().isNotEmpty == true ||
          nickname?.trim().isNotEmpty == true ||
          birthDate != null ||
          gender?.isNotEmpty == true ||
          trimmedLanguageCode?.isNotEmpty == true;

      // Save the initial profile so the fields collected during sign-up are
      // persisted and don't need to be re-entered later.
      if (hasProfileFields && user != null) {
        final trimmedFullName = fullName?.trim();
        final trimmedNickname = nickname?.trim();
        await _firestore.updateUserProfile(
          UserProfile(
            uid: user.uid,
            name: trimmedFullName?.isNotEmpty == true
                ? trimmedFullName
                : null, // Backward compatibility için
            fullName: trimmedFullName?.isNotEmpty == true
                ? trimmedFullName
                : null,
            nickname: trimmedNickname?.isNotEmpty == true
                ? trimmedNickname
                : null,
            birthDate: birthDate == null
                ? null
                : Timestamp.fromDate(birthDate),
            gender: gender?.isNotEmpty == true ? gender : null,
            languageCode: trimmedLanguageCode?.isNotEmpty == true
                ? trimmedLanguageCode
                : null,
          ),
        );
      }

      // Send a verification email so the account can't be used until the
      // email is confirmed. A failure here must NOT fail sign-up (the email is
      // already created); the verification screen lets the user resend.
      if (user != null) {
        // Localize the verification email (and Firebase Auth error messages)
        // to the language the user picked during sign-up. Non-critical:
        // failures here must not block sign-up.
        if (trimmedLanguageCode?.isNotEmpty == true) {
          try {
            await _firebaseAuth.setLanguageCode(trimmedLanguageCode);
          } catch (e) {
            if (kDebugMode) {
              print('Failed to set auth language code: $e');
            }
          }
        }
        try {
          await user.sendEmailVerification(_verificationActionCodeSettings);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to send verification email: $e');
          }
        }
      }

      await _notificationService.onUserLogin(); // Save FCM token
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      return e.message ?? e.code; // Return error message or code
    } catch (e) {
      if (kDebugMode) {
        print('Unknown Auth Error: $e');
      }
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _notificationService.onUserLogout(); // Clear FCM token
    await _firebaseAuth.signOut();
  }

  /// Sends a new email-verification link to the current user.
  /// Returns `null` on success or an error message on failure.
  ///
  /// [languageCode] (e.g. 'tr', 'en') localizes the email to the requested
  /// language when provided; otherwise the previously set auth language is
  /// kept.
  Future<String?> sendEmailVerification({String? languageCode}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return 'no-user';
    }
    try {
      if (languageCode != null && languageCode.isNotEmpty) {
        await _firebaseAuth.setLanguageCode(languageCode);
      }
      await user.sendEmailVerification(_verificationActionCodeSettings);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      return e.message ?? e.code;
    } catch (e) {
      if (kDebugMode) {
        print('Unknown sendEmailVerification error: $e');
      }
      return e.toString();
    }
  }

  /// Reloads the current user and reports whether the email is now verified.
  /// When verified, forces an ID-token refresh so `idTokenChanges` (and the
  /// auth gate in `AuthWrapper`) updates immediately.
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      await user.reload();
      final verified = user.emailVerified;
      if (verified) {
        await user.getIdToken(true); // Force token refresh → stream emits
      }
      return verified;
    } catch (e) {
      if (kDebugMode) {
        print('isEmailVerified error: $e');
      }
      return false;
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  /// Permanently deletes the account and all associated data.
  ///
  /// 1. Re-authenticates with the supplied password (required by Firebase Auth
  ///    before account deletion).
  /// 2. Deletes the user's data server-side via the `deleteUserData` Cloud
  ///    Function.
  /// 3. Cleans up local data (profile image + local database).
  /// 4. Deletes the Firebase Auth account.
  ///
  /// Returns `null` on success or an error code/message on failure.
  Future<String?> deleteAccount({required String password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      return 'no-user';
    }

    try {
      // Re-authenticate so the delete is authorized (Firebase requires a
      // recent login for deleteAccount).
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete server-side user data (personal data, FCM token, community
      // content, profile images).
      await _firestore.deleteUserData();

      // Clean up local data so it cannot leak into a future sign-in.
      await ImageStorageUtils.deleteProfileImage(user.uid);
      await DatabaseService.instance.clearAll();

      // Finally delete the account itself.
      await user.delete();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException during deleteAccount: ${e.code}');
      }
      return e.code;
    } catch (e) {
      if (kDebugMode) {
        print('Unknown deleteAccount error: $e');
      }
      return e.toString();
    }
  }
}
