import 'package:flutter/material.dart';

class AppText {
  static const appName = 'app.name';
  static const appLoading = 'app.loading';
  static const home = 'common.home';
  static const medications = 'common.medications';
  static const updates = 'common.updates';
  static const more = 'common.more';
  static const dashboard = 'common.dashboard';
  static const tasks = 'common.tasks';
  static const insights = 'common.insights';
  static const account = 'common.account';
  static const settings = 'common.settings';
  static const settingsSubtitle = 'settings.subtitle';
  static const language = 'settings.language';
  static const languageSubtitle = 'settings.languageSubtitle';
  static const arabic = 'language.arabic';
  static const english = 'language.english';
  static const newTask = 'pharmacist.newTask';
  static const saving = 'pharmacist.saving';
  static const welcomeStart = 'welcome.start';
  static const welcomeGuide = 'welcome.guide';
  static const welcomePrivacy = 'welcome.privacy';
  static const welcomeTerms = 'welcome.terms';
  static const welcomeSignIn = 'welcome.signIn';
}

class AppLocaleController extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  void updateLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }

    _locale = locale;
    notifyListeners();
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope is missing in the widget tree.');
    return scope!.notifier!;
  }
}

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      AppText.appName: '\u062F\u0648\u0627\u0621 \u062A\u0627\u064A\u0645',
      AppText.appLoading: '\u062F\u0648\u0627\u0621 \u062A\u0627\u064A\u0645',
      AppText.home: '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
      AppText.medications: '\u0627\u0644\u0623\u062F\u0648\u064A\u0629',
      AppText.updates: '\u0627\u0644\u062A\u062D\u062F\u064A\u062B\u0627\u062A',
      AppText.more: '\u0627\u0644\u0645\u0632\u064A\u062F',
      AppText.dashboard: '\u0627\u0644\u0644\u0648\u062D\u0629',
      AppText.tasks: '\u0627\u0644\u0645\u062E\u0632\u0648\u0646',
      AppText.insights:
          '\u0627\u0644\u062A\u062D\u0644\u064A\u0644\u0627\u062A',
      AppText.account: '\u0627\u0644\u062D\u0633\u0627\u0628',
      AppText.settings:
          '\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A',
      AppText.settingsSubtitle:
          '\u0627\u062E\u062A\u0631 \u0644\u063A\u0629 \u0627\u0644\u062A\u0637\u0628\u064A\u0642 \u0648\u0627\u0636\u0628\u0637 \u062A\u062C\u0631\u0628\u0629 \u062F\u0648\u0627\u0621 \u062A\u0627\u064A\u0645.',
      AppText.language:
          '\u0644\u063A\u0629 \u0627\u0644\u062A\u0637\u0628\u064A\u0642',
      AppText.languageSubtitle:
          '\u064A\u0645\u0643\u0646\u0643 \u0627\u0644\u062A\u0628\u062F\u064A\u0644 \u0628\u064A\u0646 \u0627\u0644\u0639\u0631\u0628\u064A\u0629 \u0648\u0627\u0644\u0625\u0646\u062C\u0644\u064A\u0632\u064A\u0629 \u0641\u0648\u0631\u064B\u0627.',
      AppText.arabic: '\u0627\u0644\u0639\u0631\u0628\u064A\u0629',
      AppText.english:
          '\u0627\u0644\u0625\u0646\u062C\u0644\u064A\u0632\u064A\u0629',
      AppText.newTask:
          '\u0639\u0646\u0635\u0631 \u0645\u062E\u0632\u0648\u0646 \u062C\u062F\u064A\u062F',
      AppText.saving: '\u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638',
      AppText.welcomeStart: '\u0627\u0628\u062F\u0623 \u0627\u0644\u0622\u0646',
      AppText.welcomeGuide:
          '\u062F\u0644\u064A\u0644 \u0627\u0644\u062A\u0637\u0628\u064A\u0642',
      AppText.welcomePrivacy:
          '\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629',
      AppText.welcomeTerms:
          '\u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645',
      AppText.welcomeSignIn:
          '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644 \u0623\u0648 \u0627\u0644\u062A\u0633\u062C\u064A\u0644',
    },
    'en': {
      AppText.appName: 'DawaTime',
      AppText.appLoading: 'DawaTime',
      AppText.home: 'Main',
      AppText.medications: 'Medications',
      AppText.updates: 'Updates',
      AppText.more: 'More',
      AppText.dashboard: 'Dashboard',
      AppText.tasks: 'Inventory',
      AppText.insights: 'Insights',
      AppText.account: 'Account',
      AppText.settings: 'Settings',
      AppText.settingsSubtitle:
          'Choose the app language and control how DawaTime feels.',
      AppText.language: 'App language',
      AppText.languageSubtitle: 'Switch instantly between Arabic and English.',
      AppText.arabic: 'Arabic',
      AppText.english: 'English',
      AppText.newTask: 'New inventory item',
      AppText.saving: 'Saving',
      AppText.welcomeStart: 'Start now',
      AppText.welcomeGuide: 'App guide',
      AppText.welcomePrivacy: 'Privacy policy',
      AppText.welcomeTerms: 'Terms and conditions',
      AppText.welcomeSignIn: 'Sign in or register',
    },
  };

  String t(String key) {
    final languageCode = _localizedValues.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return _localizedValues[languageCode]![key] ?? key;
  }

  static AppStrings of(BuildContext context) {
    return AppStrings(AppLocaleScope.of(context).locale);
  }
}

extension AppLocalizationX on BuildContext {
  AppLocaleController get localeController => AppLocaleScope.of(this);
  AppStrings get strings => AppStrings.of(this);
  bool get isArabic => localeController.isArabic;
  bool get isEnglish => localeController.isEnglish;

  String t(String key) => strings.t(key);
  String tr({required String ar, required String en}) => isArabic ? ar : en;
}
