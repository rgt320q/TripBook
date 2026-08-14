import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/services/auth_service.dart';
import 'package:tripbook/services/connectivity_service.dart';

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
  String _fullName = '';
  String _nickname = '';
  DateTime? _birthDate;
  String? _gender;
  String? _languageCode;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus(); // Close keyboard

    if (isValid == true) {
      final connectivityResult = await ConnectivityService()
          .executeWithConnectivityCheck(context, () async {
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
                fullName: _fullName,
                nickname: _nickname,
                birthDate: _birthDate,
                gender: _gender,
                languageCode: _languageCode,
              );
            }

            if (authResult != null) {
              if (kDebugMode) {
                print('Auth Error Message: $authResult');
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authResult),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            } else {
              // Login/Signup successful.
              // No need to Navigator.pop() here as AuthWrapper handles the transition
              // automatically by listening to authStateChanges.
              // Make sure every subsequent screen (email verification, toasts,
              // the main app) uses the language the user picked during sign-up.
              if (mounted && !_isLogin && _languageCode != null) {
                Provider.of<LocaleProvider>(context, listen: false)
                    .setLocale(Locale(_languageCode!));
              }
            }

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });

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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.enterValidEmail)));
                return;
              }

              await ConnectivityService().executeWithConnectivityCheck(
                context,
                () async {
                  final result = await _authService.resetPassword(
                    email: resetEmail,
                  );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pre-select the browser/system language (the auth screen follows the
    // user's locale) so the mandatory language field has a sensible default.
    _languageCode ??= Localizations.localeOf(context).languageCode;
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _isLogin ? l10n.login : l10n.signUp,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isLogin) ...[
                        _buildSectionHeader(l10n.accountInfo),
                        const SizedBox(height: 12),
                        _buildTextField(
                          key: const ValueKey('fullName'),
                          label: '${l10n.fullNameLabel} *',
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: (value) {
                            final trimmedValue = value?.trim() ?? '';
                            if (trimmedValue.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (trimmedValue.length < 2) {
                              return l10n.fullNameMinLengthError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _fullName = value!.trim();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          key: const ValueKey('nickname'),
                          label: '${l10n.nicknameLabel} *',
                          icon: Icons.alternate_email,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          validator: (value) {
                            final trimmedValue = value?.trim() ?? '';
                            if (trimmedValue.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (trimmedValue.length < 3) {
                              return l10n.nicknameMinLengthError;
                            }
                            final nicknameRegExp = RegExp(
                              r'^[\p{L}\p{N}._]+$',
                              unicode: true,
                            );
                            if (!nicknameRegExp.hasMatch(trimmedValue)) {
                              return l10n.nicknameInvalidCharsError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _nickname = value!.trim();
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('language'),
                          initialValue: _languageCode,
                          decoration: _inputDecoration(
                            label: '${l10n.language} *',
                            icon: Icons.language,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'tr',
                              child: Text(l10n.languageTurkish),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.languageEnglish),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _languageCode = value;
                            });
                            // Apply the chosen language immediately so every
                            // in-app screen (and the verification flow that
                            // follows) matches the user's selection.
                            if (value != null) {
                              Provider.of<LocaleProvider>(context, listen: false)
                                  .setLocale(Locale(value));
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        key: const ValueKey('email'),
                        label: '${l10n.emailAddress} *',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          final trimmedValue = value?.trim();
                          if (trimmedValue == null || trimmedValue.isEmpty) {
                            return l10n.enterValidEmail;
                          }
                          final emailRegex = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          );
                          if (!emailRegex.hasMatch(trimmedValue)) {
                            return l10n.enterValidEmail;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value!.trim();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('password'),
                        controller: _passwordController,
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
                          final passwordRegExp = RegExp(
                            r'^(?=.*[A-Za-z])(?=.*\d).{8,}$',
                          );
                          if (!passwordRegExp.hasMatch(trimmedValue)) {
                            return l10n.passwordComplexityError;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!.trim();
                        },
                        obscureText: _obscurePassword,
                        textInputAction: _isLogin
                            ? TextInputAction.done
                            : TextInputAction.next,
                        autofillHints: [
                          _isLogin
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        decoration: _inputDecoration(
                          label: '${l10n.password} *',
                          icon: Icons.lock_outline,
                          suffixIcon: _buildPasswordVisibilityButton(
                            obscure: _obscurePassword,
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('confirmPassword'),
                          controller: _confirmPasswordController,
                          validator: (value) {
                            final trimmedValue = value?.trim() ?? '';
                            if (trimmedValue.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (trimmedValue !=
                                _passwordController.text.trim()) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: _inputDecoration(
                            label: '${l10n.confirmPassword} *',
                            icon: Icons.verified_user_outlined,
                            suffixIcon: _buildPasswordVisibilityButton(
                              obscure: _obscureConfirmPassword,
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                      if (_isLogin && !_isLoading)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showResetPasswordDialog,
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        _buildSectionHeader(l10n.optionalInfo),
                        const SizedBox(height: 12),
                        _buildDateField(l10n),
                        const SizedBox(height: 16),
                        _buildGenderField(l10n),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.requiredFieldsNote,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _trySubmit,
                            child: Text(
                              _isLogin ? l10n.login : l10n.signUp,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildTextField({
    Key? key,
    required String label,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<String>? autofillHints,
  }) {
    return TextFormField(
      key: key,
      validator: validator,
      onSaved: onSaved,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Widget _buildPasswordVisibilityButton({
    required bool obscure,
    required VoidCallback onPressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      tooltip: obscure ? l10n.showPassword : l10n.hidePassword,
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
      initialValue: _gender,
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
}
