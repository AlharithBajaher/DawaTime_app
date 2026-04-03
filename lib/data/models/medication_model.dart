import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String dose;
  final String form;
  final int quantity;
  final String doseUnit;
  final String time;
  final int? hour;
  final int? minute;
  final int frequency;
  final List<int> notificationIds;
  final Timestamp? createdAt;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.form,
    required this.quantity,
    required this.doseUnit,
    required this.time,
    required this.hour,
    required this.minute,
    required this.frequency,
    required this.notificationIds,
    this.createdAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MedicationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      dose: data['dose'] as String? ?? '',
      form: data['form'] as String? ?? 'tablet',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      doseUnit: data['doseUnit'] as String? ?? 'tablet',
      time: data['time'] as String? ?? '',
      hour: (data['hour'] as num?)?.toInt(),
      minute: (data['minute'] as num?)?.toInt(),
      frequency: (data['frequency'] as num?)?.toInt() ?? 1,
      notificationIds: (data['notificationIds'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((id) => id.toInt())
          .toList(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  DateTime scheduledDateTime(DateTime anchor) {
    final parsed = _parseLegacyTime();
    final resolvedHour = hour ?? parsed.$1;
    final resolvedMinute = minute ?? parsed.$2;

    return DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      resolvedHour,
      resolvedMinute,
    );
  }

  String displayTime() {
    final parsed = _parseLegacyTime();
    final resolvedHour = hour ?? parsed.$1;
    final resolvedMinute = minute ?? parsed.$2;
    final period = resolvedHour >= 12 ? 'PM' : 'AM';
    final normalizedHour = resolvedHour % 12 == 0 ? 12 : resolvedHour % 12;
    final minuteLabel = resolvedMinute.toString().padLeft(2, '0');
    return '$normalizedHour:$minuteLabel $period';
  }

  (int, int) _parseLegacyTime() {
    final cleaned = time.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2})\:(\d{2})').firstMatch(cleaned);
    if (match == null) {
      return (9, 0);
    }

    var parsedHour = int.tryParse(match.group(1) ?? '') ?? 9;
    final parsedMinute = int.tryParse(match.group(2) ?? '') ?? 0;
    final isPm = cleaned.contains('PM');
    final isAm = cleaned.contains('AM');

    if (isPm && parsedHour < 12) {
      parsedHour += 12;
    } else if (isAm && parsedHour == 12) {
      parsedHour = 0;
    }

    parsedHour = parsedHour.clamp(0, 23);
    return (parsedHour, parsedMinute.clamp(0, 59));
  }
}
