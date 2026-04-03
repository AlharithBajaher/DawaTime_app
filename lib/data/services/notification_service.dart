import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    tz.initializeTimeZones();
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

    await scheduleMedicationReminders(
      ids: [id],
      title: title,
      body: body,
      startHour: hour,
      startMinute: minute,
      frequency: 1,
    );
  }

  static Future<void> scheduleMedicationReminders({
    required List<int> ids,
    required String title,
    required String body,
    required int startHour,
    required int startMinute,
    required int frequency,
  }) async {
    if (kIsWeb) {
      return;
    }

    if (ids.length < frequency) {
      throw ArgumentError('Not enough notification ids for the frequency.');
    }

    final intervalHours = (24 / frequency).round();

    for (var index = 0; index < frequency; index++) {
      final hour = (startHour + (intervalHours * index)) % 24;

      await _notifications.zonedSchedule(
        ids[index],
        title,
        body,
        _nextInstanceOfTime(hour, startMinute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Medication Reminder',
            channelDescription: 'Daily reminders for scheduled medications.',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelNotifications(List<int> ids) async {
    if (kIsWeb) {
      return;
    }

    for (final id in ids) {
      await _notifications.cancel(id);
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
