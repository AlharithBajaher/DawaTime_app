part of 'welcome_portal.dart';

class _LaunchPortalPage extends StatelessWidget {
  const _LaunchPortalPage({required this.onOpenDetailsPage});

  final Future<void> Function(Widget page) onOpenDetailsPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFDDEAFF),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: -95,
                top: -95,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC8E0FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -105,
                bottom: -105,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC7EDEF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: AppSpacing.pagePaddingWide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 208,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 26,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2E6EA6,
                                ).withValues(alpha: 0.14),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/icon_app.png',
                                width: 76,
                                height: 76,
                                filterQuality: FilterQuality.high,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppPalette.patientPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.t(AppText.appName),
                                style: const TextStyle(
                                  color: Color(0xFF1A2D4A),
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 34),
                        DepthCard(
                          onTap: () {
                            onOpenDetailsPage(const _GuidePage());
                          },
                          child: Center(
                            child: Text(
                              context.t(AppText.welcomeGuide),
                              style: const TextStyle(
                                color: AppPalette.patientPrimary,
                                fontSize: AppFontSize.pageTitle,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                onOpenDetailsPage(const _PrivacyPage());
                              },
                              child: Text(
                                context.t(AppText.welcomePrivacy),
                                style: const TextStyle(
                                  color: Color(0xFF3B5D82),
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFontSize.bodyLarge,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '|',
                              style: TextStyle(
                                color: const Color(
                                  0xFF3B5D82,
                                ).withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                                fontSize: AppFontSize.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            InkWell(
                              onTap: () {
                                onOpenDetailsPage(const _TermsPage());
                              },
                              child: Text(
                                context.t(AppText.welcomeTerms),
                                style: const TextStyle(
                                  color: Color(0xFF3B5D82),
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFontSize.bodyLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  const _GuidePage();

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      title: context.t(AppText.welcomeGuide),
      sections: [
        _PageSection(
          title: context.tr(ar: 'طريقة البدء', en: 'How to start'),
          body: context.tr(
            ar:
                'من شاشة الدخول يمكنك تسجيل الدخول مباشرة أو إنشاء حساب جديد. بعد تسجيل الدخول سيتم توجيهك تلقائيًا حسب نوع الحساب.',
            en:
                'From the login screen you can sign in directly or create a new account. After sign-in, you are routed automatically based on your account role.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'واجهة المريض', en: 'Patient view'),
          body: context.tr(
            ar:
                'يمكنك إضافة الأدوية، متابعة الجرعات اليومية، تنفيذ التناول أو التأجيل أو التخطي، ومراجعة التقارير بدقة.',
            en:
                'You can add medicines, track daily doses, mark taken/snoozed/skipped actions, and review accurate reports.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'واجهة الصيدلي', en: 'Pharmacist view'),
          body: context.tr(
            ar:
                'يمكنك نشر الأدوية للمرضى وإدارة المخزون بشكل احترافي مع متابعة التوفر والكميات والتنبيهات.',
            en:
                'You can publish medicines for patients and manage stock professionally with quantity and availability tracking.',
          ),
        ),
      ],
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      title: context.t(AppText.welcomePrivacy),
      sections: [
        _PageSection(
          title: context.tr(ar: 'البيانات', en: 'Data'),
          body: context.tr(
            ar:
                'يتم حفظ بيانات الحساب والأدوية داخل Firebase مع قواعد وصول تمنع أي مستخدم من الوصول إلى بيانات مستخدم آخر.',
            en:
                'Account and medication data are stored in Firebase with access rules that prevent cross-user data access.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'الإشعارات', en: 'Notifications'),
          body: context.tr(
            ar:
                'تُستخدم الإشعارات فقط لتذكير الجرعات وتنبيهات المخزون ولا يتم بيع بياناتك أو مشاركتها مع أي جهة خارجية.',
            en:
                'Notifications are used only for dose reminders and stock alerts. Your data is not sold or shared with external parties.',
          ),
        ),
      ],
    );
  }
}

class _TermsPage extends StatelessWidget {
  const _TermsPage();

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      title: context.t(AppText.welcomeTerms),
      sections: [
        _PageSection(
          title: context.tr(ar: 'الاستخدام الطبي', en: 'Medical usage'),
          body: context.tr(
            ar:
                'التطبيق أداة تنظيم وتذكير مساعدة، ولا يُعتبر بديلاً عن الاستشارة الطبية المباشرة.',
            en:
                'The app is an organizational and reminder assistant and does not replace direct medical consultation.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'المسؤولية', en: 'Responsibility'),
          body: context.tr(
            ar:
                'المستخدم مسؤول عن دقة البيانات المدخلة، والإدارة مسؤولة عن اعتماد حسابات الصيادلة ومتابعة الطلبات.',
            en:
                'Users are responsible for entered data accuracy. Admin is responsible for pharmacist approvals and request handling.',
          ),
        ),
      ],
    );
  }
}

class _ContentPage extends StatelessWidget {
  const _ContentPage({required this.title, required this.sections});

  final String title;
  final List<_PageSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        color: const Color(0xFFDDEAFF),
        child: SafeArea(
          child: ListView(
            padding: AppSpacing.pagePaddingWide,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxSheetWidth,
                  ),
                  child: DepthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppFontSize.pageTitle,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...sections.map(
                          (section) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6FAFF),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.title,
                                    style: const TextStyle(
                                      fontSize: AppFontSize.title,
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    section.body,
                                    style: const TextStyle(
                                      color: AppPalette.muted,
                                      fontSize: AppFontSize.body,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSection {
  const _PageSection({required this.title, required this.body});

  final String title;
  final String body;
}
