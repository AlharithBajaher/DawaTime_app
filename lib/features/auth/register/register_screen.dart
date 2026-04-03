import 'package:flutter/material.dart';

import '../login/login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialMode: AuthScreenMode.register);
  }
}
