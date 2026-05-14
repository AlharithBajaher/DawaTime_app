import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import 'account_gate_screens.dart';
import 'login/login_screen.dart';
import 'role_selection/role_selection_screen.dart';
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
  bool _guestIntroFinished = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupLoadingScreen();
        }

        if (!snapshot.hasData) {
          if (!_guestIntroFinished) {
            return WelcomePortal(
              onFinished: () {
                if (!mounted) {
                  return;
                }
                setState(() => _guestIntroFinished = true);
              },
            );
          }
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder(
          future: _authService.ensureAdminProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _StartupLoadingScreen();
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return const RoleSelectionScreen();
            }

            if (profile.needsAdminApproval) {
              return PharmacistPendingScreen(profile: profile);
            }

            if (profile.isRejected) {
              return PharmacistRejectedScreen(profile: profile);
            }

            switch (profile.role) {
              case 'patient':
                return const PatientHome();
              case 'pharmacist':
                return const PharmacistHome();
              case 'admin':
                return const AdminHome();
              default:
                return const LoginScreen();
            }
          },
        );
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF1F92CF),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/icon_app.png',
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
