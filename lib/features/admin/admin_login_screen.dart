import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInAdmin(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              ar: 'تم فتح لوحة الإدارة بنجاح.',
              en: 'The admin dashboard is now unlocked.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                ar: 'تعذر تسجيل دخول الإدارة. تأكد من اسم المستخدم أو البريد وكلمة المرور وصلاحية الحساب الإداري.',
                en: 'Admin sign-in failed. Check the username or email, password, and that this account has the admin role.',
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF2F0FF), Color(0xFFE7E2FF), Color(0xFFFBFAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.pagePaddingWide,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: DepthCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.94),
                      Colors.white.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderColor: Colors.white.withValues(alpha: 0.64),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppPalette.adminPrimary,
                                    Color(0xFF8E84FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tr(ar: 'وصول الإدارة', en: 'Admin access'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    _tr(
                                      ar: 'هذه الصفحة مخصصة للحساب الإداري فقط.',
                                      en: 'This page is restricted to the administrator account only.',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppPalette.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _identifierController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: _tr(
                              ar: 'اسم المستخدم أو البريد الإداري',
                              en: 'Admin username or email',
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _tr(
                                ar: 'أدخل اسم المستخدم أو البريد الإداري.',
                                en: 'Enter the admin username or email.',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: _tr(ar: 'كلمة المرور', en: 'Password'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _tr(
                                ar: 'أدخل كلمة المرور.',
                                en: 'Enter the password.',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: const Icon(Icons.lock_open_rounded),
                          label: Text(
                            _isLoading
                                ? _tr(ar: 'جارٍ التحقق...', en: 'Verifying...')
                                : _tr(
                                    ar: 'فتح لوحة الإدارة',
                                    en: 'Open admin dashboard',
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).maybePop();
                                },
                          child: Text(_tr(ar: 'العودة', en: 'Back')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
