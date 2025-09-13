
import 'package:flutter/material.dart';
import 'package:tripbook/services/auth_service.dart';


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
      _formKey.currentState?.save();
      setState(() {
        _isLoading = true;
      });

      String? authResult;
      if (_isLogin) {
        authResult = await _authService.signIn(email: _email, password: _password);
      } else {
        authResult = await _authService.signUp(email: _email, password: _password);
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
          Navigator.of(context).pop(); // Just pop, let AuthWrapper handle the rest
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('email'),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return l10n.enterValidEmail;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _email = value!;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.emailAddress,
                      ),
                    ),
                    TextFormField(
                      key: const ValueKey('password'),
                      validator: (value) {
                        if (value == null || value.length < 7) {
                          return l10n.passwordTooShort;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value!;
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const CircularProgressIndicator(),
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
                        child: Text(_isLogin
                            ? l10n.createNewAccount
                            : l10n.alreadyHaveAccount),
                      )
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
