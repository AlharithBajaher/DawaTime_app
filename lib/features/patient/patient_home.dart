import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/models/medication_model.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/notification_service.dart';
import 'medication_editor_page.dart';
import '../settings/settings_page.dart';

part 'patient_home_tabs.dart';
part 'patient_home_sheets.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final MedicationService _medicationService = MedicationService();

  int _selectedTab = 0;
  int _selectedDayOffset = 0;
  bool _showQuickActions = false;
  bool _hasWelcomedUser = false;

  DateTime get _selectedDate =>
      DateTime.now().add(Duration(days: _selectedDayOffset));

  String _formatTime(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _showWelcomeMessage(String userName) {
    if (_hasWelcomedUser) {
      return;
    }

    _hasWelcomedUser = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'مرحباً بعودتك، $userName',
              en: 'Welcome back, $userName',
            ),
          ),
        ),
      );
    });
  }

  List<_DoseMoment> _timelineForDate(
    List<MedicationModel> medications,
    DateTime date,
  ) {
    final moments = <_DoseMoment>[];

    for (final medication in medications) {
      final base = medication.scheduledDateTime(date);
      final intervalMinutes = (1440 / medication.frequency).round();
      for (var index = 0; index < medication.frequency; index++) {
        final totalMinutes =
            (base.hour * 60 + base.minute + intervalMinutes * index) % 1440;
        moments.add(
          _DoseMoment(
            medication: medication,
            time: DateTime(
              date.year,
              date.month,
              date.day,
              totalMinutes ~/ 60,
              totalMinutes % 60,
            ),
          ),
        );
      }
    }

    moments.sort((a, b) => a.time.compareTo(b.time));
    return moments;
  }

  Future<void> _openPlaceholderPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openMedicationEditor([MedicationModel? medication]) async {
    setState(() => _showQuickActions = false);

    final draft = await Navigator.push<MedicationEditorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationEditorPage(existing: medication),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    await _saveMedication(draft, medication);
  }

  Future<void> _saveMedication(
    MedicationEditorResult draft,
    MedicationModel? existing,
  ) async {
    final notificationIds = List<int>.generate(
      draft.frequency,
      (index) =>
          DateTime.now().millisecondsSinceEpoch.remainder(1000000000) + index,
    );

    try {
      final reminderTitle = context.t(AppText.appName);
      final reminderBody = context.tr(
        ar: 'حان وقت تناول ${draft.name}',
        en: 'It is time to take ${draft.name}',
      );

      if (existing != null && existing.notificationIds.isNotEmpty) {
        await NotificationService.cancelNotifications(existing.notificationIds);
      }

      await NotificationService.scheduleMedicationReminders(
        ids: notificationIds,
        title: reminderTitle,
        body: reminderBody,
        startHour: draft.time.hour,
        startMinute: draft.time.minute,
        frequency: draft.frequency,
      );

      final label = _formatTime(draft.time);
      if (existing == null) {
        await _medicationService.addMedication(
          name: draft.name,
          dose: draft.dose,
          form: draft.form,
          quantity: draft.quantity,
          doseUnit: draft.doseUnit,
          time: label,
          hour: draft.time.hour,
          minute: draft.time.minute,
          frequency: draft.frequency,
          notificationIds: notificationIds,
        );
      } else {
        await _medicationService.updateMedication(
          medicationId: existing.id,
          name: draft.name,
          dose: draft.dose,
          form: draft.form,
          quantity: draft.quantity,
          doseUnit: draft.doseUnit,
          time: label,
          hour: draft.time.hour,
          minute: draft.time.minute,
          frequency: draft.frequency,
          notificationIds: notificationIds,
        );
      }

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _MedicationSuccessSheet(name: draft.name),
      );
    } catch (error) {
      await NotificationService.cancelNotifications(notificationIds);
      if (!mounted) {
        return;
      }

      final message =
          error is FirebaseException && error.code == 'permission-denied'
          ? context.tr(
              ar: 'تعذر حفظ الدواء لأن صلاحيات Firestore الحالية تمنع ذلك. حدّث القواعد المنشورة ثم أعد المحاولة.',
              en: 'The medication could not be saved because the current Firestore rules are blocking it. Publish the updated rules and try again.',
            )
          : context.tr(
              ar: 'تعذر حفظ الدواء: $error',
              en: 'The medication could not be saved: $error',
            );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteMedication(MedicationModel medication) async {
    try {
      await _medicationService.deleteMedication(medication);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حذف ${medication.name}.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حذف الدواء: $error')));
    }
  }

  Future<void> _showMedicationActions(MedicationModel medication) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicationActionSheet(
        medication: medication,
        onTaken: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تسجيل تناول ${medication.name}.')),
          );
        },
        onSkipped: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تسجيل تخطي ${medication.name}.')),
          );
        },
        onReschedule: () {
          Navigator.pop(context);
          _openMedicationEditor(medication);
        },
        onEdit: () {
          Navigator.pop(context);
          _openMedicationEditor(medication);
        },
        onDelete: () => _deleteMedication(medication),
      ),
    );
  }

  Future<void> _showProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(
        onSignOut: () async {
          Navigator.pop(context);
          await FirebaseAuth.instance.signOut();
        },
      ),
    );
  }

  Widget _buildTabContent(
    List<MedicationModel> medications,
    List<_DoseMoment> timeline,
  ) {
    switch (_selectedTab) {
      case 0:
        return _PatientHomeTab(
          selectedDate: _selectedDate,
          timeline: timeline,
          onAddMedication: () {
            _openMedicationEditor();
          },
          onSelectOffset: (value) {
            setState(() => _selectedDayOffset = value);
          },
          onShiftWeek: (value) {
            setState(() => _selectedDayOffset += value);
          },
          onMedicationTap: _showMedicationActions,
        );
      case 1:
        return _PatientMedicinesTab(
          medications: medications,
          onAddMedication: () {
            _openMedicationEditor();
          },
        );
      case 2:
        return _PatientUpdatesTab(
          onLearnMore: () {
            _openPlaceholderPage(
              const _SimplePage(
                title: 'تعرف على المزيد',
                description:
                    'هذه صفحة معلومات حقيقية يمكن توسيعها بمحتوى الدعم الصحي والإرشادات.',
                icon: Icons.info_outline_rounded,
              ),
            );
          },
        );
      default:
        return _PatientMoreTab(onOpenPage: _openPlaceholderPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'guest@dawatime.app';
    final userName = userEmail.split('@').first.replaceAll('.', ' ');
    final displayName = userName.isEmpty
        ? context.tr(ar: 'ضيف', en: 'Guest')
        : userName;

    _showWelcomeMessage(displayName);

    return StreamBuilder<List<MedicationModel>>(
      stream: _medicationService.getUserMedications(),
      builder: (context, snapshot) {
        final medications = snapshot.data ?? const <MedicationModel>[];
        final timeline = _timelineForDate(medications, _selectedDate);

        return Scaffold(
          body: Stack(
            children: [
              Container(
                color: const Color(0xFFF1F4F9),
                child: SafeArea(
                  child: Column(
                    children: [
                      _PatientTopBar(
                        userName: displayName,
                        onProfilePressed: _showProfileSheet,
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppLayout.maxContentWidth,
                            ),
                            child: _buildTabContent(medications, timeline),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedTab == 0)
                Positioned(
                  bottom: AppLayout.fabBottomOffset,
                  left: AppSpacing.lg,
                  child: _QuickActionMenu(
                    expanded: _showQuickActions,
                    onMainTap: () {
                      setState(() => _showQuickActions = !_showQuickActions);
                    },
                    onAddMedication: () {
                      _openMedicationEditor();
                    },
                    onAddHealthTrack: () {
                      setState(() => _showQuickActions = false);
                      _openPlaceholderPage(
                        const _SimplePage(
                          title: 'أضف متتبع الصحة',
                          description:
                              'صفحة حقيقية جاهزة لاحقاً لتسجيل الضغط والسكر والنبض.',
                          icon: Icons.monitor_heart_outlined,
                        ),
                      );
                    },
                    onAddDose: () {
                      _openMedicationEditor();
                    },
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.bottomNavInset,
              0,
              AppLayout.bottomNavInset,
              AppLayout.bottomNavInset,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: NavigationBar(
                selectedIndex: _selectedTab,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedTab = index;
                    _showQuickActions = false;
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: context.t(AppText.home),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.medication_outlined),
                    selectedIcon: const Icon(Icons.medication_rounded),
                    label: context.t(AppText.medications),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.article_outlined),
                    selectedIcon: const Icon(Icons.article_rounded),
                    label: context.t(AppText.updates),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.list_alt_outlined),
                    selectedIcon: const Icon(Icons.list_alt_rounded),
                    label: context.t(AppText.more),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DoseMoment {
  const _DoseMoment({required this.medication, required this.time});

  final MedicationModel medication;
  final DateTime time;

  String get label {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
