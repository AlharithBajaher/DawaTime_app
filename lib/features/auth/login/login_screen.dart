import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localization.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/depth_card.dart';
import '../../../data/models/app_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../admin/admin_login_screen.dart';
import 'auth_ui.dart';

enum AuthScreenMode { signIn, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMode = AuthScreenMode.signIn});

  final AuthScreenMode initialMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AuthScreenMode _mode;
  String _selectedRole = 'patient';
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isRegistering => _mode == AuthScreenMode.register;

  RoleVisualConfig _roleConfig(BuildContext context) =>
      _selectedRole == 'pharmacist'
      ? RoleVisualConfig.pharmacist(context)
      : RoleVisualConfig.patient(context);

  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      late final AppUserModel profile;
      if (_isRegistering) {
        profile = await _authService.registerWithEmail(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );

        if (profile.needsAdminApproval && mounted) {
          _showSnackBar(
            _tr(
              ar: 'تم إنشاء حساب الصيدلي بنجاح، وهو الآن بانتظار موافقة الإدارة.',
              en: 'The pharmacist account was created successfully and is now waiting for admin approval.',
            ),
          );
        }
      } else {
        profile = await _authService.signInWithEmailAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fallbackRole: _selectedRole,
        );
        _handleRoleState(profile);
      }
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_friendlyAuthError(error));
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _showSnackBar(
          _tr(
            ar: 'قواعد Firestore الحالية تمنع حفظ الحساب. حدّث قواعد مجموعة users ثم أعد المحاولة.',
            en: 'The current Firestore rules are blocking account creation. Update the users collection rules and try again.',
          ),
        );
      } else {
        _showSnackBar(
          error.message ??
              _tr(
                ar: 'تعذر إكمال العملية الآن.',
                en: 'Unable to complete the action right now.',
              ),
        );
      }
    } catch (error) {
      _showSnackBar(
        _tr(
          ar: 'تعذر إكمال العملية الآن: $error',
          en: 'Unable to complete the action right now: $error',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final profile = await _authService.signInWithGoogle(
        selectedRole: _selectedRole,
      );
      _handleRoleState(profile);
    } on PlatformException catch (error) {
      _showSnackBar(_friendlyPlatformError(error));
    } on FirebaseAuthException catch (error) {
      if (error.code == 'aborted-by-user') {
        _showSnackBar(
          _tr(
            ar: 'تم إلغاء تسجيل الدخول عبر Google.',
            en: 'Google sign-in was cancelled.',
          ),
        );
      } else {
        _showSnackBar(_friendlyAuthError(error));
      }
    } catch (error) {
      _showSnackBar(
        _tr(
          ar: 'تعذر إكمال تسجيل الدخول عبر Google: $error',
          en: 'Unable to finish Google sign-in: $error',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _handleRoleState(AppUserModel profile) {
    if (profile.needsAdminApproval) {
      _showSnackBar(
        _tr(
          ar: 'حساب الصيدلي بانتظار موافقة الإدارة.',
          en: 'The pharmacist account is waiting for admin approval.',
        ),
      );
    } else if (profile.isRejected) {
      _showSnackBar(
        _tr(
          ar: 'هذا الحساب الصيدلي غير معتمد حالياً.',
          en: 'This pharmacist account is not approved right now.',
        ),
      );
    } else if (!_isRegistering && profile.role != _selectedRole) {
      final resolvedRole = profile.role == 'pharmacist'
          ? _tr(ar: 'الصيدلي', en: 'pharmacist')
          : _tr(ar: 'المريض', en: 'patient');
      _showSnackBar(
        _tr(
          ar: 'تم فتح الحساب وفق بياناته المحفوظة كواجهة $resolvedRole.',
          en: 'The account was opened using its saved role as a $resolvedRole view.',
        ),
      );
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return _tr(
          ar: 'بيانات الدخول غير صحيحة. تحقق من البريد وكلمة المرور.',
          en: 'Your sign-in details are incorrect. Check the email and password.',
        );
      case 'email-already-in-use':
        return _tr(
          ar: 'هذا البريد مستخدم بالفعل. استخدم تسجيل الدخول بدلاً من إنشاء حساب جديد.',
          en: 'This email is already in use. Sign in instead of creating a new account.',
        );
      case 'weak-password':
        return _tr(
          ar: 'كلمة المرور ضعيفة. استخدم 6 أحرف أو أكثر.',
          en: 'The password is too weak. Use at least 6 characters.',
        );
      case 'invalid-email':
        return _tr(
          ar: 'صيغة البريد الإلكتروني غير صحيحة.',
          en: 'The email format is invalid.',
        );
      case 'network-request-failed':
        return _tr(
          ar: 'لا يوجد اتصال كافٍ بالشبكة حالياً.',
          en: 'There is not enough network connectivity right now.',
        );
      case 'username-taken':
        return error.message ??
            _tr(
              ar: 'اسم المستخدم مستخدم بالفعل.',
              en: 'This username is already taken.',
            );
      case 'popup-closed-by-user':
        return _tr(
          ar: 'تم إغلاق نافذة Google قبل إكمال الدخول.',
          en: 'The Google window was closed before sign-in was completed.',
        );
      default:
        return error.message ??
            _tr(ar: 'حدث خطأ غير متوقع.', en: 'An unexpected error occurred.');
    }
  }

  String _friendlyPlatformError(PlatformException error) {
    if (error.message?.contains('google_sign_in_android') == true ||
        error.code.contains('channel-error')) {
      return _tr(
        ar: 'تعذر تشغيل تسجيل Google على هذا الجهاز الآن. تأكد من تشغيل التطبيق بعد إيقافه بالكامل، واستخدم محاكي Android يحتوي على Google Play، وتحقق من SHA-1 في Firebase.',
        en: 'Google sign-in could not start on this device right now. Restart the app fully, use an Android emulator with Google Play, and verify the SHA-1 fingerprint in Firebase.',
      );
    }

    return error.message ??
        _tr(
          ar: 'حدث خطأ تقني غير متوقع.',
          en: 'An unexpected technical error occurred.',
        );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAuthCard(ThemeData theme, RoleVisualConfig roleConfig) {
    return DepthCard(
      padding: const EdgeInsets.all(24),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.82),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Colors.white.withValues(alpha: 0.68),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: roleConfig.buttonGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    _isRegistering
                        ? Icons.person_add_alt_1_rounded
                        : Icons.login_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRegistering
                            ? _tr(
                                ar: 'أنشئ حساباً منظماً',
                                en: 'Create a well-organized account',
                              )
                            : _tr(
                                ar: 'ادخل إلى حسابك',
                                en: 'Sign in to your account',
                              ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRegistering
                            ? _tr(
                                ar: 'اختيار المريض أو الصيدلي يتم هنا فقط أثناء إنشاء الحساب أو عند أول تسجيل عبر Google.',
                                en: 'Choosing patient or pharmacist only happens during account creation or the first Google sign-in.',
                              )
                            : _tr(
                                ar: 'إذا كان الحساب موجوداً من قبل فسيتم توجيهك حسب بياناته المحفوظة ووفق اعتماد الإدارة.',
                                en: 'If the account already exists, you will be routed based on the saved profile and approval state.',
                              ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            AuthModeTabs(
              isRegistering: _isRegistering,
              onChanged: (isRegistering) {
                setState(() {
                  _mode = isRegistering
                      ? AuthScreenMode.register
                      : AuthScreenMode.signIn;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              _tr(ar: 'نوع الحساب الجديد', en: 'New account type'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _InlineRolePicker(
              selectedRole: _selectedRole,
              onChanged: (value) {
                setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 18),
            if (_isRegistering) ...[
              _AuthField(
                controller: _nameController,
                label: _tr(ar: 'الاسم الكامل', en: 'Full name'),
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return _tr(
                      ar: 'أدخل اسماً واضحاً.',
                      en: 'Enter a clear full name.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _AuthField(
                controller: _usernameController,
                label: _tr(ar: 'اسم المستخدم', en: 'Username'),
                icon: Icons.alternate_email_outlined,
                validator: (value) {
                  final normalized = _authService.normalizeUsername(
                    value ?? '',
                  );
                  if (normalized.length < 4) {
                    return _tr(
                      ar: 'استخدم 4 أحرف أو أرقام أو _ على الأقل.',
                      en: 'Use at least 4 letters, numbers, or underscores.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],
            _AuthField(
              controller: _emailController,
              label: _tr(ar: 'البريد الإلكتروني', en: 'Email address'),
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _tr(
                    ar: 'أدخل البريد الإلكتروني.',
                    en: 'Enter your email address.',
                  );
                }
                if (!value.contains('@')) {
                  return _tr(
                    ar: 'أدخل بريداً إلكترونياً صالحاً.',
                    en: 'Enter a valid email address.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _passwordController,
              label: _tr(ar: 'كلمة المرور', en: 'Password'),
              obscureText: _obscurePassword,
              toggle: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _tr(
                    ar: 'أدخل كلمة المرور.',
                    en: 'Enter your password.',
                  );
                }
                if (_isRegistering && value.length < 6) {
                  return _tr(
                    ar: 'يجب أن تتكون من 6 أحرف على الأقل.',
                    en: 'It must be at least 6 characters long.',
                  );
                }
                return null;
              },
              onSubmitted: (_) {
                if (!_isRegistering) {
                  _submit();
                }
              },
            ),
            if (_isRegistering) ...[
              const SizedBox(height: 14),
              _PasswordField(
                controller: _confirmPasswordController,
                label: _tr(ar: 'تأكيد كلمة المرور', en: 'Confirm password'),
                obscureText: _obscureConfirmPassword,
                toggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (value) {
                  if (value != _passwordController.text) {
                    return _tr(
                      ar: 'كلمتا المرور غير متطابقتين.',
                      en: 'The passwords do not match.',
                    );
                  }
                  return null;
                },
                onSubmitted: (_) {
                  _submit();
                },
              ),
            ],
            const SizedBox(height: 18),
            _RoleStateHint(config: roleConfig),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: roleConfig.buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: roleConfig.highlightColor.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  _isLoading
                      ? _tr(ar: 'جارٍ التنفيذ...', en: 'Working...')
                      : _isRegistering
                      ? _tr(
                          ar: 'إنشاء حساب ${roleConfig.roleName}',
                          en: 'Create ${roleConfig.roleName} account',
                        )
                      : _tr(ar: 'تسجيل الدخول', en: 'Sign in'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _mode = _isRegistering
                              ? AuthScreenMode.signIn
                              : AuthScreenMode.register;
                        });
                      },
                child: Text(
                  _isRegistering
                      ? _tr(
                          ar: 'لديك حساب بالفعل؟ سجل الدخول',
                          en: 'Already have an account? Sign in',
                        )
                      : _tr(
                          ar: 'مستخدم جديد؟ أنشئ حساباً',
                          en: 'New here? Create an account',
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _DividerLabel(
              label: _isGoogleLoading
                  ? _tr(ar: 'جارٍ فتح Google', en: 'Opening Google')
                  : _tr(ar: 'أو استخدم Google', en: 'Or continue with Google'),
            ),
            const SizedBox(height: 14),
            _GoogleButton(
              isLoading: _isGoogleLoading,
              onPressed: _continueWithGoogle,
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _isLoading || _isGoogleLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text(_tr(ar: 'وصول الإدارة', en: 'Admin access')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleConfig = _roleConfig(context);
    final heroPanel = HeroPanel(
      config: roleConfig,
      selectedRole: _selectedRole,
      onRoleSelected: (role) {
        setState(() => _selectedRole = role);
      },
    );
    final authCard = _buildAuthCard(theme, roleConfig);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: roleConfig.pageGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 11, child: heroPanel),
                              const SizedBox(width: 22),
                              Expanded(flex: 9, child: authCard),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heroPanel,
                              const SizedBox(height: 22),
                              authCard,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InlineRolePicker extends StatelessWidget {
  const _InlineRolePicker({
    required this.selectedRole,
    required this.onChanged,
  });

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleChip(
            label: context.tr(ar: 'المريض', en: 'Patient'),
            icon: Icons.favorite_outline_rounded,
            selected: selectedRole == 'patient',
            onTap: () => onChanged('patient'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleChip(
            label: context.tr(ar: 'الصيدلي', en: 'Pharmacist'),
            icon: Icons.local_pharmacy_outlined,
            selected: selectedRole == 'pharmacist',
            onTap: () => onChanged('pharmacist'),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? AppPalette.patientPrimary.withValues(alpha: 0.10)
            : const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppPalette.patientPrimary.withValues(alpha: 0.18)
              : const Color(0xFFDDE6F6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppPalette.patientPrimary
                      : AppPalette.muted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppPalette.patientPrimary
                        : AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleStateHint extends StatelessWidget {
  const _RoleStateHint({required this.config});

  final RoleVisualConfig config;

  @override
  Widget build(BuildContext context) {
    final extra = config.roleKey == 'pharmacist'
        ? context.tr(
            ar: 'حساب الصيدلي يُسجل مباشرة لكنه يبقى بانتظار اعتماد الإدارة قبل الدخول.',
            en: 'The pharmacist account is created right away, but it stays pending admin approval before access.',
          )
        : context.tr(
            ar: 'حساب المريض يدخل مباشرة بعد الإنشاء أو تسجيل الدخول.',
            en: 'The patient account signs in directly after registration or login.',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.highlightColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, color: config.highlightColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$extra\n${config.roleDescription}',
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF44336),
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isLoading
                ? context.tr(
                    ar: 'جارٍ الاتصال بـ Google...',
                    en: 'Connecting to Google...',
                  )
                : context.tr(
                    ar: 'المتابعة بحساب Google',
                    en: 'Continue with Google',
                  ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.toggle,
    required this.validator,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback toggle;
  final String? Function(String?) validator;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: validator,
    );
  }
}
