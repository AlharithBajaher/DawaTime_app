part of 'welcome_portal.dart';

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF238CCB)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medication_liquid_rounded,
                size: 86,
                color: Colors.white,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.t(AppText.appName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.hero,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingPage extends StatelessWidget {
  const _LandingPage();

  @override
  Widget build(BuildContext context) {
    final heroCard = DepthCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppSpacing.pagePaddingWide,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF59C1F8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: const _LandingHero(),
          ),
          Padding(
            padding: AppSpacing.pagePaddingWide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    ar: 'منصة دواء منظمة للمريض والصيدلي',
                    en: 'A medication platform built for patients and pharmacists',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.pageTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr(
                    ar: 'إدارة الأدوية، تنبيهات الجرعات، متابعة الحسابات، واعتماد الصيادلة داخل تطبيق واحد مبني على Flutter وFirebase بشكل جاهز للويب والموبايل.',
                    en: 'Manage medications, dose reminders, account flows, and pharmacist approvals in one Flutter and Firebase app for web and mobile.',
                  ),
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(context.t(AppText.welcomeStart)),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const _GuidePage()),
                        );
                      },
                      child: Text(context.t(AppText.welcomeGuide)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final sideColumn = Column(
      children: [
        _SidePageCard(
          title: context.t(AppText.welcomePrivacy),
          subtitle: context.tr(
            ar: 'تعرف على طريقة حفظ بيانات المرضى والصيادلة في Firebase.',
            en: 'Learn how patient and pharmacist data is stored in Firebase.',
          ),
          icon: Icons.privacy_tip_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PrivacyPage()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SidePageCard(
          title: context.t(AppText.welcomeTerms),
          subtitle: context.tr(
            ar: 'صفحة منظمة لعرض شروط الاستخدام وحدود المسؤولية.',
            en: 'A clear page that outlines terms of use and responsibility limits.',
          ),
          icon: Icons.gavel_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _TermsPage()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SidePageCard(
          title: context.t(AppText.welcomeSignIn),
          subtitle: context.tr(
            ar: 'ادخل كمريض أو قدم طلب صيدلي بانتظار اعتماد الإدارة.',
            en: 'Enter as a patient or submit a pharmacist request pending admin approval.',
          ),
          icon: Icons.login_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SidePageCard(
          title: context.tr(ar: 'وصول الإدارة', en: 'Admin access'),
          subtitle: context.tr(
            ar: 'تسجيل دخول محمي للحساب الإداري لمراجعة الحسابات والتحكم بالتطبيق.',
            en: 'Protected sign-in for the administrator account to review users and control the app.',
          ),
          icon: Icons.admin_panel_settings_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            );
          },
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F7FF), Color(0xFFDCF0FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return SingleChildScrollView(
                padding: AppSpacing.pagePaddingWide,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxWideContentWidth,
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 11, child: heroCard),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(flex: 7, child: sideColumn),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heroCard,
                              const SizedBox(height: AppSpacing.lg),
                              sideColumn,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LandingHero extends StatelessWidget {
  const _LandingHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_rounded, color: Colors.white),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 36,
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 108,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.t(AppText.appName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.hero,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr(
                    ar: 'تجربة عربية منظمة لإدارة الدواء، المتابعة، وتنسيق الوصول بين المريض والصيدلي والإدارة.',
                    en: 'A polished bilingual experience for medication management, follow-up, and coordinated access for patients, pharmacists, and admins.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.6,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePageCard extends StatelessWidget {
  const _SidePageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.patientPrimary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: AppPalette.patientPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppPalette.muted),
        ],
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
      gradientColors: const [Color(0xFF97C84A), Color(0xFFB8DE6F)],
      sections: [
        _PageSection(
          title: context.tr(
            ar: 'ابدأ من شاشة الحساب',
            en: 'Start from the account screen',
          ),
          body: context.tr(
            ar: 'اختر نوع الحساب من شاشة الدخول فقط: مريض أو صيدلي. بعد إنشاء الحساب لا يُطلب منك الاختيار مرة أخرى.',
            en: 'Choose the account type only from the sign-in screen: patient or pharmacist. After the account is created, you will not be asked again.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'المريض', en: 'Patient'),
          body: context.tr(
            ar: 'يمكنه إضافة الأدوية، عرض الجدول اليومي، متابعة التحديثات، والتنقل بين صفحات التطبيق بسهولة.',
            en: 'Patients can add medications, view the daily schedule, follow updates, and move between app pages easily.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'الصيدلي', en: 'Pharmacist'),
          body: context.tr(
            ar: 'يستطيع تقديم طلب حساب صيدلي وإدارة المهام، لكنه لا يدخل واجهته التشغيلية قبل اعتماد الإدارة.',
            en: 'Pharmacists can submit an account request and manage tasks, but their operational workspace stays locked until admin approval.',
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
      gradientColors: const [Color(0xFF53B3F4), Color(0xFF7FD3FF)],
      sections: [
        _PageSection(
          title: context.tr(ar: 'البيانات المخزنة', en: 'Stored data'),
          body: context.tr(
            ar: 'يُخزن التطبيق بيانات الحساب الأساسية والبيانات الطبية التي يضيفها المستخدم داخل Firebase وفق بنية منظمة.',
            en: 'The app stores core account details and the medical information added by the user inside Firebase with an organized structure.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'صلاحيات الوصول', en: 'Access permissions'),
          body: context.tr(
            ar: 'المريض يرى بياناته فقط، والصيدلي يحتاج موافقة الإدارة قبل استخدام الواجهة الخاصة به.',
            en: 'Patients can see only their own data, and pharmacists need admin approval before using their dedicated interface.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'التنبيهات', en: 'Notifications'),
          body: context.tr(
            ar: 'التذكيرات تُستخدم فقط لدعم التزام الجرعات ولا تُشارك مع جهات خارجية.',
            en: 'Reminders are used only to support dose adherence and are not shared with external parties.',
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
      gradientColors: const [Color(0xFF2E86C1), Color(0xFF5CB8FF)],
      sections: [
        _PageSection(
          title: context.tr(ar: 'الاستخدام المقصود', en: 'Intended use'),
          body: context.tr(
            ar: 'التطبيق أداة مساعدة لتنظيم الجرعات والمتابعة ولا يغني عن التوجيه الطبي المباشر.',
            en: 'The app is a support tool for organizing doses and follow-up. It does not replace direct medical guidance.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'مسؤولية الحساب', en: 'Account responsibility'),
          body: context.tr(
            ar: 'المستخدم مسؤول عن صحة معلوماته، والإدارة مسؤولة عن اعتماد حسابات الصيادلة.',
            en: 'Users are responsible for the accuracy of their information, and the admin team is responsible for pharmacist approvals.',
          ),
        ),
        _PageSection(
          title: context.tr(ar: 'إدارة الوصول', en: 'Access management'),
          body: context.tr(
            ar: 'يجوز للمشرف رفض أو إيقاف أي حساب صيدلي إذا لم يستوفِ متطلبات الاعتماد.',
            en: 'The administrator may reject or stop any pharmacist account that does not meet approval requirements.',
          ),
        ),
      ],
    );
  }
}

class _ContentPage extends StatelessWidget {
  const _ContentPage({
    required this.title,
    required this.gradientColors,
    required this.sections,
  });

  final String title;
  final List<Color> gradientColors;
  final List<_PageSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
