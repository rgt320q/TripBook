import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/services/auth_service.dart';

/// Shown right after sign-up (and on every sign-in until the email is
/// verified). Blocks access to the app until [AuthService.isEmailVerified]
/// reports true, at which point the auth gate in `AuthWrapper` switches to the
/// main app automatically.
///
/// The screen auto-checks the verification status on mount and then polls
/// every few seconds. This makes the gate self-healing: if the account is
/// already verified but the app was holding a stale ID token (issued before
/// the verification), the reload + forced token refresh in
/// [AuthService.isEmailVerified] detects it and the gate flips to the main app
/// without any manual step. It also auto-advances when the user confirms the
/// email in another tab/browser while this screen is open.
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  static const int _resendCooldownSeconds = 30;
  static const Duration _pollInterval = Duration(seconds: 5);

  bool _isChecking = false;
  bool _isSending = false;
  int _resendSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Resolve the stale-token case immediately on mount, then keep polling so
    // verifying in another tab/browser auto-advances the gate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerification(silent: true);
    });
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _checkVerification(silent: true);
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _resendSeconds = _resendCooldownSeconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendSeconds = 0;
        });
      } else {
        setState(() {
          _resendSeconds -= 1;
        });
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        backgroundColor:
            isError ? colorScheme.error : colorScheme.inverseSurface,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isChecking) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isChecking = true;
    });
    try {
      final verified = await _authService.isEmailVerified();
      if (!mounted) return;
      if (verified) {
        _showMessage(l10n.emailVerifiedSuccess);
        // The auth gate switches to the main app via idTokenChanges.
      } else if (!silent) {
        _showMessage(l10n.notVerifiedYet, isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        _showMessage(l10n.verificationCheckError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_isSending || _resendSeconds > 0) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSending = true;
    });

    // Skip the connectivity pre-check here: on web `checkConnectivity()` can
    // wrongly report "offline", which would (a) show a spurious red toast and
    // (b) cause this method to claim success without ever sending. The auth
    // service already catches send failures and returns an error message.
    final authResult = await _authService.sendEmailVerification(
      languageCode: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
    });

    if (authResult == null) {
      _showMessage(l10n.verificationEmailSent);
      _startCooldown();
    } else {
      _showMessage(l10n.verificationResendError, isError: true);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isSending = true;
    });
    await _authService.signOut();
    // AuthWrapper listens to the auth stream and will show the login screen.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = _isChecking || _isSending;
    final resendDisabled = isBusy || _resendSeconds > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.verifyEmailTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.verifyEmailMessage(widget.email),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkVerification,
                        child: _isChecking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l10n.iHaveVerified,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: resendDisabled ? null : _resend,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _resendSeconds > 0
                              ? l10n.resendCountdown(_resendSeconds)
                              : l10n.resendVerificationEmail,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isSending ? null : _signOut,
                      child: Text(l10n.logout),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
