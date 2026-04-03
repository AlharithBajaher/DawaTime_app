import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localization.dart';
import '../../../app/theme/app_metrics.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/depth_card.dart';
import '../../admin/admin_login_screen.dart';
import '../login/login_screen.dart';

part 'welcome_portal_pages.dart';

class WelcomePortal extends StatefulWidget {
  const WelcomePortal({super.key});

  @override
  State<WelcomePortal> createState() => _WelcomePortalState();
}

class _WelcomePortalState extends State<WelcomePortal> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      child: _showSplash ? const _SplashPage() : const _LandingPage(),
    );
  }
}
