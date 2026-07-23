import 'package:firebase_auth/firebase_auth.dart';
import 'package:tripbook/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final NotificationService _notificationService;

  AuthService({FirebaseAuth? firebaseAuth, NotificationService? notificationService})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? NotificationService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

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
      return e.message; // Return error message
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _notificationService.onUserLogin(); // Save FCM token
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  Future<void> signOut() async {
    await _notificationService.onUserLogout(); // Clear FCM token
    await _firebaseAuth.signOut();
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }
}
