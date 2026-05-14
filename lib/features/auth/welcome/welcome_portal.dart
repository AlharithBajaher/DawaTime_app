import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localization.dart';
import '../../../app/theme/app_metrics.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/depth_card.dart';
// ignore: unused_import
import '../../admin/admin_login_screen.dart';

part 'welcome_portal_pages.dart';

class WelcomePortal extends StatefulWidget {
  const WelcomePortal({
    super.key,
    this.onFinished,
    this.autoFinishAfter = const Duration(milliseconds: 1700),
  });

  final VoidCallback? onFinished;
  final Duration autoFinishAfter;

  @override
  State<WelcomePortal> createState() => _WelcomePortalState();
}

class _WelcomePortalState extends State<WelcomePortal> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoFinishAfter, () {
      if (mounted) {
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const _LaunchPortalPage();
  }
}
