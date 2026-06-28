import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/localization/app_localization.dart';
import 'app/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'features/auth/auth_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase first — required before any Firestore/Auth call.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialise local notifications synchronously (channel setup).
  await NotificationService.init();

  // App Check and any optional services run in the background — they must
  // not block the first frame.
  _initOptionalServicesInBackground();

  runApp(const DawaTimeApp());
}

/// Runs non-critical initialisation after the first frame is drawn.
void _initOptionalServicesInBackground() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!kDebugMode) {
      try {
        await FirebaseAppCheck.instance
            .activate(
              androidProvider: AndroidProvider.playIntegrity,
              appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Non-fatal: App Check not available on this device/configuration.
      }
    }
  });
}

// =============================================================================
class DawaTimeApp extends StatefulWidget {
  const DawaTimeApp({super.key});

  @override
  State<DawaTimeApp> createState() => _DawaTimeAppState();
}

class _DawaTimeAppState extends State<DawaTimeApp> {
  final AppLocaleController _localeController = AppLocaleController();

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: _localeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.t(AppText.appName),
            theme: AppTheme.lightTheme(),
            locale: _localeController.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}
