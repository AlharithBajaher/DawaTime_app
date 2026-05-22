import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/animated_welcome_banner.dart';
import '../../app/widgets/depth_card.dart';
import '../../app/widgets/home_navigation_chrome.dart';
import '../../app/widgets/profile_editor_sheet.dart';
import '../../app/widgets/profile_side_drawer.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/pharmacy_rating_model.dart';
import '../../data/models/shared_medicine_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/pharmacy_rating_service.dart';
import '../../data/services/shared_medicine_service.dart';
import '../settings/settings_page.dart';
import 'medication_editor_page.dart';

part 'patient_home_tabs.dart';
part 'patient_home_sheets.dart';
part 'patient_marketplace_tab.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final MedicationService _medicationService = MedicationService();
  final SharedMedicineService _sharedMedicineService = SharedMedicineService();

  int _selectedTab = 0;
  int _selectedDayOffset = 0;
  bool _showQuickActions = false;
  bool _hasWelcomedUser = false;
  bool _welcomeBannerVisible = false;
  String _welcomeDisplayName = '';
  String _catalogSearchQuery = '';
  String _lastReminderSyncSignature = '';
  bool _isReminderSyncRunning = false;
  bool _reminderSyncQueued = false;
  Timer? _reminderSyncDebounce;
  List<MedicationModel> _pendingReminderMedications = const <MedicationModel>[];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _doseActionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _reminderSyncDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Force a one-time resync after app resume to keep reminders aligned.
      setState(() => _lastReminderSyncSignature = '');
    }
  }

  DateTime get _selectedDate =>
      DateTime.now().add(Duration(days: _selectedDayOffset));

  Stream<AppUserModel?> _watchCurrentProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream<AppUserModel?>.value(null);
    }

    return _authService.watchUserProfile(uid);
  }

  String _fallbackUserName(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final fallback = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    return fallback.isEmpty ? context.tr(ar: 'ضيف', en: 'Guest') : fallback;
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  List<int> _buildNotificationIds({
    required int requiredCount,
    required String seedText,
  }) {
    final nowSeed = DateTime.now().microsecondsSinceEpoch;
    final baseId = nowSeed.remainder(1200000000);
    final seedOffset = seedText.hashCode.abs() % 200000000;
    final used = <int>{};
    final ids = <int>[];

    for (var index = 0; index < requiredCount; index++) {
      var candidate =
          (baseId + seedOffset + (index * 9973) + (requiredCount * 37))
              .remainder(2000000000);
      while (!used.add(candidate)) {
        candidate = (candidate + 17).remainder(2000000000);
      }
      ids.add(candidate);
    }
    return ids;
  }

  Future<List<int>> _ensureNotificationIdsForMedication(
    MedicationModel medication,
  ) async {
    final requiredCount = NotificationService.requiredNotificationCount(
      doseCount: medication.doseTimes.length,
      intervalDays: medication.intervalDays,
    );
    if (medication.notificationIds.length >= requiredCount) {
      return medication.notificationIds;
    }

    final nextIds = _buildNotificationIds(
      requiredCount: requiredCount,
      seedText: '${medication.id}:${medication.name}:${medication.dose}',
    );
    await _medicationService.replaceNotificationIds(
      medicationId: medication.id,
      notificationIds: nextIds,
    );
    return nextIds;
  }

  void _syncWelcomeBanner(String userName) {
    if (_hasWelcomedUser) {
      return;
    }

    _hasWelcomedUser = true;
    _welcomeDisplayName = userName.trim().isEmpty
        ? context.tr(ar: 'ضيف', en: 'Guest')
        : userName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() => _welcomeBannerVisible = true);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _welcomeBannerVisible = false);
        }
      });
    });
  }

  List<_DoseMoment> _timelineForDate(
    List<MedicationModel> medications,
    DateTime date,
  ) {
    final moments = <_DoseMoment>[];

    for (final medication in medications) {
      if (!medication.isScheduledOnDate(date)) {
        continue;
      }

      for (final doseTime in medication.sortedDoseTimes) {
        moments.add(
          _DoseMoment(
            medication: medication,
            time: DateTime(
              date.year,
              date.month,
              date.day,
              doseTime.hour,
              doseTime.minute,
            ),
          ),
        );
      }
    }

    moments.sort((a, b) => a.time.compareTo(b.time));
    return moments;
  }

  Future<void> _synchronizeMedicationReminders(
    List<MedicationModel> medications,
  ) async {
    final signature = medications
        .map(
          (medication) =>
              '${medication.id}:${medication.notificationIds.join(',')}:${medication.doseTimes.length}:${medication.intervalDays}:${medication.quantity}:${medication.remainingQuantity}',
        )
        .join('|');

    if (signature.isEmpty || signature == _lastReminderSyncSignature) {
      return;
    }

    if (_isReminderSyncRunning) {
      _reminderSyncQueued = true;
      return;
    }

    _isReminderSyncRunning = true;
    _lastReminderSyncSignature = signature;
    final reminderTitle = context.t(AppText.appName);
    final isArabic = context.isArabic;
    var hasAnyFailure = false;

    try {
      for (final medication in medications) {
        try {
          final notificationIds = await _ensureNotificationIdsForMedication(
            medication,
          );
          final reminderBody = isArabic
              ? 'حان وقت تناول ${medication.name}'
              : 'It is time to take ${medication.name}';

          if (notificationIds.isNotEmpty) {
            await NotificationService.scheduleMedicationReminders(
              ids: notificationIds,
              title: reminderTitle,
              body: reminderBody,
              doseTimes: medication.sortedDoseTimes,
              intervalDays: medication.intervalDays,
              anchorDate: medication.createdAt?.toDate() ?? DateTime.now(),
              medicationId: medication.id,
              medicationName: medication.name,
              medicationDose: medication.dose,
            );
          }

          final lowStockId =
              NotificationService.lowStockNotificationIdForMedication(
                medication.id,
              );
          await NotificationService.cancelNotification(lowStockId);
          final lowStockReminderAt = _estimateLowStockReminderDate(medication);
          if (lowStockReminderAt != null) {
            final lowStockBody = isArabic
                ? 'كمية ${medication.name} على وشك النفاد. يرجى إعادة التعبئة.'
                : '${medication.name} is running low. Please refill soon.';
            await NotificationService.scheduleLowStockReminder(
              id: lowStockId,
              title: reminderTitle,
              body: lowStockBody,
              reminderAt: lowStockReminderAt,
            );
          }
        } catch (_) {
          hasAnyFailure = true;
        }
      }
    } catch (_) {
      hasAnyFailure = true;
    } finally {
      if (hasAnyFailure) {
        _lastReminderSyncSignature = '';
      }
      _isReminderSyncRunning = false;
      if (_reminderSyncQueued && mounted) {
        _reminderSyncQueued = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _synchronizeMedicationReminders(_pendingReminderMedications);
          }
        });
      }
    }
  }

  void _queueReminderSync(List<MedicationModel> medications) {
    if (medications.isEmpty) {
      return;
    }
    _pendingReminderMedications = medications;
    _reminderSyncDebounce?.cancel();
    _reminderSyncDebounce = Timer(const Duration(milliseconds: 750), () {
      if (!mounted || _pendingReminderMedications.isEmpty) {
        return;
      }
      _synchronizeMedicationReminders(_pendingReminderMedications);
    });
  }

  DateTime? _estimateLowStockReminderDate(MedicationModel medication) {
    final sortedDoseTimes = medication.sortedDoseTimes;
    if (sortedDoseTimes.isEmpty || medication.remainingQuantity <= 0) {
      return null;
    }

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    var dosesLeft = medication.remainingQuantity;
    DateTime? depletionAt;

    for (var dayOffset = 0; dayOffset <= 1100 && dosesLeft > 0; dayOffset++) {
      final day = today.add(Duration(days: dayOffset));
      if (!medication.isScheduledOnDate(day)) {
        continue;
      }

      for (final doseTime in sortedDoseTimes) {
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          doseTime.hour,
          doseTime.minute,
        );
        if (scheduledAt.isBefore(now)) {
          continue;
        }

        dosesLeft -= 1;
        if (dosesLeft <= 0) {
          depletionAt = scheduledAt;
          break;
        }
      }
    }

    if (depletionAt == null) {
      final dosesPerCycle = sortedDoseTimes.length;
      final estimatedDaysLeft =
          ((medication.remainingQuantity / dosesPerCycle).ceil() *
                  medication.intervalDays)
              .clamp(1, 3650)
              .toInt();
      depletionAt = now.add(Duration(days: estimatedDaysLeft));
    }

    final reminderAt = depletionAt.subtract(const Duration(days: 2));
    if (!reminderAt.isAfter(now)) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    }
    return reminderAt;
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

  int _resolveRemainingQuantityForSave({
    required MedicationEditorResult draft,
    MedicationModel? existing,
  }) {
    if (existing == null) {
      return draft.quantity;
    }

    final safeDraftQuantity = draft.quantity.clamp(1, 1000000).toInt();
    final safeExistingQuantity = existing.quantity.clamp(1, 1000000).toInt();

    // عند تعديل كمية العبوة، نعتبرها إعادة تعبئة جديدة بالكامل.
    // مثال: من 20 (المتبقي 4) إلى 16 => تصبح 16/16 مباشرة.
    if (safeDraftQuantity != safeExistingQuantity) {
      return safeDraftQuantity;
    }

    // إذا لم تتغير الكمية، نحافظ على المتبقي الحالي.
    return existing.remainingQuantity.clamp(0, safeDraftQuantity).toInt();
  }

  Future<void> _saveMedication(
    MedicationEditorResult draft,
    MedicationModel? existing,
  ) async {
    final notificationCount = NotificationService.requiredNotificationCount(
      doseCount: draft.doseTimes.length,
      intervalDays: draft.intervalDays,
    );
    final draftSeed = '${draft.name}:${draft.dose}:${draft.intervalDays}';
    List<int> notificationIds;
    if (existing != null) {
      if (existing.notificationIds.length >= notificationCount) {
        notificationIds = existing.notificationIds;
      } else {
        final extraIds = _buildNotificationIds(
          requiredCount: notificationCount - existing.notificationIds.length,
          seedText: '$draftSeed:${existing.id}',
        );
        final merged = <int>{
          ...existing.notificationIds,
          ...extraIds,
        }.toList(growable: false);
        notificationIds = merged.length >= notificationCount
            ? merged.take(notificationCount).toList(growable: false)
            : <int>[
                ...merged,
                ..._buildNotificationIds(
                  requiredCount: notificationCount - merged.length,
                  seedText: '$draftSeed:topup',
                ),
              ];
      }
    } else {
      notificationIds = _buildNotificationIds(
        requiredCount: notificationCount,
        seedText: draftSeed,
      );
    }
    final remainingQuantity = _resolveRemainingQuantityForSave(
      draft: draft,
      existing: existing,
    );

    try {
      final reminderTitle = context.t(AppText.appName);
      final reminderBody = context.tr(
        ar: 'حان وقت تناول ${draft.name}',
        en: 'It is time to take ${draft.name}',
      );
      final firstDose = draft.doseTimes.first;
      final label = _formatTime(
        TimeOfDay(hour: firstDose.hour, minute: firstDose.minute),
      );

      String savedMedicationId;
      DateTime scheduleAnchor;
      if (existing == null) {
        savedMedicationId = await _medicationService.addMedication(
          name: draft.name,
          dose: draft.dose,
          form: draft.form,
          quantity: draft.quantity,
          remainingQuantity: remainingQuantity,
          doseUnit: draft.doseUnit,
          time: label,
          hour: firstDose.hour,
          minute: firstDose.minute,
          frequency: draft.doseTimes.length,
          doseTimes: draft.doseTimes,
          intervalDays: draft.intervalDays,
          notificationIds: notificationIds,
        );
        scheduleAnchor = DateTime.now();
      } else {
        await _medicationService.updateMedication(
          medicationId: existing.id,
          name: draft.name,
          dose: draft.dose,
          form: draft.form,
          quantity: draft.quantity,
          remainingQuantity: remainingQuantity,
          doseUnit: draft.doseUnit,
          time: label,
          hour: firstDose.hour,
          minute: firstDose.minute,
          frequency: draft.doseTimes.length,
          doseTimes: draft.doseTimes,
          intervalDays: draft.intervalDays,
          notificationIds: notificationIds,
        );
        savedMedicationId = existing.id;
        scheduleAnchor = existing.createdAt?.toDate() ?? DateTime.now();
      }

      try {
        await NotificationService.scheduleMedicationReminders(
          ids: notificationIds,
          title: reminderTitle,
          body: reminderBody,
          doseTimes: draft.doseTimes,
          intervalDays: draft.intervalDays,
          anchorDate: scheduleAnchor,
          medicationId: savedMedicationId,
          medicationName: draft.name,
          medicationDose: draft.dose,
        );

        if (existing != null &&
            existing.notificationIds.isNotEmpty &&
            existing.notificationIds.join(',') != notificationIds.join(',')) {
          await NotificationService.cancelNotifications(
            existing.notificationIds,
          );
        }
        if (existing != null) {
          await NotificationService.cancelNotification(
            NotificationService.lowStockNotificationIdForMedication(
              existing.id,
            ),
          );
        }
      } catch (_) {
        // Keep the saved medication and allow automatic resync on next frame/resume.
        _lastReminderSyncSignature = '';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  ar: 'تم حفظ الدواء، وسيتم إعادة مزامنة التذكيرات تلقائياً خلال لحظات.',
                  en: 'Medicine saved. Reminders will be auto-resynced shortly.',
                ),
              ),
            ),
          );
        }
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
      if (!mounted) {
        return;
      }

      final message =
          error is FirebaseException && error.code == 'permission-denied'
          ? context.tr(
              ar: 'تعذر حفظ الدواء لأن قواعد Firestore الحالية تمنع ذلك. حدّث القواعد ثم أعد المحاولة.',
              en: 'The medication could not be saved because Firestore rules are blocking it. Update the rules and try again.',
            )
          : context.tr(
              ar: 'تعذر حفظ الدواء: $error',
              en: 'Unable to save medication: $error',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم حذف ${medication.name}.',
              en: '${medication.name} deleted.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تعذر حذف الدواء: $error',
              en: 'Unable to delete medication: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteMedication(MedicationModel medication) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(ar: 'حذف الدواء', en: 'Delete medicine')),
          content: Text(
            context.tr(
              ar: 'هل تريد حذف ${medication.name} نهائياً؟',
              en: 'Do you want to delete ${medication.name} permanently?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr(ar: 'إلغاء', en: 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.tr(ar: 'حذف', en: 'Delete')),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteMedication(medication);
    }
  }

  Future<void> _markDoseAsTaken(_DoseMoment dose) async {
    if (_doseActionInProgress) {
      return;
    }
    if (dose.medication.isDoseTaken(dose.time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم تسجيل هذه الجرعة مسبقاً.',
              en: 'This dose is already recorded as taken.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _doseActionInProgress = true);
    try {
      final takenAt = DateTime.now().toLocal();
      final result = await _medicationService.markDoseAsTaken(
        medication: dose.medication,
        scheduledAt: dose.time,
        takenAt: takenAt,
      );

      if (!mounted) {
        return;
      }

      final timeLabel = _formatTime(TimeOfDay.fromDateTime(takenAt));
      final message = result.archivedMedication
          ? context.tr(
              ar: 'تم تناول آخر جرعة من ${dose.medication.name} عند $timeLabel، وتم إخفاء الدواء تلقائياً بعد نفاد الكمية.',
              en: 'Last dose of ${dose.medication.name} was taken at $timeLabel, and the medicine was auto-removed after stock depletion.',
            )
          : context.tr(
              ar: 'تم تناول ${dose.medication.name} عند $timeLabel. الكمية المتبقية: ${result.remainingQuantity}.',
              en: '${dose.medication.name} was taken at $timeLabel. Remaining quantity: ${result.remainingQuantity}.',
            );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_formatOperationError(error))));
    } finally {
      if (mounted) {
        setState(() => _doseActionInProgress = false);
      }
    }
  }

  Future<void> _markDoseAsSkipped(_DoseMoment dose) async {
    if (_doseActionInProgress) {
      return;
    }
    if (dose.medication.isDoseSkipped(dose.time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم تسجيل هذه الجرعة كمتخطاة مسبقاً.',
              en: 'This dose is already marked as skipped.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _doseActionInProgress = true);
    try {
      final skippedAt = DateTime.now().toLocal();
      await _medicationService.markDoseAsSkipped(
        medication: dose.medication,
        scheduledAt: dose.time,
        skippedAt: skippedAt,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تم تخطي ${dose.medication.name}.',
              en: '${dose.medication.name} was skipped.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_formatOperationError(error))));
    } finally {
      if (mounted) {
        setState(() => _doseActionInProgress = false);
      }
    }
  }

  String _formatOperationError(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return context.tr(
        ar: 'تعذر تنفيذ العملية بسبب قواعد Firestore الحالية. حدّث القواعد ثم أعد المحاولة.',
        en: 'Operation blocked by current Firestore rules. Update your rules and try again.',
      );
    }
    return context.tr(
      ar: 'تعذر تنفيذ العملية: $error',
      en: 'Operation failed: $error',
    );
  }

  Future<void> _snoozeDose(_DoseMoment dose, int minutes) async {
    final reminderTitle = context.t(AppText.appName);
    final reminderBody = context.tr(
      ar: 'حان وقت تناول ${dose.medication.name}',
      en: 'It is time to take ${dose.medication.name}',
    );

    final snoozeId =
        DateTime.now().millisecondsSinceEpoch.remainder(2000000000) + minutes;
    final reminderAt = DateTime.now().toLocal().add(Duration(minutes: minutes));
    await NotificationService.scheduleOneTimeReminder(
      id: snoozeId,
      title: reminderTitle,
      body: reminderBody,
      reminderAt: reminderAt,
      medicationId: dose.medication.id,
      medicationName: dose.medication.name,
      medicationDose: dose.medication.dose,
    );

    if (!mounted) {
      return;
    }

    final timeLabel = _formatTime(TimeOfDay.fromDateTime(reminderAt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            ar: 'تم تأجيل تذكير ${dose.medication.name} حتى $timeLabel.',
            en: '${dose.medication.name} reminder snoozed to $timeLabel.',
          ),
        ),
      ),
    );
  }

  Future<void> _showMedicationActions(_DoseMoment dose) async {
    final medication = dose.medication;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicationActionSheet(
        medication: medication,
        onTaken: () async {
          Navigator.pop(context);
          await _markDoseAsTaken(dose);
        },
        onSkipped: () async {
          Navigator.pop(context);
          await _markDoseAsSkipped(dose);
        },
        onSnooze30: () async {
          Navigator.pop(context);
          await _snoozeDose(dose, 30);
        },
        onSnooze60: () async {
          Navigator.pop(context);
          await _snoozeDose(dose, 60);
        },
        onReschedule: () async {
          Navigator.pop(context);
          await _openMedicationEditor(medication);
        },
        onEdit: () async {
          Navigator.pop(context);
          await _openMedicationEditor(medication);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _confirmDeleteMedication(medication);
        },
      ),
    );
  }

  Future<void> _saveCurrentProfile({
    required String name,
    required String username,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
  }) async {
    await _authService.updateCurrentUserProfile(
      name: name,
      username: username,
      pharmacyName: pharmacyName,
      pharmacyLocation: pharmacyLocation,
      pharmacyPhone: pharmacyPhone,
    );
  }

  Future<void> _openProfileEditor({
    required AppUserModel? profile,
    required String displayName,
    required String email,
  }) async {
    await showProfileEditorSheet(
      context: context,
      profile: profile,
      fallbackName: displayName,
      fallbackEmail: email,
      roleLabel: context.tr(ar: 'مريض', en: 'Patient'),
      accentColor: AppPalette.patientPrimary,
      showPharmacyFields: false,
      onSaveProfile: _saveCurrentProfile,
    );
  }

  void _openSettingsFromDrawer() {
    Navigator.of(context).pop();
    _openPlaceholderPage(const SettingsPage());
  }

  Future<void> _showSharedMedicineDetails(
    SharedMedicineModel sharedMedicine,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientMedicineDetailsSheet(medicine: sharedMedicine),
    );
  }

  Widget _buildTabContent(
    List<MedicationModel> medications,
    List<MedicationModel> medicationHistory,
    List<SharedMedicineModel> sharedMedicines,
    List<_DoseMoment> timeline,
    AppUserModel? profile,
    String displayName,
    String email,
  ) {
    switch (_selectedTab) {
      case 0:
        return _ModernPatientHomeTab(
          selectedDate: _selectedDate,
          timeline: timeline,
          onAddMedication: _openMedicationEditor,
          onSelectOffset: (value) {
            setState(() => _selectedDayOffset = value);
          },
          onShiftWeek: (value) {
            setState(() => _selectedDayOffset += value);
          },
          onMedicationTap: _showMedicationActions,
          onDeleteMedication: _confirmDeleteMedication,
          onTakeDose: _markDoseAsTaken,
        );
      case 1:
        return _ModernPatientMedicinesTab(
          medications: medications,
          onAddMedication: _openMedicationEditor,
        );
      case 2:
        return _PatientMarketplaceTab(
          medicines: sharedMedicines,
          searchQuery: _catalogSearchQuery,
          onSearchChanged: (value) {
            setState(() => _catalogSearchQuery = value);
          },
          onOpenMedicine: _showSharedMedicineDetails,
        );
      case 3:
        return _PatientUpdatesTab(
          onLearnMore: () {
            _openPlaceholderPage(
              _SimplePage(
                title: context.tr(ar: 'تعرّف على المزيد', en: 'Learn more'),
                description: context.tr(
                  ar: 'يمكن توسيع هذه الصفحة لاحقاً بمحتوى دعم وإرشادات صحية.',
                  en: 'This page can be expanded later with support content and health guidance.',
                ),
                icon: Icons.info_outline_rounded,
              ),
            );
          },
          onOpenReports: () {
            _openPlaceholderPage(
              _MedicationReportsPage(medications: medicationHistory),
            );
          },
        );
      default:
        return _PatientMoreTab(
          onOpenPage: _openPlaceholderPage,
          medications: medications,
          onEditProfile: () => _openProfileEditor(
            profile: profile,
            displayName: displayName,
            email: email,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: _watchCurrentProfile(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final displayName = profile?.displayName ?? _fallbackUserName(context);
        final email =
            profile?.email ??
            FirebaseAuth.instance.currentUser?.email ??
            'guest@dawatime.app';

        _syncWelcomeBanner(displayName);

        return StreamBuilder<List<MedicationModel>>(
          stream: _medicationService.getUserMedications(includeArchived: true),
          builder: (context, snapshot) {
            final allMedications = snapshot.data ?? const <MedicationModel>[];
            final medications = allMedications
                .where((medication) => !medication.isArchived)
                .toList(growable: false);
            final timeline = _timelineForDate(medications, _selectedDate);

            _queueReminderSync(medications);

            return StreamBuilder<List<SharedMedicineModel>>(
              stream: _sharedMedicineService.watchMarketplaceMedicines(),
              builder: (context, sharedMedicineSnapshot) {
                final sharedMedicines =
                    sharedMedicineSnapshot.data ??
                    const <SharedMedicineModel>[];
                final hasDataWarning =
                    snapshot.hasError ||
                    sharedMedicineSnapshot.hasError ||
                    profileSnapshot.hasError;

                return Scaffold(
                  key: _scaffoldKey,
                  drawer: ProfileSideDrawer(
                    profile: profile,
                    fallbackName: displayName,
                    fallbackEmail: email,
                    roleLabel: context.tr(ar: 'مريض', en: 'Patient'),
                    accentColor: AppPalette.patientPrimary,
                    onOpenSettings: _openSettingsFromDrawer,
                    onEditProfile: () => _openProfileEditor(
                      profile: profile,
                      displayName: displayName,
                      email: email,
                    ),
                    onSignOut: _authService.signOut,
                  ),
                  body: Stack(
                    children: [
                      Container(
                        color: const Color(0xFFF1F4F9),
                        child: SafeArea(
                          child: Column(
                            children: [
                              _PatientTopBar(
                                profile: profile,
                                fallbackName: displayName,
                              ),
                              if (hasDataWarning)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    0,
                                  ),
                                  child: DepthCard(
                                    color: const Color(0xFFFFF4E5),
                                    borderColor: const Color(0xFFFFDCA8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppPalette.amber,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            context.tr(
                                              ar: 'حدثت مشكلة مؤقتة في تحميل بعض البيانات، لكن يمكنك متابعة استخدام هذه الصفحة.',
                                              en: 'Some data could not be loaded right now, but you can continue using this page.',
                                            ),
                                            style: const TextStyle(
                                              color: AppPalette.text,
                                              fontSize: AppFontSize.body,
                                              fontWeight: FontWeight.w700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: AppLayout.maxContentWidth,
                                    ),
                                    child: _buildTabContent(
                                      medications,
                                      allMedications,
                                      sharedMedicines,
                                      timeline,
                                      profile,
                                      displayName,
                                      email,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedTab == 0)
                        Positioned(
                          bottom: 70,
                          left: AppSpacing.lg,
                          child: _QuickActionMenu(
                            expanded: _showQuickActions,
                            onMainTap: () {
                              setState(
                                () => _showQuickActions = !_showQuickActions,
                              );
                            },
                            onAddMedication: _openMedicationEditor,
                            onAddHealthTrack: () {
                              setState(() => _showQuickActions = false);
                              _openPlaceholderPage(
                                _SimplePage(
                                  title: context.tr(
                                    ar: 'أضف تتبع الصحة',
                                    en: 'Add health tracker',
                                  ),
                                  description: context.tr(
                                    ar: 'صفحة جاهزة لاحقاً لتسجيل الضغط والسكر والنبض.',
                                    en: 'A page prepared for later blood pressure, glucose, and pulse tracking.',
                                  ),
                                  icon: Icons.monitor_heart_outlined,
                                ),
                              );
                            },
                            onAddDose: _openMedicationEditor,
                          ),
                        ),
                      AnimatedWelcomeBanner(
                        visible: _welcomeBannerVisible,
                        displayName: _welcomeDisplayName,
                        accentColor: AppPalette.patientPrimary,
                        icon: Icons.waving_hand_rounded,
                      ),
                    ],
                  ),
                  bottomNavigationBar: AnimatedHomeBottomBar(
                    selectedIndex: _selectedTab,
                    activeColor: AppPalette.patientPrimary,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedTab = index;
                        _showQuickActions = false;
                      });
                    },
                    items: [
                      HomeBottomBarItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: context.t(AppText.home),
                      ),
                      HomeBottomBarItem(
                        icon: Icons.medication_outlined,
                        selectedIcon: Icons.medication_rounded,
                        label: context.t(AppText.medications),
                      ),
                      HomeBottomBarItem(
                        icon: Icons.storefront_outlined,
                        selectedIcon: Icons.storefront_rounded,
                        label: context.tr(ar: 'تصفح', en: 'Browse'),
                      ),
                      HomeBottomBarItem(
                        icon: Icons.article_outlined,
                        selectedIcon: Icons.article_rounded,
                        label: context.t(AppText.updates),
                      ),
                      HomeBottomBarItem(
                        icon: Icons.list_alt_outlined,
                        selectedIcon: Icons.list_alt_rounded,
                        label: context.t(AppText.more),
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
