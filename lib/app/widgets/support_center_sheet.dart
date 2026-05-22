import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localization.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import 'depth_card.dart';

class SupportCenterSheet {
  static const String supportPhone = '+967771406612';
  static const String supportWhatsapp = '+967771406612';
  static const String supportEmail = 'alharithbayousef@gmail.com';
  static const String supportInstagram =
      'https://www.instagram.com/%F0%9D%91%AC%F0%9D%92%8F%F0%9D%92%88.%F0%9D%91%A8%F0%9D%92%8D%F0%9D%92%89%F0%9D%92%82%F0%9D%92%93%F0%9D%92%8A%F0%9D%92%95%F0%9D%92%89-%F0%9D%91%A9%F0%9D%92%82%F0%9D%92%80%F0%9D%92%90%F0%9D%92%96%F0%9D%92%94%F0%9D%92%86%F0%9D%92%87';

  static const String developerName = 'Alharith Abdullah Bajaher';
  static const String developerPhone = '+967771406612';
  static const String developerWhatsapp = '+967771406612';
  static const String developerEmailPrimary = 'alharithabdullah717@gmail.com';
  static const String developerEmailSecondary = 'alharithbayousef@gmail.com';
  static const String developerInstagram =
      'https://www.instagram.com/%F0%9D%91%AC%F0%9D%92%8F%F0%9D%92%88.%F0%9D%91%A8%F0%9D%92%8D%F0%9D%92%89%F0%9D%92%82%F0%9D%92%93%F0%9D%92%8A%F0%9D%92%95%F0%9D%92%89-%F0%9D%91%A9%F0%9D%92%82%F0%9D%92%80%F0%9D%92%90%F0%9D%92%96%F0%9D%92%94%F0%9D%92%86%F0%9D%92%87';

  static Future<void> showSupportSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SupportContentSheet(),
    );
  }

  static Future<void> showDeveloperSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeveloperContentSheet(),
    );
  }
}

class _SupportContentSheet extends StatelessWidget {
  const _SupportContentSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseContactSheet(
      title: context.tr(ar: 'الدعم والتواصل', en: 'Support & contact'),
      subtitle: context.tr(
        ar: 'تواصل مباشرة مع فريق دعم دوا تايم عبر أزرار سريعة.',
        en: 'Contact DawaTime support directly using quick action buttons.',
      ),
      sections: [
        _ContactSection(
          title: context.tr(ar: 'الدعم الرسمي', en: 'Official support'),
          actions: [
            _ContactActionButtonData.phone(
              label: context.tr(ar: 'اتصال', en: 'Call'),
              value: SupportCenterSheet.supportPhone,
            ),
            _ContactActionButtonData.whatsapp(
              label: context.tr(ar: 'واتساب', en: 'WhatsApp'),
              value: SupportCenterSheet.supportWhatsapp,
            ),
            _ContactActionButtonData.instagram(
              label: context.tr(ar: 'إنستقرام', en: 'Instagram'),
              value: SupportCenterSheet.supportInstagram,
            ),
            _ContactActionButtonData.email(
              label: context.tr(ar: 'إيميل', en: 'Email'),
              value: SupportCenterSheet.supportEmail,
            ),
          ],
          rows: [
            _ContactRowData.phone(
              label: context.tr(ar: 'اتصال هاتفي', en: 'Phone call'),
              value: SupportCenterSheet.supportPhone,
            ),
            _ContactRowData.whatsapp(
              label: context.tr(ar: 'واتساب', en: 'WhatsApp'),
              value: SupportCenterSheet.supportWhatsapp,
            ),
            _ContactRowData.email(
              label: context.tr(ar: 'البريد الإلكتروني', en: 'Email'),
              value: SupportCenterSheet.supportEmail,
            ),
          ],
        ),
      ],
    );
  }
}

class _DeveloperContentSheet extends StatelessWidget {
  const _DeveloperContentSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseContactSheet(
      title: context.tr(ar: 'المصمم والمطور', en: 'Designer & developer'),
      subtitle: SupportCenterSheet.developerName,
      sections: [
        _ContactSection(
          title: context.tr(ar: 'بيانات التواصل', en: 'Contact details'),
          actions: [
            _ContactActionButtonData.phone(
              label: context.tr(ar: 'اتصال', en: 'Call'),
              value: SupportCenterSheet.developerPhone,
            ),
            _ContactActionButtonData.whatsapp(
              label: context.tr(ar: 'واتساب', en: 'WhatsApp'),
              value: SupportCenterSheet.developerWhatsapp,
            ),
            _ContactActionButtonData.instagram(
              label: context.tr(ar: 'إنستقرام', en: 'Instagram'),
              value: SupportCenterSheet.developerInstagram,
            ),
            _ContactActionButtonData.email(
              label: context.tr(ar: 'إيميل', en: 'Email'),
              value: SupportCenterSheet.developerEmailPrimary,
            ),
          ],
          rows: [
            _ContactRowData.phone(
              label: context.tr(ar: 'موبايل', en: 'Mobile'),
              value: SupportCenterSheet.developerPhone,
            ),
            _ContactRowData.whatsapp(
              label: context.tr(ar: 'واتساب', en: 'WhatsApp'),
              value: SupportCenterSheet.developerWhatsapp,
            ),
            _ContactRowData.email(
              label: context.tr(ar: 'إيميل 1', en: 'Email 1'),
              value: SupportCenterSheet.developerEmailPrimary,
            ),
            _ContactRowData.email(
              label: context.tr(ar: 'إيميل 2', en: 'Email 2'),
              value: SupportCenterSheet.developerEmailSecondary,
            ),
            _ContactRowData.link(
              label: 'Instagram',
              value: SupportCenterSheet.developerInstagram,
            ),
          ],
        ),
      ],
    );
  }
}

class _BaseContactSheet extends StatelessWidget {
  const _BaseContactSheet({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<_ContactSection> sections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
          child: DepthCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ContactSectionWidget(section: section),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactSection {
  const _ContactSection({
    required this.title,
    required this.rows,
    this.actions = const <_ContactActionButtonData>[],
  });

  final String title;
  final List<_ContactRowData> rows;
  final List<_ContactActionButtonData> actions;
}

class _ContactSectionWidget extends StatelessWidget {
  const _ContactSectionWidget({required this.section});

  final _ContactSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFE1E9F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: AppFontSize.bodyLarge,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (section.actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: section.actions
                  .map((action) => _ContactActionIconButton(data: action))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          ...section.rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ContactRowWidget(data: row),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ContactActionType { phone, whatsapp, email, link }

class _ContactActionButtonData {
  const _ContactActionButtonData({
    required this.label,
    required this.value,
    required this.type,
    required this.icon,
    required this.tintColor,
  });

  factory _ContactActionButtonData.phone({
    required String label,
    required String value,
  }) => _ContactActionButtonData(
    label: label,
    value: value,
    type: _ContactActionType.phone,
    icon: Icons.call_rounded,
    tintColor: const Color(0xFF1E88E5),
  );

  factory _ContactActionButtonData.whatsapp({
    required String label,
    required String value,
  }) => _ContactActionButtonData(
    label: label,
    value: value,
    type: _ContactActionType.whatsapp,
    icon: Icons.chat_bubble_rounded,
    tintColor: const Color(0xFF22A55D),
  );

  factory _ContactActionButtonData.email({
    required String label,
    required String value,
  }) => _ContactActionButtonData(
    label: label,
    value: value,
    type: _ContactActionType.email,
    icon: Icons.email_rounded,
    tintColor: const Color(0xFF7E57C2),
  );

  factory _ContactActionButtonData.instagram({
    required String label,
    required String value,
  }) => _ContactActionButtonData(
    label: label,
    value: value,
    type: _ContactActionType.link,
    icon: Icons.camera_alt_rounded,
    tintColor: const Color(0xFFE1306C),
  );

  final String label;
  final String value;
  final _ContactActionType type;
  final IconData icon;
  final Color tintColor;
}

class _ContactActionIconButton extends StatelessWidget {
  const _ContactActionIconButton({required this.data});

  final _ContactActionButtonData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => _ContactActionLauncher.open(
        context: context,
        type: data.type,
        value: data.value,
      ),
      onLongPress: () =>
          _ContactActionLauncher.copyValue(context: context, value: data.value),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: data.tintColor.withValues(alpha: 0.08),
          border: Border.all(color: data.tintColor.withValues(alpha: 0.26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: data.tintColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.tintColor, size: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.tintColor,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRowData {
  const _ContactRowData({
    required this.label,
    required this.value,
    required this.type,
    required this.icon,
  });

  factory _ContactRowData.phone({
    required String label,
    required String value,
  }) => _ContactRowData(
    label: label,
    value: value,
    type: _ContactActionType.phone,
    icon: Icons.call_rounded,
  );

  factory _ContactRowData.whatsapp({
    required String label,
    required String value,
  }) => _ContactRowData(
    label: label,
    value: value,
    type: _ContactActionType.whatsapp,
    icon: Icons.chat_rounded,
  );

  factory _ContactRowData.email({
    required String label,
    required String value,
  }) => _ContactRowData(
    label: label,
    value: value,
    type: _ContactActionType.email,
    icon: Icons.email_rounded,
  );

  factory _ContactRowData.link({
    required String label,
    required String value,
  }) => _ContactRowData(
    label: label,
    value: value,
    type: _ContactActionType.link,
    icon: Icons.link_rounded,
  );

  final String label;
  final String value;
  final _ContactActionType type;
  final IconData icon;
}

class _ContactRowWidget extends StatelessWidget {
  const _ContactRowWidget({required this.data});

  final _ContactRowData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.patientPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(data.icon, color: AppPalette.patientPrimary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  color: AppPalette.muted,
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          tooltip: context.tr(ar: 'نسخ', en: 'Copy'),
          onPressed: () => _ContactActionLauncher.copyValue(
            context: context,
            value: data.value,
          ),
          icon: const Icon(Icons.copy_rounded),
        ),
        IconButton(
          tooltip: context.tr(ar: 'فتح', en: 'Open'),
          onPressed: () => _ContactActionLauncher.open(
            context: context,
            type: data.type,
            value: data.value,
          ),
          icon: const Icon(Icons.open_in_new_rounded),
        ),
      ],
    );
  }
}

class _ContactActionLauncher {
  static Future<void> copyValue({
    required BuildContext context,
    required String value,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(ar: 'تم النسخ بنجاح.', en: 'Copied.')),
      ),
    );
  }

  static Future<void> open({
    required BuildContext context,
    required _ContactActionType type,
    required String value,
  }) async {
    Uri uri;
    switch (type) {
      case _ContactActionType.phone:
        uri = Uri(scheme: 'tel', path: value);
        break;
      case _ContactActionType.whatsapp:
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        uri = Uri.parse('https://wa.me/$digits');
        break;
      case _ContactActionType.email:
        uri = Uri(
          scheme: 'mailto',
          path: value,
          queryParameters: {'subject': 'DawaTime Support'},
        );
        break;
      case _ContactActionType.link:
        uri = Uri.parse(value);
        break;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            ar: 'تعذر فتح الرابط مباشرة. تم نسخ البيانات.',
            en: 'Could not open directly. Copied instead.',
          ),
        ),
      ),
    );
    await copyValue(context: context, value: value);
  }
}
