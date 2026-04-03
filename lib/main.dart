import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/localization/app_localization.dart';
import 'app/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'features/auth/auth_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  runApp(const DawaTimeApp());
}

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
