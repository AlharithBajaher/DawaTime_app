import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDoseTime {
  const MedicationDoseTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  factory MedicationDoseTime.fromMap(Map<String, dynamic> data) {
    return MedicationDoseTime(
      hour: ((data['hour'] as num?)?.toInt() ?? 9).clamp(0, 23),
      minute: ((data['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
    );
  }

  Map<String, int> toMap() {
    return {'hour': hour, 'minute': minute};
  }

  int get sortValue => hour * 60 + minute;

  String formatLabel() {
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final minuteLabel = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:$minuteLabel $period';
  }
}

class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.form,
    required this.quantity,
    required this.remainingQuantity,
    required this.doseUnit,
    required this.time,
    required this.hour,
    required this.minute,
    required this.frequency,
    required this.notificationIds,
    this.doseTimes = const <MedicationDoseTime>[],
    this.intervalDays = 1,
    this.takenDoseLogs = const <String, DateTime>{},
    this.skippedDoseLogs = const <String, DateTime>{},
    this.isArchived = false,
    this.archivedAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String dose;
  final String form;
  final int quantity;
  final int remainingQuantity;
  final String doseUnit;
  final String time;
  final int? hour;
  final int? minute;
  final int frequency;
  final List<MedicationDoseTime> doseTimes;
  final int intervalDays;
  final List<int> notificationIds;
  final Map<String, DateTime> takenDoseLogs;
  final Map<String, DateTime> skippedDoseLogs;
  final bool isArchived;
  final Timestamp? archivedAt;
  final Timestamp? createdAt;

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final legacyTime = data['time'] as String? ?? '';
    final legacyHour = (data['hour'] as num?)?.toInt();
    final legacyMinute = (data['minute'] as num?)?.toInt();
    final legacyFrequency = (data['frequency'] as num?)?.toInt() ?? 1;
    final parsedDoseTimes = _parseDoseTimes(
      data['doseTimes'],
      legacyTime: legacyTime,
      legacyHour: legacyHour,
      legacyMinute: legacyMinute,
      legacyFrequency: legacyFrequency,
    );

    return MedicationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      dose: data['dose'] as String? ?? '',
      form: data['form'] as String? ?? 'tablet',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      remainingQuantity:
          (data['remainingQuantity'] as num?)?.toInt() ??
          ((data['quantity'] as num?)?.toInt() ?? 1),
      doseUnit: data['doseUnit'] as String? ?? 'tablet',
      time: legacyTime,
      hour: legacyHour,
      minute: legacyMinute,
      frequency: legacyFrequency,
      doseTimes: parsedDoseTimes,
      intervalDays: ((data['intervalDays'] as num?)?.toInt() ?? 1).clamp(
        1,
        365,
      ),
      takenDoseLogs: _parseTakenDoseLogs(data['takenDoseLogs']),
      skippedDoseLogs: _parseDoseDateLogs(data['skippedDoseLogs']),
      notificationIds: (data['notificationIds'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((id) => id.toInt())
          .toList(),
      isArchived: data['isArchived'] as bool? ?? false,
      archivedAt: data['archivedAt'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  List<MedicationDoseTime> get sortedDoseTimes {
    final sorted = List<MedicationDoseTime>.from(doseTimes);
    sorted.sort((a, b) => a.sortValue.compareTo(b.sortValue));
    return sorted;
  }

  DateTime scheduledDateTime(DateTime anchor) {
    final firstDose = sortedDoseTimes.isNotEmpty
        ? sortedDoseTimes.first
        : _legacyDoseTime();

    return DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      firstDose.hour,
      firstDose.minute,
    );
  }

  bool isScheduledOnDate(DateTime date) {
    final createdDate = createdAt?.toDate();
    if (createdDate == null) {
      return true;
    }

    final safeIntervalDays = intervalDays <= 0 ? 1 : intervalDays;
    final anchor = DateTime(
      createdDate.year,
      createdDate.month,
      createdDate.day,
    );
    final target = DateTime(date.year, date.month, date.day);
    final elapsedDays = target.difference(anchor).inDays;
    return elapsedDays >= 0 && elapsedDays % safeIntervalDays == 0;
  }

  String displayTime() {
    final times = sortedDoseTimes.isNotEmpty
        ? sortedDoseTimes
        : [_legacyDoseTime()];
    return times.map((doseTime) => doseTime.formatLabel()).join(' • ');
  }

  String repeatSummary({required bool isArabic}) {
    if (intervalDays <= 1) {
      return isArabic ? 'كل يوم' : 'Every day';
    }

    return isArabic ? 'كل $intervalDays أيام' : 'Every $intervalDays days';
  }

  bool isDoseTaken(DateTime scheduledAt) {
    return takenDoseLogs.containsKey(doseLogKeyFor(scheduledAt));
  }

  DateTime? takenDoseTime(DateTime scheduledAt) {
    return takenDoseLogs[doseLogKeyFor(scheduledAt)];
  }

  bool isDoseSkipped(DateTime scheduledAt) {
    return skippedDoseLogs.containsKey(doseLogKeyFor(scheduledAt));
  }

  DateTime? skippedDoseTime(DateTime scheduledAt) {
    return skippedDoseLogs[doseLogKeyFor(scheduledAt)];
  }

  bool isDoseMissed(
    DateTime scheduledAt, {
    DateTime? now,
    int graceMinutes = 45,
  }) {
    if (isDoseTaken(scheduledAt) || isDoseSkipped(scheduledAt)) {
      return false;
    }

    final reference = (now ?? DateTime.now()).toLocal();
    final cutoff = scheduledAt.toLocal().add(Duration(minutes: graceMinutes));
    return reference.isAfter(cutoff);
  }

  static String doseLogKeyFor(DateTime scheduledAt) {
    final normalized = scheduledAt.toLocal();
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    final hour = normalized.hour.toString().padLeft(2, '0');
    final minute = normalized.minute.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute';
  }

  MedicationDoseTime _legacyDoseTime() {
    final parsed = _parseLegacyTime(time);
    return MedicationDoseTime(
      hour: hour ?? parsed.hour,
      minute: minute ?? parsed.minute,
    );
  }

  static List<MedicationDoseTime> _parseDoseTimes(
    Object? source, {
    required String legacyTime,
    required int? legacyHour,
    required int? legacyMinute,
    required int legacyFrequency,
  }) {
    final fromFirestore = source is List
        ? source
              .whereType<Map>()
              .map(
                (item) =>
                    MedicationDoseTime.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : <MedicationDoseTime>[];

    if (fromFirestore.isNotEmpty) {
      return fromFirestore;
    }

    final parsed = _parseLegacyTime(legacyTime);
    final start = MedicationDoseTime(
      hour: legacyHour ?? parsed.hour,
      minute: legacyMinute ?? parsed.minute,
    );

    final safeFrequency = legacyFrequency.clamp(1, 24);
    if (safeFrequency == 1) {
      return [start];
    }

    final intervalMinutes = (1440 / safeFrequency).round();
    return List<MedicationDoseTime>.generate(safeFrequency, (index) {
      final totalMinutes =
          (start.hour * 60 + start.minute + intervalMinutes * index) % 1440;
      return MedicationDoseTime(
        hour: totalMinutes ~/ 60,
        minute: totalMinutes % 60,
      );
    });
  }

  static MedicationDoseTime _parseLegacyTime(String value) {
    final cleaned = value.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2})\:(\d{2})').firstMatch(cleaned);
    if (match == null) {
      return const MedicationDoseTime(hour: 9, minute: 0);
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

    return MedicationDoseTime(
      hour: parsedHour.clamp(0, 23),
      minute: parsedMinute.clamp(0, 59),
    );
  }

  static Map<String, DateTime> _parseTakenDoseLogs(Object? source) {
    return _parseDoseDateLogs(source);
  }

  static Map<String, DateTime> _parseDoseDateLogs(Object? source) {
    if (source is! Map) {
      return const <String, DateTime>{};
    }

    final parsed = <String, DateTime>{};
    for (final entry in source.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is Timestamp) {
        parsed[key] = value.toDate().toLocal();
      } else if (value is DateTime) {
        parsed[key] = value.toLocal();
      } else if (value is String) {
        final parsedDate = DateTime.tryParse(value);
        if (parsedDate != null) {
          parsed[key] = parsedDate.toLocal();
        }
      }
    }

    return parsed;
  }
}

