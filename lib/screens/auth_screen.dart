import 'package:flutter/material.dart';
import 'package:tripbook/services/auth_service.dart';
import 'package:tripbook/services/connectivity_service.dart';
import 'package:tripbook/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLogin = true;
  bool _isLoading = false;
  String _email = '';
  String _password = '';

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus(); // Close keyboard

    if (isValid == true) {
      final connectivityResult = await ConnectivityService().executeWithConnectivityCheck(
        context,
        () async {
          _formKey.currentState?.save();
          setState(() {
            _isLoading = true;
          });

          String? authResult;
          if (_isLogin) {
            authResult = await _authService.signIn(
              email: _email,
              password: _password,
            );
          } else {
            authResult = await _authService.signUp(
              email: _email,
              password: _password,
            );
          }

          if (authResult != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authResult),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else {
            // Login/Signup successful, simply pop AuthScreen
            if (mounted) {
              Navigator.of(
                context,
              ).pop(); // Just pop, let AuthWrapper handle the rest
            }
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
      
      if (!connectivityResult && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResetPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    String resetEmail = _email; // Pre-fill with entered email if any

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterEmailToResetPassword),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailAddress),
              onChanged: (value) => resetEmail = value,
              controller: TextEditingController(text: resetEmail),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmail.isEmpty || !resetEmail.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.enterValidEmail)),
                );
                return;
              }
              
              await ConnectivityService().executeWithConnectivityCheck(
                context,
                () async {
                  final result = await _authService.resetPassword(email: resetEmail);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.passwordResetEmailSent)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
              );
            },
            child: Text(l10n.sendResetEmail),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _isLogin ? l10n.login : l10n.signUp,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('email'),
                      validator: (value) {
                        final trimmedValue = value?.trim();
                        if (trimmedValue == null || trimmedValue.isEmpty) {
                          return l10n.enterValidEmail;
                        }
                        final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                        if (!emailRegex.hasMatch(trimmedValue)) {
                          return l10n.enterValidEmail;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _email = value!.trim();
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.emailAddress),
                    ),
                    TextFormField(
                      key: const ValueKey('password'),
                      validator: (value) {
                        final trimmedValue = value?.trim() ?? '';
                        if (trimmedValue.isEmpty) {
                          return l10n.passwordMinLengthError;
                        }
                        if (trimmedValue.length < 8) {
                          return l10n.passwordMinLengthError;
                        }
                        if (trimmedValue.contains(' ')) {
                          return l10n.passwordWhitespaceError;
                        }
                        final passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
                        if (!passwordRegExp.hasMatch(trimmedValue)) {
                          return l10n.passwordComplexityError;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value!.trim();
                      },
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.password),
                    ),
                    if (_isLogin && !_isLoading)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showResetPasswordDialog,
                          child: Text(l10n.forgotPassword),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_isLoading) const CircularProgressIndicator(),
                    if (!_isLoading)
                      ElevatedButton(
                        onPressed: _trySubmit,
                        child: Text(_isLogin ? l10n.login : l10n.signUp),
                      ),
                    if (!_isLoading)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? l10n.createNewAccount
                              : l10n.alreadyHaveAccount,
                        ),
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
