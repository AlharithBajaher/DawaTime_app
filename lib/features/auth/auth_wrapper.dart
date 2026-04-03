import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/services/auth_service.dart';
import 'account_gate_screens.dart';
import '../auth/login/login_screen.dart';
import '../auth/role_selection/role_selection_screen.dart';
import '../auth/welcome/welcome_portal.dart';
import '../patient/patient_home.dart';
import '../pharmacist/pharmacist_home.dart';
import '../admin/admin_home.dart';

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData) {
          return const WelcomePortal();
        }

        final user = snapshot.data!;

        return FutureBuilder(
          future: _authService.ensureAdminProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
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

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF2FF), Color(0xFFD5E5FF), Color(0xFFF7FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: _Orb(
                size: 220,
                color: AppPalette.patientAccent.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: -90,
              right: -50,
              child: _Orb(
                size: 240,
                color: AppPalette.pharmacistAccent.withValues(alpha: 0.16),
              ),
            ),
            Center(
              child: DepthCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 34,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    Colors.white.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _LogoMark(),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                    Text(
                      context.t(AppText.appLoading),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppPalette.patientPrimary, AppPalette.patientAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.patientPrimary.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.medication_liquid_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
