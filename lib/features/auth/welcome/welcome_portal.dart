import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localization.dart';
import '../../../app/theme/app_metrics.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/depth_card.dart';

part 'welcome_portal_pages.dart';

class WelcomePortal extends StatefulWidget {
  const WelcomePortal({
    super.key,
    this.onFinished,
    this.autoFinishAfter = const Duration(milliseconds: 2000),
  });

  final VoidCallback? onFinished;
  final Duration autoFinishAfter;

  @override
  State<WelcomePortal> createState() => _WelcomePortalState();
}

class _WelcomePortalState extends State<WelcomePortal> {
  Timer? _timer;
  bool _detailsOpen = false;

  @override
  void initState() {
    super.initState();
    _startTimer(widget.autoFinishAfter);
  }

  void _startTimer(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (!mounted || _detailsOpen) {
        return;
      }
      widget.onFinished?.call();
    });
  }

  Future<void> _openDetailsPage(Widget page) async {
    _detailsOpen = true;
    _timer?.cancel();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    _detailsOpen = false;
    if (mounted) {
      _startTimer(const Duration(milliseconds: 1200));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LaunchPortalPage(onOpenDetailsPage: _openDetailsPage);
  }
}
