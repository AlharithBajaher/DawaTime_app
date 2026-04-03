import 'package:flutter/material.dart';

import '../login/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialMode: AuthScreenMode.register);
  }
}
