import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../firebase_options.dart';
import '../models/medication_model.dart';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await NotificationService.handleNotificationAction(
    response,
    fromBackground: true,
  );
}

class NotificationService {
  static const int reminderPlanningWindowDays = 14;
  static const int _maxSchedulesPerMedication = 120;
  static const int _lowStockLeadDays = 2;
  static const String _channelId = 'dawatime_medication_reminders_v7';
  static const String _channelName = 'DawaTime medication reminders';
  static const String _channelDescription =
      'Precise local dose reminders with actions, snooze, and lock-screen visibility.';
  static const String _androidReminderSound = 'dawatime_reminder';
  static const String _actionTaken = 'dose_taken';
  static const String _actionSkip = 'dose_skip';
  static const String _actionSnooze30 = 'dose_snooze_30';
  static const String _actionSnooze60 = 'dose_snooze_60';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _timeZoneChannel = MethodChannel(
    'dawatime/timezone',
  );

  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_androidReminderSound),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        showBadge: true,
      ),
    );
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) {
      return;
    }

    final next = _buildIntervalReminders(
      doseTimes: [MedicationDoseTime(hour: hour, minute: minute)],
      intervalDays: 1,
      anchorDate: DateTime.now(),
    );
    if (next.isEmpty) {
      return;
    }

    await scheduleOneTimeReminder(
      id: id,
      title: title,
      body: body,
      reminderAt: next.first.toLocal(),
    );
  }

  static int requiredNotificationCount({
    required int doseCount,
    required int intervalDays,
  }) {
    final safeDoseCount = doseCount.clamp(1, 24).toInt();
    final safeInterval = intervalDays
        .clamp(1, reminderPlanningWindowDays)
        .toInt();
    final cycleCount = (reminderPlanningWindowDays / safeInterval).ceil() + 1;
    return safeDoseCount * cycleCount;
  }

  static int lowStockNotificationIdForMedication(String medicationId) {
    final hash = medicationId.hashCode.abs();
    return 1000000000 + (hash % 900000000);
  }

  static int inventoryNotificationIdForItem(String itemId) {
    final hash = itemId.hashCode.abs();
    return 1900000000 + (hash % 90000000);
  }

  static Future<void> syncInventoryAlert({
    required String itemId,
    required String itemName,
    required int quantity,
    required int minQuantity,
  }) async {
    if (kIsWeb) {
      return;
    }

    final id = inventoryNotificationIdForItem(itemId);
    await cancelNotification(id);

    if (quantity <= 0) {
      await showImmediateInventoryAlert(
        id: id,
        title: 'DawaTime',
        body: '$itemName is out of stock. Please refill immediately.',
      );
      return;
    }

    if (quantity <= minQuantity) {
      await showImmediateInventoryAlert(
        id: id,
        title: 'DawaTime',
        body: '$itemName stock is low ($quantity left). Please refill soon.',
      );
    }
  }

  static Future<void> showImmediateInventoryAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    await _notifications.show(id, title, body, _lowStockNotificationDetails());
  }

  static Future<void> scheduleMedicationReminders({
    required List<int> ids,
    required String title,
    required String body,
    required List<MedicationDoseTime> doseTimes,
    required int intervalDays,
    required DateTime anchorDate,
    String? medicationId,
    String? medicationName,
    String? medicationDose,
  }) async {
    if (kIsWeb || doseTimes.isEmpty) {
      return;
    }
    await _configureLocalTimeZone();

    final safeInterval = intervalDays
        .clamp(1, reminderPlanningWindowDays)
        .toInt();
    final localizedAnchorDate = anchorDate.toLocal();
    final upcomingReminders = _buildIntervalReminders(
      doseTimes: doseTimes,
      intervalDays: safeInterval,
      anchorDate: localizedAnchorDate,
    );

    final scheduleCount = upcomingReminders.length
        .clamp(0, _maxSchedulesPerMedication)
        .toInt();
    if (ids.length < scheduleCount) {
      throw ArgumentError(
        'Not enough notification ids for interval-based reminders.',
      );
    }

    for (var index = 0; index < scheduleCount; index++) {
      final scheduled = upcomingReminders[index];
      final payload = _DoseReminderPayload(
        notificationId: ids[index],
        medicationId: medicationId ?? '',
        medicationName: medicationName ?? title,
        medicationDose: medicationDose ?? '',
        hour: scheduled.hour,
        minute: scheduled.minute,
        scheduledAtIso: scheduled.toLocal().toIso8601String(),
        title: title,
        body: body,
      ).toJson();
      await _scheduleReminderSafely(
        id: ids[index],
        title: title,
        body: body,
        scheduledAt: scheduled,
        payload: payload,
      );
    }
  }

  static Future<void> scheduleOneTimeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime reminderAt,
    String? medicationId,
    String? medicationName,
    String? medicationDose,
  }) async {
    if (kIsWeb) {
      return;
    }
    await _configureLocalTimeZone();

    final scheduledDate = reminderAt.toLocal();
    final payload = _DoseReminderPayload(
      notificationId: id,
      medicationId: medicationId ?? '',
      medicationName: medicationName ?? title,
      medicationDose: medicationDose ?? '',
      hour: scheduledDate.hour,
      minute: scheduledDate.minute,
      scheduledAtIso: scheduledDate.toIso8601String(),
      title: title,
      body: body,
    ).toJson();

    await _scheduleReminderSafely(
      id: id,
      title: title,
      body: body,
      scheduledAt: tz.TZDateTime.from(scheduledDate, tz.local),
      payload: payload,
    );
  }

  static Future<void> scheduleLowStockReminder({
    required int id,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    if (kIsWeb) {
      return;
    }
    await _configureLocalTimeZone();

    final now = DateTime.now().toLocal();
    final safeReminderAt = reminderAt.isAfter(now)
        ? reminderAt
        : now.add(const Duration(minutes: 1));

    await _scheduleReminderSafely(
      id: id,
      title: title,
      body: body,
      scheduledAt: tz.TZDateTime.from(safeReminderAt, tz.local),
      details: _lowStockNotificationDetails(),
    );
  }

  static Future<void> cancelNotifications(List<int> ids) async {
    if (kIsWeb) {
      return;
    }

    for (final id in ids) {
      await _notifications.cancel(id);
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      return;
    }

    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      return;
    }

    await _notifications.cancelAll();
  }

  static Future<void> handleNotificationAction(
    NotificationResponse response, {
    bool fromBackground = false,
  }) async {
    if (kIsWeb) {
      return;
    }

    final payload = _DoseReminderPayload.tryParse(response.payload);
    if (payload == null) {
      return;
    }

    final actionId = response.actionId ?? '';
    if (actionId.isEmpty) {
      return;
    }

    try {
      if (actionId == _actionSnooze30 || actionId == _actionSnooze60) {
        final minutes = actionId == _actionSnooze30 ? 30 : 60;
        await _scheduleSnoozeReminder(payload: payload, minutes: minutes);
        return;
      }

      if (actionId == _actionTaken) {
        await _markDoseStatus(payload: payload, markAsTaken: true);
        return;
      }

      if (actionId == _actionSkip) {
        await _markDoseStatus(payload: payload, markAsTaken: false);
        return;
      }
    } catch (_) {
      // Ignore action failures in background isolate to prevent crashes.
    }

    if (fromBackground) {
      return;
    }
  }

  static NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(_androidReminderSound),
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[
          0,
          900,
          350,
          1100,
          350,
          1300,
        ]),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        ticker: 'DawaTime reminder',
        channelShowBadge: true,
        autoCancel: true,
        ongoing: false,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionTaken,
            'Take',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionSnooze30,
            'Snooze 30m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionSnooze60,
            'Snooze 60m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionSkip,
            'Skip',
            showsUserInterface: false,
            cancelNotification: true,
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
  }

  static NotificationDetails _lowStockNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: '@mipmap/ic_launcher',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: false,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(_androidReminderSound),
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 500, 250, 700]),
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        ticker: 'DawaTime low stock',
        channelShowBadge: true,
        autoCancel: true,
        ongoing: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    await handleNotificationAction(response);
  }

  static Future<void> _scheduleReminderSafely({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
    NotificationDetails? details,
  }) async {
    await _ensureAndroidPermissionState();
    final resolvedDetails = details ?? _notificationDetails();
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        resolvedDetails,
        // Always try exact first for on-time medication alerts.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestExactAlarmsPermission();
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledAt,
          resolvedDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        return;
      } catch (_) {}

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        resolvedDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  static Future<void> _ensureAndroidPermissionState() async {
    if (kIsWeb) {
      return;
    }
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation == null) {
      return;
    }

    try {
      final enabled = await androidImplementation.areNotificationsEnabled();
      if (enabled == false) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (_) {
      // Continue gracefully on OEMs that do not expose this check reliably.
    }

    try {
      final canExact =
          await androidImplementation.canScheduleExactNotifications();
      if (canExact == false) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (_) {
      // Continue; scheduler has inexact fallback anyway.
    }

    try {
      await androidImplementation.requestFullScreenIntentPermission();
    } catch (_) {
      // Continue gracefully if OEM/framework doesn't expose this API.
    }
  }

  static Future<void> _scheduleSnoozeReminder({
    required _DoseReminderPayload payload,
    required int minutes,
  }) async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(minutes: minutes));
    final snoozeId = _snoozeNotificationId(payload, minutes);
    await scheduleOneTimeReminder(
      id: snoozeId,
      title: payload.title.isEmpty ? 'DawaTime' : payload.title,
      body: payload.body.isEmpty
          ? 'It is time to take ${payload.medicationName}'
          : payload.body,
      reminderAt: scheduled.toLocal(),
      medicationId: payload.medicationId,
      medicationName: payload.medicationName,
      medicationDose: payload.medicationDose,
    );
  }

  static int _snoozeNotificationId(_DoseReminderPayload payload, int minutes) {
    final seed =
        '${payload.medicationId}_${payload.notificationId}_${payload.hour}_${payload.minute}_$minutes';
    final hash = seed.hashCode.abs();
    final timeSalt = DateTime.now().microsecondsSinceEpoch.remainder(1000000);
    return (hash + timeSalt + (minutes * 31)).remainder(2147483000);
  }

  static Future<void> _markDoseStatus({
    required _DoseReminderPayload payload,
    required bool markAsTaken,
  }) async {
    if (payload.medicationId.isEmpty) {
      return;
    }

    await _ensureFirebaseInitialized();
    await _ensureAuthenticatedUserLoaded();
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now().toLocal();
    final scheduledAt = _resolveScheduledAt(payload, now);
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    final medicationRef = firestore
        .collection('medications')
        .doc(payload.medicationId);
    _DoseStatusResult result;
    try {
      result = await firestore.runTransaction<_DoseStatusResult>((
        transaction,
      ) async {
        final snapshot = await transaction.get(medicationRef);
        if (!snapshot.exists) {
          return const _DoseStatusResult(updated: false);
        }

        final rawData = snapshot.data() ?? const <String, dynamic>{};
        final data = Map<String, dynamic>.from(rawData);
        final ownerId = data['userId'] as String? ?? '';
        if (ownerId != FirebaseAuth.instance.currentUser?.uid) {
          return const _DoseStatusResult(updated: false);
        }

        final notificationIds =
            (data['notificationIds'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<num>()
                .map((value) => value.toInt())
                .toList(growable: false);
        final currentRemaining =
            (data['remainingQuantity'] as num?)?.toInt() ??
            (data['quantity'] as num?)?.toInt() ??
            0;

        if (markAsTaken) {
          final takenLogs = Map<String, dynamic>.from(
            data['takenDoseLogs'] as Map<String, dynamic>? ??
                const <String, dynamic>{},
          );
          if (takenLogs.containsKey(key)) {
            return _DoseStatusResult(
              notificationIds: notificationIds,
              remainingQuantity: currentRemaining,
              medicationData: data,
              updated: false,
            );
          }

          final nextRemaining = (currentRemaining - 1).clamp(0, 1000000).toInt();
          final shouldArchive = nextRemaining <= 0;
          transaction.set(medicationRef, {
            'takenDoseLogs.$key': Timestamp.fromDate(now),
            'skippedDoseLogs.$key': FieldValue.delete(),
            'remainingQuantity': shouldArchive ? 0 : nextRemaining,
            'isArchived': shouldArchive,
            'archivedAt': shouldArchive ? Timestamp.fromDate(now) : null,
          }, SetOptions(merge: true));

          return _DoseStatusResult(
            archivedMedication: shouldArchive,
            notificationIds: notificationIds,
            remainingQuantity: shouldArchive ? 0 : nextRemaining,
            medicationData: Map<String, dynamic>.from(data)
              ..['remainingQuantity'] = shouldArchive ? 0 : nextRemaining,
            updated: true,
          );
        }

        transaction.set(medicationRef, {
          'skippedDoseLogs.$key': Timestamp.fromDate(now),
          'takenDoseLogs.$key': FieldValue.delete(),
        }, SetOptions(merge: true));

        return _DoseStatusResult(
          notificationIds: notificationIds,
          remainingQuantity: currentRemaining,
          medicationData: data,
          updated: true,
        );
      });
    } catch (_) {
      final snapshot = await medicationRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (!snapshot.exists) {
        return;
      }
      final data = snapshot.data() ?? const <String, dynamic>{};
      final ownerId = data['userId'] as String? ?? '';
      if (ownerId != FirebaseAuth.instance.currentUser?.uid) {
        return;
      }

      final notificationIds =
          (data['notificationIds'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<num>()
              .map((value) => value.toInt())
              .toList(growable: false);
      final currentRemaining =
          (data['remainingQuantity'] as num?)?.toInt() ??
          (data['quantity'] as num?)?.toInt() ??
          0;

      if (markAsTaken) {
        final takenLogs = Map<String, dynamic>.from(
          data['takenDoseLogs'] as Map<String, dynamic>? ??
              const <String, dynamic>{},
        );
        if (takenLogs.containsKey(key)) {
          result = _DoseStatusResult(
            notificationIds: notificationIds,
            remainingQuantity: currentRemaining,
            medicationData: data,
            updated: false,
          );
        } else {
          final nextRemaining = (currentRemaining - 1).clamp(0, 1000000).toInt();
          final shouldArchive = nextRemaining <= 0;
          await medicationRef.set({
            'takenDoseLogs.$key': Timestamp.fromDate(now),
            'skippedDoseLogs.$key': FieldValue.delete(),
            'remainingQuantity': shouldArchive ? 0 : nextRemaining,
            'isArchived': shouldArchive,
            'archivedAt': shouldArchive ? Timestamp.fromDate(now) : null,
          }, SetOptions(merge: true));
          result = _DoseStatusResult(
            archivedMedication: shouldArchive,
            notificationIds: notificationIds,
            remainingQuantity: shouldArchive ? 0 : nextRemaining,
            medicationData: Map<String, dynamic>.from(data)
              ..['remainingQuantity'] = shouldArchive ? 0 : nextRemaining,
            updated: true,
          );
        }
      } else {
        await medicationRef.set({
          'skippedDoseLogs.$key': Timestamp.fromDate(now),
          'takenDoseLogs.$key': FieldValue.delete(),
        }, SetOptions(merge: true));
        result = _DoseStatusResult(
          notificationIds: notificationIds,
          remainingQuantity: currentRemaining,
          medicationData: data,
          updated: true,
        );
      }
    }

    if (result.archivedMedication) {
      if (result.notificationIds.isNotEmpty) {
        await cancelNotifications(result.notificationIds);
      }
      await cancelNotification(
        lowStockNotificationIdForMedication(payload.medicationId),
      );
      return;
    }

    if (markAsTaken && result.medicationData != null) {
      await _maybeScheduleLowStockFromData(
        medicationId: payload.medicationId,
        medicationData: result.medicationData!,
      );
    }
  }

  static Future<void> _maybeScheduleLowStockFromData({
    required String medicationId,
    required Map<String, dynamic> medicationData,
  }) async {
    final lowStockId = lowStockNotificationIdForMedication(medicationId);
    await cancelNotification(lowStockId);

    final reminderAt = _estimateLowStockReminderDateFromData(medicationData);
    if (reminderAt == null) {
      return;
    }

    final medicationName = medicationData['name'] as String? ?? 'Medication';
    await scheduleLowStockReminder(
      id: lowStockId,
      title: 'DawaTime',
      body: '$medicationName stock is running low. Please refill soon.',
      reminderAt: reminderAt,
    );
  }

  static DateTime? _estimateLowStockReminderDateFromData(
    Map<String, dynamic> data,
  ) {
    final remainingQuantity =
        (data['remainingQuantity'] as num?)?.toInt() ??
        (data['quantity'] as num?)?.toInt() ??
        0;
    if (remainingQuantity <= 0) {
      return null;
    }

    var dosesPerScheduledDay = 0;
    final doseTimes = data['doseTimes'];
    if (doseTimes is List) {
      dosesPerScheduledDay = doseTimes.whereType<Map>().length;
    }
    if (dosesPerScheduledDay <= 0) {
      dosesPerScheduledDay = ((data['frequency'] as num?)?.toInt() ?? 1)
          .clamp(1, 24)
          .toInt();
    }

    final intervalDays = ((data['intervalDays'] as num?)?.toInt() ?? 1)
        .clamp(1, 365)
        .toInt();
    final calendarDaysLeft =
        ((remainingQuantity / dosesPerScheduledDay).ceil() * intervalDays)
            .clamp(1, 3650)
            .toInt();

    final now = DateTime.now().toLocal();
    final lowStockDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: calendarDaysLeft - _lowStockLeadDays));
    final reminderAt = DateTime(
      lowStockDate.year,
      lowStockDate.month,
      lowStockDate.day,
      9,
      0,
    );

    if (reminderAt.isBefore(now.add(const Duration(minutes: 1)))) {
      return now.add(const Duration(minutes: 1));
    }
    return reminderAt;
  }

  static DateTime _resolveScheduledAt(
    _DoseReminderPayload payload,
    DateTime now,
  ) {
    if (payload.scheduledAtIso.isNotEmpty) {
      final parsed = DateTime.tryParse(payload.scheduledAtIso);
      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    final derived = DateTime(
      now.year,
      now.month,
      now.day,
      payload.hour,
      payload.minute,
    );
    if (derived.isAfter(now.add(const Duration(minutes: 5)))) {
      return derived.subtract(const Duration(days: 1));
    }
    return derived;
  }

  static Future<void> _configureLocalTimeZone() async {
    try {
      final deviceTimeZone = await _timeZoneChannel.invokeMethod<String>(
        'getLocalTimeZone',
      );
      if (deviceTimeZone == null || deviceTimeZone.isEmpty) {
        throw StateError('No timezone returned from the device.');
      }
      tz.setLocalLocation(tz.getLocation(deviceTimeZone));
    } catch (_) {
      // Fallback to a fixed-offset zone from device clock to avoid UTC drift.
      tz.setLocalLocation(_fixedOffsetLocation());
    }
  }

  static tz.Location _fixedOffsetLocation() {
    final offset = DateTime.now().timeZoneOffset;
    final totalHours = offset.inHours;
    final sign = totalHours <= 0 ? '+' : '-';
    final zoneName = 'Etc/GMT$sign${totalHours.abs()}';
    try {
      return tz.getLocation(zoneName);
    } catch (_) {
      return tz.UTC;
    }
  }

  static Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      await Firebase.initializeApp();
    }
  }

  static Future<void> _ensureAuthenticatedUserLoaded() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return;
    }

    try {
      await auth.authStateChanges().first.timeout(const Duration(seconds: 15));
    } catch (_) {
      // Keep proceeding gracefully; if still null, caller handles it.
    }
  }

  static List<tz.TZDateTime> _buildIntervalReminders({
    required List<MedicationDoseTime> doseTimes,
    required int intervalDays,
    required DateTime anchorDate,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final normalizedAnchorDate = anchorDate.toLocal();
    final anchor = tz.TZDateTime(
      tz.local,
      normalizedAnchorDate.year,
      normalizedAnchorDate.month,
      normalizedAnchorDate.day,
    );
    final sortedTimes = List<MedicationDoseTime>.from(doseTimes)
      ..sort((a, b) => a.sortValue.compareTo(b.sortValue));

    final reminders = <tz.TZDateTime>[];
    for (
      var offset = 0;
      offset <= reminderPlanningWindowDays;
      offset += intervalDays
    ) {
      final scheduledDay = anchor.add(Duration(days: offset));
      for (final doseTime in sortedTimes) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDay.year,
          scheduledDay.month,
          scheduledDay.day,
          doseTime.hour,
          doseTime.minute,
        );
        if (scheduledDate.isAfter(now)) {
          reminders.add(scheduledDate);
        }
      }
    }

    if (reminders.isEmpty && sortedTimes.isNotEmpty) {
      final nextDay = now.add(Duration(days: intervalDays));
      final firstDose = sortedTimes.first;
      reminders.add(
        tz.TZDateTime(
          tz.local,
          nextDay.year,
          nextDay.month,
          nextDay.day,
          firstDose.hour,
          firstDose.minute,
        ),
      );
    }

    return reminders;
  }
}

class _DoseStatusResult {
  const _DoseStatusResult({
    this.archivedMedication = false,
    this.notificationIds = const <int>[],
    this.remainingQuantity = 0,
    this.medicationData,
    this.updated = false,
  });

  final bool archivedMedication;
  final List<int> notificationIds;
  final int remainingQuantity;
  final Map<String, dynamic>? medicationData;
  final bool updated;
}

class _DoseReminderPayload {
  const _DoseReminderPayload({
    required this.notificationId,
    required this.medicationId,
    required this.medicationName,
    required this.medicationDose,
    required this.hour,
    required this.minute,
    required this.scheduledAtIso,
    required this.title,
    required this.body,
  });

  final int notificationId;
  final String medicationId;
  final String medicationName;
  final String medicationDose;
  final int hour;
  final int minute;
  final String scheduledAtIso;
  final String title;
  final String body;

  String toJson() {
    return jsonEncode(<String, Object>{
      'notificationId': notificationId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'medicationDose': medicationDose,
      'hour': hour,
      'minute': minute,
      'scheduledAtIso': scheduledAtIso,
      'title': title,
      'body': body,
    });
  }

  static _DoseReminderPayload? tryParse(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return _DoseReminderPayload(
        notificationId: (decoded['notificationId'] as num?)?.toInt() ?? 0,
        medicationId: decoded['medicationId'] as String? ?? '',
        medicationName: decoded['medicationName'] as String? ?? '',
        medicationDose: decoded['medicationDose'] as String? ?? '',
        hour: ((decoded['hour'] as num?)?.toInt() ?? 9).clamp(0, 23).toInt(),
        minute: ((decoded['minute'] as num?)?.toInt() ?? 0)
            .clamp(0, 59)
            .toInt(),
        scheduledAtIso: decoded['scheduledAtIso'] as String? ?? '',
        title: decoded['title'] as String? ?? '',
        body: decoded['body'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
