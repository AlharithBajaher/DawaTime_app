import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_localization.dart';
import '../../../app/theme/app_metrics.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/depth_card.dart';
import '../../../app/widgets/language_toggle_button.dart';
import '../../../data/models/app_user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../admin/admin_home.dart';
import '../../admin/admin_login_screen.dart';
import '../../auth/account_gate_screens.dart';
import '../../patient/patient_home.dart';
import '../../pharmacist/pharmacist_home.dart';

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

  bool get _isRegistering => _mode == AuthScreenMode.register;

  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  List<Color> get _buttonGradient => _selectedRole == 'pharmacist'
      ? const [Color(0xFF0F766E), Color(0xFF4ED0B0)]
      : const [Color(0xFF1E88E5), Color(0xFF56C1FF)];

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
              en: 'Pharmacist account created and waiting for admin approval.',
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

      if (!mounted) {
        return;
      }
      await _navigateAfterAuth(profile);
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_friendlyAuthError(error));
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _showSnackBar(
          _tr(
            ar: 'تعذر إكمال العملية بسبب قواعد Firestore الحالية.',
            en: 'Operation blocked by current Firestore rules.',
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
      if (mounted) {
        await _navigateAfterAuth(profile);
      }
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_friendlyAuthError(error));
    } catch (error) {
      _showSnackBar(
        _tr(
          ar: 'تعذر تسجيل الدخول عبر Google: $error',
          en: 'Google sign-in failed: $error',
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
          en: 'Pharmacist account is waiting for admin approval.',
        ),
      );
    } else if (profile.isRejected) {
      _showSnackBar(
        _tr(
          ar: 'حساب الصيدلي غير معتمد حالياً.',
          en: 'Pharmacist account is not approved right now.',
        ),
      );
    }
  }

  Future<void> _navigateAfterAuth(AppUserModel profile) async {
    if (!mounted) {
      return;
    }

    late final Widget target;
    if (profile.needsAdminApproval) {
      target = PharmacistPendingScreen(profile: profile);
    } else if (profile.isRejected) {
      target = PharmacistRejectedScreen(profile: profile);
    } else {
      switch (profile.role) {
        case 'patient':
          target = const PatientHome();
          break;
        case 'pharmacist':
          target = const PharmacistHome();
          break;
        case 'admin':
          target = const AdminHome();
          break;
        default:
          return;
      }
    }

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return _tr(
          ar: 'بيانات الدخول غير صحيحة.',
          en: 'Invalid login credentials.',
        );
      case 'email-already-in-use':
        return _tr(
          ar: 'هذا البريد مستخدم بالفعل.',
          en: 'This email is already in use.',
        );
      case 'weak-password':
        return _tr(
          ar: 'كلمة المرور ضعيفة. استخدم 6 أحرف أو أكثر.',
          en: 'Weak password. Use at least 6 characters.',
        );
      case 'network-request-failed':
        return _tr(
          ar: 'لا يوجد اتصال كافٍ بالإنترنت حالياً.',
          en: 'No stable internet connection right now.',
        );
      default:
        return error.message ??
            _tr(ar: 'حدث خطأ غير متوقع.', en: 'An unexpected error occurred.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForgotPasswordSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(
        authService: _authService,
        initialEmail: _emailController.text.trim(),
      ),
    );
  }

  String _roleName() =>
      _selectedRole == 'pharmacist'
      ? _tr(ar: 'صيدلي', en: 'pharmacist')
      : _tr(ar: 'مريض', en: 'patient');

  Widget _buildFormCard() {
    return DepthCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRegistering
                  ? _tr(ar: 'إنشاء حساب جديد', en: 'Create account')
                  : _tr(ar: 'تسجيل الدخول', en: 'Sign in'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isRegistering
                  ? _tr(
                      ar: 'أنشئ حسابك بسهولة وابدأ رحلتك معنا',
                      en: 'Create your account and start with us',
                    )
                  : _tr(
                      ar: 'أهلاً بعودتك! الرجاء إدخال بياناتك',
                      en: 'Welcome back! Enter your credentials',
                    ),
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _InlineRolePicker(
              selectedRole: _selectedRole,
              onChanged: (value) {
                setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 14),
            if (_isRegistering) ...[
              _AuthField(
                controller: _nameController,
                label: _tr(ar: 'الاسم الكامل', en: 'Full name'),
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return _tr(ar: 'أدخل الاسم الكامل.', en: 'Enter full name.');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _AuthField(
                controller: _usernameController,
                label: _tr(ar: 'اسم المستخدم', en: 'Username'),
                icon: Icons.alternate_email_outlined,
                validator: (value) {
                  final normalized = _authService.normalizeUsername(value ?? '');
                  if (normalized.length < 4) {
                    return _tr(
                      ar: 'الحد الأدنى 4 أحرف أو أرقام.',
                      en: 'Minimum 4 letters or numbers.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            _AuthField(
              controller: _emailController,
              label: _tr(ar: 'البريد الإلكتروني', en: 'Email address'),
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty || !value.contains('@')) {
                  return _tr(ar: 'أدخل بريدًا صالحًا.', en: 'Enter a valid email.');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _passwordController,
              label: _tr(ar: 'كلمة المرور', en: 'Password'),
              obscureText: _obscurePassword,
              toggle: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _tr(ar: 'أدخل كلمة المرور.', en: 'Enter password.');
                }
                if (_isRegistering && value.length < 6) {
                  return _tr(
                    ar: '6 أحرف على الأقل.',
                    en: 'At least 6 characters.',
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
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirmPasswordController,
                label: _tr(ar: 'تأكيد كلمة المرور', en: 'Confirm password'),
                obscureText: _obscureConfirmPassword,
                toggle: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                validator: (value) {
                  if (value != _passwordController.text) {
                    return _tr(ar: 'كلمتا المرور غير متطابقتين.', en: 'Passwords do not match.');
                  }
                  return null;
                },
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (!_isRegistering) ...[
              const SizedBox(height: 8),
              Align(
                alignment: context.isArabic
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _openForgotPasswordSheet,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: Text(_tr(ar: 'نسيت كلمة المرور؟', en: 'Forgot password?')),
                ),
              ),
            ],
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _buttonGradient.first.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isLoading
                      ? _tr(ar: 'جارٍ التنفيذ...', en: 'Working...')
                      : _isRegistering
                      ? _tr(ar: 'إنشاء حساب ${_roleName()}', en: 'Create ${_roleName()} account')
                      : _tr(ar: 'تسجيل الدخول', en: 'Sign in'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(
                              initialMode: _isRegistering
                                  ? AuthScreenMode.signIn
                                  : AuthScreenMode.register,
                            ),
                          ),
                        );
                      },
                child: Text(
                  _isRegistering
                      ? _tr(
                          ar: 'لديك حساب بالفعل؟ سجل الدخول',
                          en: 'Already have an account? Sign in',
                        )
                      : _tr(
                          ar: 'ليس لديك حساب؟ إنشاء حساب جديد',
                          en: 'No account? Create one',
                        ),
                ),
              ),
            ),
            _DividerLabel(label: _tr(ar: 'أو باستخدام', en: 'Or continue with')),
            const SizedBox(height: 12),
            _GoogleButton(
              isLoading: _isGoogleLoading,
              onPressed: _continueWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF2FF), Color(0xFFD9E9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (_isRegistering)
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(
                                    initialMode: AuthScreenMode.signIn,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        const AppLanguageToggleButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: _isRegistering
                              ? const [Color(0xFF3EA1FF), Color(0xFF66BEFF)]
                              : const [Color(0xFFF4FAFF), Color(0xFFE6F2FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Column(
                        children: [
                          if (_isRegistering)
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppPalette.patientPrimary,
                                size: 46,
                              ),
                            )
                          else
                            const Icon(
                              Icons.shield_rounded,
                              size: 84,
                              color: AppPalette.patientPrimary,
                            ),
                          const SizedBox(height: 10),
                          Text(
                            _isRegistering
                                ? _tr(ar: 'إنشاء حساب جديد', en: 'Create account')
                                : _tr(ar: 'مرحبًا بك', en: 'Welcome'),
                            style: TextStyle(
                              color: _isRegistering
                                  ? Colors.white
                                  : const Color(0xFF16385E),
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isRegistering
                                ? _tr(
                                    ar: 'أنشئ حسابك بسهولة وابدأ رحلتك معنا',
                                    en: 'Create your account and start with us',
                                  )
                                : _tr(
                                    ar: 'سجّل دخولك واستكشف حسابك',
                                    en: 'Sign in and continue',
                                  ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isRegistering
                                  ? Colors.white.withValues(alpha: 0.94)
                                  : const Color(0xFF567296),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFormCard(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DepthCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminLoginScreen(),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.apartment_rounded,
                                  color: AppPalette.patientPrimary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _tr(ar: 'وصول الإدارة', en: 'Admin access'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppPalette.text,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: DepthCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.support_agent_rounded,
                                  color: AppPalette.patientPrimary,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'التواصل بالإدارة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppPalette.text,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.authService,
    required this.initialEmail,
  });

  final AuthService authService;
  final String initialEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  final TextEditingController _codeController = TextEditingController();
  bool _isRequesting = false;
  bool _isSending = false;

  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar(
        _tr(ar: 'أدخل بريدًا إلكترونيًا صالحًا أولًا.', en: 'Enter a valid email first.'),
      );
      return;
    }

    setState(() => _isRequesting = true);
    try {
      await widget.authService.submitPasswordResetRequest(email: email);
      _showSnackBar(
        _tr(
          ar: 'تم إرسال طلبك للإدارة. بعد استلام رمز الوصول أدخله بالأسفل.',
          en: 'Request sent to admin. Enter access code when received.',
        ),
      );
    } catch (error) {
      _showSnackBar(
        _tr(
          ar: 'تعذر إرسال الطلب: $error',
          en: 'Could not submit request: $error',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || !email.contains('@') || code.length < 4) {
      _showSnackBar(
        _tr(ar: 'أدخل البريد والرمز بشكل صحيح.', en: 'Enter email and code correctly.'),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await widget.authService.sendPasswordResetEmailViaCode(
        email: email,
        accessCode: code,
      );
      _showSnackBar(
        _tr(
          ar: 'تم التحقق من الرمز وإرسال رابط إعادة التعيين لبريدك.',
          en: 'Code verified and reset link sent to your email.',
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      _showSnackBar(
        _tr(
          ar: 'تعذر إرسال رابط إعادة التعيين: $error',
          en: 'Could not send reset link: $error',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _isRequesting || _isSending;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DepthCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(ar: 'استعادة كلمة المرور', en: 'Reset password'),
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _tr(
                    ar: '1) اطلب رمز الوصول. 2) أدخل الرمز لإرسال رابط إعادة التعيين.',
                    en: '1) Request access code. 2) Enter code to send reset link.',
                  ),
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _tr(ar: 'البريد الإلكتروني', en: 'Email address'),
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: _tr(ar: 'رمز الوصول من الإدارة', en: 'Admin access code'),
                    prefixIcon: const Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : _requestCode,
                        icon: const Icon(Icons.campaign_rounded, size: 18),
                        label: Text(_tr(ar: 'طلب رمز', en: 'Request code')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _sendResetEmail,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          loading
                              ? _tr(ar: 'جارٍ التنفيذ...', en: 'Please wait...')
                              : _tr(ar: 'إرسال الرابط', en: 'Send link'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            label: context.tr(ar: 'مريض', en: 'Patient'),
            icon: Icons.favorite_outline_rounded,
            selected: selectedRole == 'patient',
            onTap: () => onChanged('patient'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleChip(
            label: context.tr(ar: 'صيدلي', en: 'Pharmacist'),
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
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? AppPalette.patientPrimary.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppPalette.patientPrimary.withValues(alpha: 0.20)
              : const Color(0xFFE0E8F5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? AppPalette.patientPrimary : AppPalette.muted,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppPalette.patientPrimary : AppPalette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
            width: 24,
            height: 24,
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
          const SizedBox(width: 10),
          Text(
            isLoading
                ? context.tr(ar: 'جارٍ الاتصال بـ Google...', en: 'Connecting to Google...')
                : context.tr(ar: 'تسجيل الدخول باستخدام Google', en: 'Continue with Google'),
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
