import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../auth/login/login_screen.dart';
import '../auth/role_selection/role_selection_screen.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<String?>(
          future: _authService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data;

            if (role == null) {
              return const RoleSelectionScreen();
            }

            switch (role) {
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
