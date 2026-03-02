import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await _authService.saveUserData(
        uid: user.uid,
        name: user.email ?? "",
        email: user.email ?? "",
        role: role,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Role")),

      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ElevatedButton(
                    onPressed: () => _selectRole("patient"),
                    child: const Text("Patient"),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => _selectRole("pharmacist"),
                    child: const Text("Pharmacist"),
                  ),

                ],
              ),
      ),
    );
  }
}