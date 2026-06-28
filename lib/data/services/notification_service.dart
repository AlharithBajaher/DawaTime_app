// ============================================================
// notification_service.dart
// DawaTime – unified notification system (doses + stock + inventory)
// ============================================================
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../firebase_options.dart';
import '../models/medication_model.dart';

// ---------------------------------------------------------------------------
// Background entry-point (Android isolate)
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.init(requestPermissions: false);
  await NotificationService.handleNotificationAction(
    response,
    fromBackground: true,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
/// A bilingual (AR/EN) notification message pair.
class _BilingualMsg {
  const _BilingualMsg({
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
  String body(bool isArabic) => isArabic ? bodyAr : bodyEn;
}

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------
class NotificationService {
  // ── Channel IDs ──────────────────────────────────────────────────────────
  static const String _doseChannelId   = 'dawatime_dose_v9';
  static const String _stockChannelId  = 'dawatime_stock_v4';
  static const String _syncChannelId   = 'dawatime_sync_v2';

  // ── Channel names (shown in Android settings) ────────────────────────────
  static const String _doseChannelName  = 'تذكير الجرعة / Dose Reminder';
  static const String _stockChannelName = 'تنبيه الكمية / Stock Alert';
  static const String _syncChannelName  = 'تأكيد الإجراء / Action Status';

  // ── Android raw-resource sounds (res/raw/*.mp3) ──────────────────────────
  static const String _doseSound  = 'dawatime_reminder';
  static const String _stockSound = 'dawatime_reminder_long';

  // ── Notification action IDs ──────────────────────────────────────────────
  static const String _actionTaken    = 'dose_taken';
  static const String _actionSkip     = 'dose_skip';
  static const String _actionSnooze30 = 'dose_snooze_30';
  static const String _actionSnooze60 = 'dose_snooze_60';

  // ── Planning constants ───────────────────────────────────────────────────
  /// Days ahead for which dose reminders are pre-scheduled.
  static const int reminderPlanningWindowDays = 14;

  /// Hard cap on scheduled notifications per medication.
  static const int _maxDoseSchedules = 120;

  // ── Low-stock constants ──────────────────────────────────────────────────
  /// Start reminding when remaining doses cover this many days or fewer.
  static const int _lowStockLeadDays = 3;

  /// Considered "critical" when this many doses remain.
  static const int _criticalDosesLeft = 3;

  /// Times of day for stock reminders (24-h).
  static const List<({int hour, int minute})> _stockTimes = [
    (hour: 9,  minute: 0),   // 9:00 AM
    (hour: 13, minute: 0),   // 1:00 PM
    (hour: 18, minute: 0),   // 6:00 PM
  ];

  // ── Internal ─────────────────────────────────────────────────────────────
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const MethodChannel _tzChannel = MethodChannel('dawatime/timezone');

  // =========================================================================
  // PUBLIC: Initialisation
  // =========================================================================
  static Future<void> init({bool requestPermissions = true}) async {
    if (kIsWeb || _initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final android_ = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Dose channel – alarm priority, custom sound, inline actions
    await android_?.createNotificationChannel(
      const AndroidNotificationChannel(
        _doseChannelId, _doseChannelName,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_doseSound),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        showBadge: true,
      ),
    );
    // Stock channel – high priority, long stock sound
    await android_?.createNotificationChannel(
      const AndroidNotificationChannel(
        _stockChannelId, _stockChannelName,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_stockSound),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        showBadge: true,
      ),
    );
    // Sync / confirmation channel – silent
    await android_?.createNotificationChannel(
      const AndroidNotificationChannel(
        _syncChannelId, _syncChannelName,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    if (requestPermissions) {
      await android_?.requestNotificationsPermission();
      await android_?.requestExactAlarmsPermission();
    }
    _initialized = true;
  }

  // =========================================================================
  // PUBLIC: Dose reminders
  // =========================================================================

  /// Returns how many notification IDs are needed for a medication schedule.
  static int requiredNotificationCount({
    required int doseCount,
    required int intervalDays,
  }) {
    final doses    = doseCount.clamp(1, 24);
    final interval = intervalDays.clamp(1, reminderPlanningWindowDays);
    final cycles   = (reminderPlanningWindowDays / interval).ceil() + 1;
    return doses * cycles;
  }

  /// Schedules all upcoming dose reminders for a medication.
  /// [ids] must have at least [requiredNotificationCount] elements.
  /// Pass [isArabic] to localise the notification text.
  static Future<void> scheduleMedicationReminders({
    required List<int> ids,
    required List<MedicationDoseTime> doseTimes,
    required int intervalDays,
    required DateTime anchorDate,
    required String medicationId,
    required String medicationName,
    required String medicationDose,
    required bool isArabic,
  }) async {
    if (kIsWeb || doseTimes.isEmpty) return;
    await _configureLocalTimeZone();

    final safeInterval = intervalDays.clamp(1, reminderPlanningWindowDays);
    final slots = _buildIntervalSlots(
      doseTimes: doseTimes,
      intervalDays: safeInterval,
      anchorDate: anchorDate.toLocal(),
    );
    final count = slots.length.clamp(0, _maxDoseSchedules);
    if (ids.length < count) {
      throw ArgumentError(
        'Need $count notification IDs for this schedule, got ${ids.length}.',
      );
    }

    final title = isArabic ? 'دواء تايم 💊' : 'DawaTime 💊';
    final body  = isArabic
        ? 'حان وقت تناول $medicationName'
        : 'Time to take $medicationName';

    for (var i = 0; i < count; i++) {
      final payload = _DosePayload(
        notificationId: ids[i],
        medicationId: medicationId,
        medicationName: medicationName,
        medicationDose: medicationDose,
        hour: slots[i].hour,
        minute: slots[i].minute,
        scheduledAtIso: slots[i].toLocal().toIso8601String(),
        titleAr: 'دواء تايم 💊',
        titleEn: 'DawaTime 💊',
        bodyAr: 'حان وقت تناول $medicationName',
        bodyEn: 'Time to take $medicationName',
      ).toJson();

      await _scheduleDoseSafely(
        id: ids[i],
        title: title,
        body: body,
        scheduledAt: slots[i],
        payload: payload,
      );
    }

    // Cancel unused IDs
    if (ids.length > count) {
      await cancelNotifications(ids.sublist(count));
    }
  }

  /// Schedules a single one-time reminder (used for snooze, etc.).
  static Future<void> scheduleOneTimeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime reminderAt,
    String medicationId    = '',
    String medicationName  = '',
    String medicationDose  = '',
  }) async {
    if (kIsWeb) return;
    await _configureLocalTimeZone();

    final local = reminderAt.toLocal();
    final payload = _DosePayload(
      notificationId: id,
      medicationId: medicationId,
      medicationName: medicationName,
      medicationDose: medicationDose,
      hour: local.hour,
      minute: local.minute,
      scheduledAtIso: local.toIso8601String(),
      titleAr: title, titleEn: title,
      bodyAr: body,   bodyEn: body,
    ).toJson();

    await _scheduleDoseSafely(
      id: id,
      title: title,
      body: body,
      scheduledAt: tz.TZDateTime.from(local, tz.local),
      payload: payload,
    );
  }

  // =========================================================================
  // PUBLIC: Stock reminders (patient medication quantity)
  // =========================================================================

  /// ID of the low-stock reminder for a patient medication.
  static int lowStockNotificationIdForMedication(String medicationId) =>
      1000000000 + (medicationId.hashCode.abs() % 900000000);

  /// ID of the inventory alert for a pharmacist item.
  static int inventoryNotificationIdForItem(String itemId) =>
      1900000000 + (itemId.hashCode.abs() % 90000000);

  /// Called after every dose taken. Evaluates whether stock reminders should
  /// be (re)scheduled based on remaining quantity. Pass the full medication
  /// data map and [isArabic] for correct language.
  static Future<void> syncMedicationStockReminders({
    required String medicationId,
    required String medicationName,
    required int totalQuantity,
    required int remainingQuantity,
    required int dosesPerDay,          // number of doseTimes entries
    required int intervalDays,
    required bool isArabic,
  }) async {
    if (kIsWeb) return;

    // Always cancel previous stock reminders first.
    await _cancelAllStockRemindersForMedication(medicationId);

    if (remainingQuantity <= 0 || dosesPerDay <= 0 || totalQuantity <= 0) return;

    // How many calendar days until depletion.
    final daysLeft = ((remainingQuantity / dosesPerDay).ceil() * intervalDays)
        .clamp(1, 3650);

    // Nothing to schedule if depletion is far away.
    if (daysLeft > reminderPlanningWindowDays + _lowStockLeadDays) return;

    await _configureLocalTimeZone();
    final now = DateTime.now().toLocal();

    // ── Build the list of schedule slots ───────────────────────────────────
    // We schedule on: today if already in the lead window, plus each of the
    // next [_lowStockLeadDays] days — at each of the _stockTimes.
    final startDay = (daysLeft - _lowStockLeadDays).clamp(0, daysLeft);

    for (var dayOffset = startDay; dayOffset <= daysLeft; dayOffset++) {
      for (final t in _stockTimes) {
        final slot = DateTime(
          now.year, now.month, now.day,
          t.hour, t.minute,
        ).add(Duration(days: dayOffset));

        if (!slot.isAfter(now)) continue;   // skip past slots

        final isCritical = remainingQuantity <= _criticalDosesLeft;
        final msg = _buildStockMessage(
          medicationName: medicationName,
          remaining: remainingQuantity,
          daysLeft: daysLeft,
          isCritical: isCritical,
          isArabic: isArabic,
        );

        final notifId = _stockSlotId(medicationId, dayOffset, t.hour, t.minute);
        await _scheduleStockSafely(
          id: notifId,
          title: msg.title(isArabic),
          body: msg.body(isArabic),
          scheduledAt: tz.TZDateTime.from(slot, tz.local),
        );
      }
    }
  }

  // ── Pharmacist inventory ──────────────────────────────────────────────────

  /// Shows or schedules alerts for a pharmacist inventory item.
  /// Called whenever quantity changes.
  static Future<void> syncInventoryAlert({
    required String itemId,
    required String itemName,
    required int quantity,
    required int minQuantity,
    required bool isArabic,
  }) async {
    if (kIsWeb) return;
    await _cancelAllInventoryRemindersForItem(itemId);

    if (quantity <= 0) {
      // Immediate + same-day repeats (out of stock)
      for (final t in _stockTimes) {
        final slot = _nextOccurrence(t.hour, t.minute);
        final msg = _buildInventoryMessage(
          itemName: itemName,
          quantity: quantity,
          minQuantity: minQuantity,
          isArabic: isArabic,
        );
        await _scheduleStockSafely(
          id: _inventorySlotId(itemId, t.hour, t.minute),
          title: msg.title(isArabic),
          body: msg.body(isArabic),
          scheduledAt: tz.TZDateTime.from(slot, tz.local),
        );
      }
      return;
    }

    if (quantity <= minQuantity) {
      // Low stock → 3 times a day
      await _configureLocalTimeZone();
      for (final t in _stockTimes) {
        final slot = _nextOccurrence(t.hour, t.minute);
        final msg = _buildInventoryMessage(
          itemName: itemName,
          quantity: quantity,
          minQuantity: minQuantity,
          isArabic: isArabic,
        );
        await _scheduleStockSafely(
          id: _inventorySlotId(itemId, t.hour, t.minute),
          title: msg.title(isArabic),
          body: msg.body(isArabic),
          scheduledAt: tz.TZDateTime.from(slot, tz.local),
        );
      }
    }
    // quantity > minQuantity → no alert needed
  }

  // =========================================================================
  // PUBLIC: Cancel helpers
  // =========================================================================

  static Future<void> cancelNotifications(List<int> ids) async {
    if (kIsWeb) return;
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // =========================================================================
  // PUBLIC: Notification action handler (tap / Take / Skip / Snooze)
  // =========================================================================

  static Future<void> handleNotificationAction(
    NotificationResponse response, {
    bool fromBackground = false,
  }) async {
    if (kIsWeb) return;

    final payload = _DosePayload.tryParse(response.payload);
    if (payload == null) return;

    final action = response.actionId ?? '';
    if (action.isEmpty) return;

    try {
      if (action == _actionSnooze30 || action == _actionSnooze60) {
        final minutes = action == _actionSnooze30 ? 30 : 60;
        await _executeSnooze(payload: payload, minutes: minutes);
        return;
      }
      if (action == _actionTaken || action == _actionSkip) {
        final markTaken = action == _actionTaken;
        final queued = await _commitDoseStatus(
          payload: payload,
          markAsTaken: markTaken,
        );
        await _showSyncFeedback(
          payload: payload,
          markAsTaken: markTaken,
          queued: queued,
        );
        return;
      }
    } catch (_) {
      if (action == _actionTaken || action == _actionSkip) {
        await _showSyncFeedback(
          payload: payload,
          markAsTaken: action == _actionTaken,
          queued: true,
        );
      }
    }
  }

  // =========================================================================
  // PRIVATE: Notification details builders
  // =========================================================================

  static NotificationDetails _doseDetails() => NotificationDetails(
    android: AndroidNotificationDetails(
      _doseChannelId, _doseChannelName,
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(_doseSound),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 900, 350, 1100, 350, 1300]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: 'DawaTime',
      channelShowBadge: true,
      autoCancel: true,
      actions: const [
        AndroidNotificationAction(
          _actionTaken, 'تناولت / Taken',
          showsUserInterface: false, cancelNotification: true,
        ),
        AndroidNotificationAction(
          _actionSkip, 'تخطي / Skip',
          showsUserInterface: false, cancelNotification: true,
        ),
        AndroidNotificationAction(
          _actionSnooze30, 'تأجيل 30د / Snooze 30m',
          showsUserInterface: false, cancelNotification: true,
        ),
      ],
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static NotificationDetails _stockDetails() => NotificationDetails(
    android: AndroidNotificationDetails(
      _stockChannelId, _stockChannelName,
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(_stockSound),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 700]),
      audioAttributesUsage: AudioAttributesUsage.notification,
      ticker: 'DawaTime',
      channelShowBadge: true,
      autoCancel: true,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  static const NotificationDetails _syncDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _syncChannelId, _syncChannelName,
      icon: '@mipmap/ic_launcher',
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      channelShowBadge: false,
      autoCancel: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    ),
  );

  // =========================================================================
  // PRIVATE: Schedulers
  // =========================================================================

  static Future<void> _scheduleDoseSafely({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    String? payload,
  }) async {
    await _ensureAndroidPermissions();
    try {
      await _plugin.zonedSchedule(
        id, title, body, scheduledAt, _doseDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      // Retry requesting exact alarm permission then try once more
      final android_ = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android_?.requestExactAlarmsPermission();
      try {
        await _plugin.zonedSchedule(
          id, title, body, scheduledAt, _doseDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (_) {
        // Final fallback: inexact
        await _plugin.zonedSchedule(
          id, title, body, scheduledAt, _doseDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
    }
  }

  static Future<void> _scheduleStockSafely({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
  }) async {
    await _ensureBasicPermission();
    try {
      await _plugin.zonedSchedule(
        id, title, body, scheduledAt, _stockDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Ignore on platforms that don't support scheduling
    }
  }

  // =========================================================================
  // PRIVATE: Snooze
  // =========================================================================

  static Future<void> _executeSnooze({
    required _DosePayload payload,
    required int minutes,
  }) async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();
    final snoozeAt = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    final snoozeId = _snoozeId(payload, minutes);
    await scheduleOneTimeReminder(
      id: snoozeId,
      title: payload.titleEn.isEmpty ? 'DawaTime 💊' : payload.titleEn,
      body: payload.bodyEn.isEmpty
          ? 'Time to take ${payload.medicationName}'
          : payload.bodyEn,
      reminderAt: snoozeAt.toLocal(),
      medicationId: payload.medicationId,
      medicationName: payload.medicationName,
      medicationDose: payload.medicationDose,
    );
  }

  static int _snoozeId(_DosePayload p, int minutes) {
    final seed = '${p.medicationId}_${p.notificationId}_${p.hour}_${p.minute}_$minutes';
    final salt = DateTime.now().microsecondsSinceEpoch.remainder(1000000);
    return (seed.hashCode.abs() + salt + minutes * 31).remainder(2147483000);
  }

  // =========================================================================
  // PRIVATE: Dose status (Take / Skip from notification)
  // =========================================================================

  static Future<bool> _commitDoseStatus({
    required _DosePayload payload,
    required bool markAsTaken,
  }) async {
    if (payload.medicationId.isEmpty) return false;
    await _ensureFirebaseReady();
    await _ensureAuthLoaded();
    if (FirebaseAuth.instance.currentUser == null) return false;

    final fs  = FirebaseFirestore.instance;
    final now = DateTime.now().toLocal();
    final scheduledAt = _resolveScheduledAt(payload, now);
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    final medRef    = fs.collection('medications').doc(payload.medicationId);
    final reportRef = fs.collection('medication_reports').doc(payload.medicationId);

    late DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await medRef.get(const GetOptions(source: Source.serverAndCache));
    } on FirebaseException catch (e) {
      if (_isOffline(e)) {
        await _optimisticWrite(
          fs: fs, payload: payload, markAsTaken: markAsTaken,
          scheduledAt: scheduledAt, recordedAt: now,
        );
        return true;
      }
      rethrow;
    }

    if (!snap.exists) {
      await _optimisticWrite(
        fs: fs, payload: payload, markAsTaken: markAsTaken,
        scheduledAt: scheduledAt, recordedAt: now,
      );
      return true;
    }

    final data = snap.data()!;
    if ((data['userId'] as String? ?? '') !=
        FirebaseAuth.instance.currentUser?.uid) {
      return false;
    }

    final ids = (data['notificationIds'] as List? ?? [])
        .whereType<num>().map((v) => v.toInt()).toList();
    final currentRemaining =
        (data['remainingQuantity'] as num?)?.toInt() ??
        (data['quantity'] as num?)?.toInt() ?? 0;

    if (markAsTaken) {
      final taken = Map<String, dynamic>.from(
          data['takenDoseLogs'] as Map? ?? {});
      if (taken.containsKey(key)) return false; // already recorded

      final nextRemaining = (currentRemaining - 1).clamp(0, 1000000);
      final archive = nextRemaining <= 0;
      final nextTaken   = {...taken,  key: Timestamp.fromDate(now)};
      final nextSkipped = Map<String, dynamic>.from(
          data['skippedDoseLogs'] as Map? ?? {})..remove(key);

      final reportData = _reportFromRaw(
        medicationId: payload.medicationId, raw: data,
        takenLogs: nextTaken, skippedLogs: nextSkipped,
        remaining: archive ? 0 : nextRemaining,
        isArchived: archive, archivedAt: archive ? now : null,
        isDeleted: archive,
        deletedReason: archive ? 'out_of_stock' : null,
        deletedAt: archive ? now : null,
      );
      await reportRef.set(reportData, SetOptions(merge: true));

      if (archive) {
        await medRef.delete();
        await cancelNotifications(ids);
        await cancelNotification(
            lowStockNotificationIdForMedication(payload.medicationId));
      } else {
        await medRef.set({
          'takenDoseLogs': nextTaken,
          'skippedDoseLogs': nextSkipped,
          'remainingQuantity': nextRemaining,
          'isArchived': false,
          'archivedAt': null,
        }, SetOptions(merge: true));
        // Reschedule stock reminders with updated remaining count
        final dosesPerDay = (data['doseTimes'] as List? ?? []).length
            .clamp(1, 24);
        final interval = (data['intervalDays'] as num?)?.toInt() ?? 1;
        await syncMedicationStockReminders(
          medicationId: payload.medicationId,
          medicationName: payload.medicationName,
          totalQuantity: (data['quantity'] as num?)?.toInt() ?? 1,
          remainingQuantity: nextRemaining,
          dosesPerDay: dosesPerDay,
          intervalDays: interval,
          isArabic: false, // background: default English; UI re-syncs on open
        );
      }
    } else {
      // Skip
      final skipped = Map<String, dynamic>.from(
          data['skippedDoseLogs'] as Map? ?? {});
      final nextSkipped = {...skipped, key: Timestamp.fromDate(now)};
      final nextTaken   = Map<String, dynamic>.from(
          data['takenDoseLogs'] as Map? ?? {})..remove(key);

      await medRef.set({
        'skippedDoseLogs': nextSkipped,
        'takenDoseLogs': nextTaken,
      }, SetOptions(merge: true));
      await reportRef.set(
        _reportFromRaw(
          medicationId: payload.medicationId, raw: data,
          takenLogs: nextTaken, skippedLogs: nextSkipped,
        ),
        SetOptions(merge: true),
      );
    }
    return false;
  }

  // ── Optimistic offline write ───────────────────────────────────────────

  static Future<void> _optimisticWrite({
    required FirebaseFirestore fs,
    required _DosePayload payload,
    required bool markAsTaken,
    required DateTime scheduledAt,
    required DateTime recordedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    final ts  = Timestamp.fromDate(recordedAt);
    final med = fs.collection('medications').doc(payload.medicationId);
    final rep = fs.collection('medication_reports').doc(payload.medicationId);
    if (markAsTaken) {
      await med.set({
        'takenDoseLogs.$key': ts,
        'skippedDoseLogs.$key': FieldValue.delete(),
        'remainingQuantity': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      await rep.set({
        'userId': uid,
        'sourceMedicationId': payload.medicationId,
        'name': payload.medicationName,
        'dose': payload.medicationDose,
        'takenDoseLogs.$key': ts,
        'skippedDoseLogs.$key': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await med.set({
        'skippedDoseLogs.$key': ts,
        'takenDoseLogs.$key': FieldValue.delete(),
      }, SetOptions(merge: true));
      await rep.set({
        'userId': uid,
        'sourceMedicationId': payload.medicationId,
        'name': payload.medicationName,
        'dose': payload.medicationDose,
        'skippedDoseLogs.$key': ts,
        'takenDoseLogs.$key': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // =========================================================================
  // PRIVATE: Sync feedback notification
  // =========================================================================

  static Future<void> _showSyncFeedback({
    required _DosePayload payload,
    required bool markAsTaken,
    required bool queued,
  }) async {
    await _ensureBasicPermission();
    final nameAr = payload.medicationName.isEmpty ? 'الدواء' : payload.medicationName;
    final String bodyAr;
    if (queued) {
      bodyAr = 'تم تسجيل ${markAsTaken ? "تناول" : "تخطي"} $nameAr محلياً، وسيُزامن عند الاتصال.';
    } else {
      bodyAr = 'تم تسجيل $nameAr كـ${markAsTaken ? "مأخوذ ✅" : "متخطى ⏭️"}.';
    }
    final id = 1800000000 +
        ('${payload.medicationId}_${payload.scheduledAtIso}_$markAsTaken'
            .hashCode.abs() % 100000000);
    await _plugin.show(id, 'DawaTime', bodyAr, _syncDetails);
  }

  // =========================================================================
  // PRIVATE: Message builders (bilingual)
  // =========================================================================

  static _BilingualMsg _buildStockMessage({
    required String medicationName,
    required int remaining,
    required int daysLeft,
    required bool isCritical,
    required bool isArabic,
  }) {
    if (isCritical) {
      return _BilingualMsg(
        titleAr: '⚠️ دواء تايم – تحذير عاجل',
        titleEn: '⚠️ DawaTime – Urgent',
        bodyAr: 'تبقّت $remaining جرعة فقط من $medicationName. أعِد التعبئة فوراً!',
        bodyEn: 'Only $remaining dose(s) of $medicationName left. Refill urgently!',
      );
    }
    if (daysLeft <= 1) {
      return _BilingualMsg(
        titleAr: '⚠️ دواء تايم – ينفد قريباً',
        titleEn: '⚠️ DawaTime – Running Out',
        bodyAr: '$medicationName سينفد اليوم ($remaining جرعة). أعِد التعبئة.',
        bodyEn: '$medicationName runs out today ($remaining dose(s)). Refill now.',
      );
    }
    return _BilingualMsg(
      titleAr: '💊 دواء تايم – كمية منخفضة',
      titleEn: '💊 DawaTime – Low Stock',
      bodyAr: '$medicationName: تبقّت $remaining جرعة (≈$daysLeft يوم). فكّر في التعبئة.',
      bodyEn: '$medicationName: $remaining dose(s) left (~$daysLeft days). Consider refilling.',
    );
  }

  static _BilingualMsg _buildInventoryMessage({
    required String itemName,
    required int quantity,
    required int minQuantity,
    required bool isArabic,
  }) {
    if (quantity <= 0) {
      return _BilingualMsg(
        titleAr: '⚠️ دواء تايم – نفاد المخزون',
        titleEn: '⚠️ DawaTime – Out of Stock',
        bodyAr: 'نفد $itemName من المخزون تماماً. أعِد التعبئة فوراً!',
        bodyEn: '$itemName is completely out of stock. Refill immediately!',
      );
    }
    return _BilingualMsg(
      titleAr: '📦 دواء تايم – مخزون منخفض',
      titleEn: '📦 DawaTime – Low Inventory',
      bodyAr: 'مخزون $itemName منخفض ($quantity متبقٍّ، الحد الأدنى $minQuantity).',
      bodyEn: '$itemName stock is low ($quantity left, min $minQuantity).',
    );
  }

  // =========================================================================
  // PRIVATE: ID helpers
  // =========================================================================

  static int _stockSlotId(String medId, int dayOffset, int hour, int minute) {
    final seed = '${medId}_stock_${dayOffset}_${hour}_$minute';
    return 1100000000 + (seed.hashCode.abs() % 800000000);
  }

  static int _inventorySlotId(String itemId, int hour, int minute) {
    final seed = '${itemId}_inv_${hour}_$minute';
    return 1900000000 + (seed.hashCode.abs() % 90000000);
  }

  // =========================================================================
  // PRIVATE: Cancel helpers
  // =========================================================================

  static Future<void> _cancelAllStockRemindersForMedication(
      String medicationId) async {
    await cancelNotification(
        lowStockNotificationIdForMedication(medicationId));
    for (var day = 0; day <= reminderPlanningWindowDays + _lowStockLeadDays + 1; day++) {
      for (final t in _stockTimes) {
        await cancelNotification(
            _stockSlotId(medicationId, day, t.hour, t.minute));
      }
    }
  }

  static Future<void> _cancelAllInventoryRemindersForItem(
      String itemId) async {
    await cancelNotification(inventoryNotificationIdForItem(itemId));
    for (final t in _stockTimes) {
      await cancelNotification(_inventorySlotId(itemId, t.hour, t.minute));
    }
  }

  // =========================================================================
  // PRIVATE: Permissions
  // =========================================================================

  static Future<void> _ensureAndroidPermissions() async {
    if (kIsWeb) return;
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (a == null) return;
    try {
      if (await a.areNotificationsEnabled() == false) {
        await a.requestNotificationsPermission();
      }
    } catch (_) {}
    try {
      if (await a.canScheduleExactNotifications() == false) {
        await a.requestExactAlarmsPermission();
      }
    } catch (_) {}
    try {
      await a.requestFullScreenIntentPermission();
    } catch (_) {}
  }

  static Future<void> _ensureBasicPermission() async {
    if (kIsWeb) return;
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (a == null) return;
    try {
      if (await a.areNotificationsEnabled() == false) {
        await a.requestNotificationsPermission();
      }
    } catch (_) {}
  }

  // =========================================================================
  // PRIVATE: Firebase helpers
  // =========================================================================

  static Future<void> _ensureFirebaseReady() async {
    if (Firebase.apps.isNotEmpty) return;
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      await Firebase.initializeApp();
    }
    if (!kDebugMode) {
      try {
        await FirebaseAppCheck.instance
            .activate(
              androidProvider: AndroidProvider.playIntegrity,
              appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
  }

  static Future<void> _ensureAuthLoaded() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;
    try {
      await auth.authStateChanges().first.timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  static bool _isOffline(FirebaseException e) =>
      e.code == 'unavailable' ||
      e.code == 'deadline-exceeded' ||
      e.code == 'cancelled' ||
      e.code == 'unknown';

  // =========================================================================
  // PRIVATE: Timezone
  // =========================================================================

  static Future<void> _configureLocalTimeZone() async {
    try {
      final name = await _tzChannel.invokeMethod<String>('getLocalTimeZone');
      if (name == null || name.isEmpty) throw StateError('empty');
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(_fixedOffsetZone());
    }
  }

  static tz.Location _fixedOffsetZone() {
    final h    = DateTime.now().timeZoneOffset.inHours;
    final sign = h <= 0 ? '+' : '-';
    try { return tz.getLocation('Etc/GMT$sign${h.abs()}'); } catch (_) {
      return tz.UTC;
    }
  }

  // =========================================================================
  // PRIVATE: Slot builder for dose reminders
  // =========================================================================

  static List<tz.TZDateTime> _buildIntervalSlots({
    required List<MedicationDoseTime> doseTimes,
    required int intervalDays,
    required DateTime anchorDate,
  }) {
    final now    = tz.TZDateTime.now(tz.local);
    final anchor = tz.TZDateTime(
      tz.local,
      anchorDate.year, anchorDate.month, anchorDate.day,
    );
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    final elapsed = today.difference(anchor).inDays;
    final startOff = elapsed <= 0
        ? 0
        : elapsed + ((intervalDays - (elapsed % intervalDays)) % intervalDays);
    final endOff = startOff + reminderPlanningWindowDays;

    final sorted = List<MedicationDoseTime>.from(doseTimes)
      ..sort((a, b) => a.sortValue.compareTo(b.sortValue));

    final slots = <tz.TZDateTime>[];
    for (var off = startOff; off <= endOff; off += intervalDays) {
      final day = anchor.add(Duration(days: off));
      for (final dt in sorted) {
        final slot = tz.TZDateTime(
          tz.local, day.year, day.month, day.day, dt.hour, dt.minute,
        );
        if (slot.isAfter(now)) slots.add(slot);
      }
    }

    // Guarantee at least one slot
    if (slots.isEmpty && sorted.isNotEmpty) {
      final next = now.add(Duration(days: intervalDays));
      slots.add(tz.TZDateTime(
        tz.local, next.year, next.month, next.day,
        sorted.first.hour, sorted.first.minute,
      ));
    }
    return slots;
  }

  // =========================================================================
  // PRIVATE: scheduledAt resolver (for background action)
  // =========================================================================

  static DateTime _resolveScheduledAt(_DosePayload p, DateTime now) {
    if (p.scheduledAtIso.isNotEmpty) {
      final parsed = DateTime.tryParse(p.scheduledAtIso);
      if (parsed != null) return parsed.toLocal();
    }
    final derived = DateTime(now.year, now.month, now.day, p.hour, p.minute);
    final diff = derived.difference(now);
    if (diff > const Duration(minutes: 5))  return derived.subtract(const Duration(days: 1));
    if (diff < const Duration(minutes: -5)) return derived.add(const Duration(days: 1));
    return derived;
  }

  // =========================================================================
  // PRIVATE: Next occurrence of a daily time
  // =========================================================================

  static DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) return today;
    return today.add(const Duration(days: 1));
  }

  // =========================================================================
  // PRIVATE: Report payload builder (from raw Firestore map)
  // =========================================================================

  static Map<String, dynamic> _reportFromRaw({
    required String medicationId,
    required Map<String, dynamic> raw,
    Map<String, dynamic>? takenLogs,
    Map<String, dynamic>? skippedLogs,
    int? remaining,
    bool? isArchived,
    DateTime? archivedAt,
    bool? isDeleted,
    String? deletedReason,
    DateTime? deletedAt,
  }) {
    return {
      'userId': raw['userId'] ?? '',
      'sourceMedicationId': medicationId,
      'name': raw['name'],
      'dose': raw['dose'],
      'form': raw['form'],
      'quantity': raw['quantity'],
      'remainingQuantity': remaining ??
          ((raw['remainingQuantity'] as num?)?.toInt() ??
              (raw['quantity'] as num?)?.toInt() ?? 0),
      'doseUnit': raw['doseUnit'],
      'time': raw['time'],
      'hour': raw['hour'],
      'minute': raw['minute'],
      'frequency': raw['frequency'],
      'doseTimes': raw['doseTimes'] ?? const [],
      'intervalDays': raw['intervalDays'],
      'notificationIds': raw['notificationIds'] ?? const [],
      'takenDoseLogs': takenLogs ??
          Map<String, dynamic>.from(raw['takenDoseLogs'] as Map? ?? {}),
      'skippedDoseLogs': skippedLogs ??
          Map<String, dynamic>.from(raw['skippedDoseLogs'] as Map? ?? {}),
      'isArchived': isArchived ?? (raw['isArchived'] as bool? ?? false),
      'archivedAt': archivedAt == null
          ? raw['archivedAt']
          : Timestamp.fromDate(archivedAt),
      'isDeleted': isDeleted ?? false,
      'deletedReason': deletedReason,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt),
      'createdAt': raw['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // =========================================================================
  // PRIVATE: Foreground response router
  // =========================================================================

  static Future<void> _onForegroundResponse(
      NotificationResponse response) async {
    await handleNotificationAction(response);
  }
}

// =============================================================================
// _DosePayload – JSON-serialisable payload carried inside every dose reminder
// =============================================================================
class _DosePayload {
  const _DosePayload({
    required this.notificationId,
    required this.medicationId,
    required this.medicationName,
    required this.medicationDose,
    required this.hour,
    required this.minute,
    required this.scheduledAtIso,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });

  final int    notificationId;
  final String medicationId;
  final String medicationName;
  final String medicationDose;
  final int    hour;
  final int    minute;
  final String scheduledAtIso;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  String toJson() => jsonEncode({
    'nid': notificationId,
    'mid': medicationId,
    'mn':  medicationName,
    'md':  medicationDose,
    'h':   hour,
    'm':   minute,
    'sat': scheduledAtIso,
    'tar': titleAr,
    'ten': titleEn,
    'bar': bodyAr,
    'ben': bodyEn,
  });

  static _DosePayload? tryParse(String? src) {
    if (src == null || src.isEmpty) return null;
    try {
      final d = jsonDecode(src);
      if (d is! Map<String, dynamic>) return null;
      return _DosePayload(
        notificationId: (d['nid'] as num?)?.toInt() ?? 0,
        medicationId:   d['mid'] as String? ?? '',
        medicationName: d['mn']  as String? ?? '',
        medicationDose: d['md']  as String? ?? '',
        hour:   ((d['h'] as num?)?.toInt() ?? 9).clamp(0, 23),
        minute: ((d['m'] as num?)?.toInt() ?? 0).clamp(0, 59),
        scheduledAtIso: d['sat'] as String? ?? '',
        titleAr: d['tar'] as String? ?? '',
        titleEn: d['ten'] as String? ?? '',
        bodyAr:  d['bar'] as String? ?? '',
        bodyEn:  d['ben'] as String? ?? '',
      );
    } catch (_) { return null; }
  }
}

// =========================================================================
