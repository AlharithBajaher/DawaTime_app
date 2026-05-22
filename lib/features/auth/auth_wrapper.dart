import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_user_model.dart';
import '../../data/services/auth_service.dart';
import 'account_gate_screens.dart';
import 'login/login_screen.dart';
import 'welcome/welcome_portal.dart';
import '../admin/admin_home.dart';
import '../patient/patient_home.dart';
import '../pharmacist/pharmacist_home.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _startupIntroFinished = false;
  final Set<String> _adminEnsureStarted = <String>{};
  Widget? _lastResolvedShell;

  Widget _buildHoldingGuideScreen() {
    return const WelcomePortal(autoFinishAfter: Duration(days: 1));
  }

  void _ensureAdminProfileInBackground(User user) {
    if (_adminEnsureStarted.contains(user.uid)) {
      return;
    }
    _adminEnsureStarted.add(user.uid);
    _authService.ensureAdminProfile(user).catchError((_) {
      // Keep startup resilient even if profile sync has transient failures.
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget remember(Widget shell) {
      _lastResolvedShell = shell;
      return shell;
    }

    if (!_startupIntroFinished) {
      return WelcomePortal(
        autoFinishAfter: const Duration(milliseconds: 2600),
        onFinished: () {
          if (!mounted) {
            return;
          }
          setState(() => _startupIntroFinished = true);
        },
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final liveUser = snapshot.data ?? FirebaseAuth.instance.currentUser;

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_lastResolvedShell != null) {
            return _lastResolvedShell!;
          }
          return _buildHoldingGuideScreen();
        }

        if (liveUser == null) {
          _adminEnsureStarted.clear();
          return remember(const LoginScreen());
        }

        final user = liveUser;
        _ensureAdminProfileInBackground(user);

        return StreamBuilder<AppUserModel?>(
          stream: _authService.watchUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            if (profile == null &&
                profileSnapshot.connectionState == ConnectionState.waiting) {
              return _lastResolvedShell ?? _buildHoldingGuideScreen();
            }

            if (profile == null) {
              return _lastResolvedShell ?? remember(const LoginScreen());
            }

            if (profile.needsAdminApproval) {
              return remember(PharmacistPendingScreen(profile: profile));
            }

            if (profile.isRejected) {
              return remember(PharmacistRejectedScreen(profile: profile));
            }

            switch (profile.role) {
              case 'patient':
                return remember(const PatientHome());
              case 'pharmacist':
                return remember(const PharmacistHome());
              case 'admin':
                return remember(const AdminHome());
              default:
                return remember(const LoginScreen());
            }
          },
        );
      },
    );
  }
}
