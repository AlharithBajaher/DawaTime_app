import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettings {
  final String userId;
  final bool quantityAlertEnabled;
  final Map<String, dynamic> quantityAlertSchedule; // {times: [9, 13, 17, 21]}
  final bool inventoryAlertEnabled;
  final Map<String, dynamic> inventoryAlertSchedule;
  final bool adherenceAlertEnabled;
  final double adherenceAlertThreshold; // 0.0 to 1.0
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSettings({
    required this.userId,
    this.quantityAlertEnabled = true,
    this.quantityAlertSchedule = const {
      'times': [9, 13, 17, 21],
      'repeatCount': 1,
      'repeatInterval': {'hours': 1},
    },
    this.inventoryAlertEnabled = true,
    this.inventoryAlertSchedule = const {
      'times': [9, 13, 17, 21],
      'urgentThreshold': 2, // Notify when quantity <= this
    },
    this.adherenceAlertEnabled = true,
    this.adherenceAlertThreshold = 0.7,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSettings.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return NotificationSettings(
      userId: data['userId'],
      quantityAlertEnabled: data['quantityAlertEnabled'] ?? true,
      quantityAlertSchedule: Map<String, dynamic>.from(
        data['quantityAlertSchedule'] ?? {
          'times': [9, 13, 17, 21],
          'repeatCount': 1,
          'repeatInterval': {'hours': 1},
        },
      ),
      inventoryAlertEnabled: data['inventoryAlertEnabled'] ?? true,
      inventoryAlertSchedule: Map<String, dynamic>.from(
        data['inventoryAlertSchedule'] ?? {
          'times': [9, 13, 17, 21],
          'urgentThreshold': 2,
        },
      ),
      adherenceAlertEnabled: data['adherenceAlertEnabled'] ?? true,
      adherenceAlertThreshold: (data['adherenceAlertThreshold'] ?? 0.7).toDouble(),
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'quantityAlertEnabled': quantityAlertEnabled,
      'quantityAlertSchedule': quantityAlertSchedule,
      'inventoryAlertEnabled': inventoryAlertEnabled,
      'inventoryAlertSchedule': inventoryAlertSchedule,
      'adherenceAlertEnabled': adherenceAlertEnabled,
      'adherenceAlertThreshold': adherenceAlertThreshold,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NotificationSettings copyWith({
    String? userId,
    bool? quantityAlertEnabled,
    Map<String, dynamic>? quantityAlertSchedule,
    bool? inventoryAlertEnabled,
    Map<String, dynamic>? inventoryAlertSchedule,
    bool? adherenceAlertEnabled,
    double? adherenceAlertThreshold,
    bool? soundEnabled,
    bool? vibrationEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      quantityAlertEnabled: quantityAlertEnabled ?? this.quantityAlertEnabled,
      quantityAlertSchedule: quantityAlertSchedule ?? this.quantityAlertSchedule,
      inventoryAlertEnabled: inventoryAlertEnabled ?? this.inventoryAlertEnabled,
      inventoryAlertSchedule: inventoryAlertSchedule ?? this.inventoryAlertSchedule,
      adherenceAlertEnabled: adherenceAlertEnabled ?? this.adherenceAlertEnabled,
      adherenceAlertThreshold: adherenceAlertThreshold ?? this.adherenceAlertThreshold,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  List<int> get quantityAlertTimes {
    final times = quantityAlertSchedule['times'];
    if (times is List) {
      return times.whereType<int>().toList();
    }
    return [9, 13, 17, 21];
  }

  List<int> get inventoryAlertTimes {
    final times = inventoryAlertSchedule['times'];
    if (times is List) {
      return times.whereType<int>().toList();
    }
    return [9, 13, 17, 21];
  }

  int get inventoryUrgentThreshold {
    final threshold = inventoryAlertSchedule['urgentThreshold'];
    return threshold is int ? threshold : 2;
  }

  int get quantityAlertRepeatCount {
    final count = quantityAlertSchedule['repeatCount'];
    return count is int ? count : 1;
  }

  Duration get quantityAlertRepeatInterval {
    final interval = quantityAlertSchedule['repeatInterval'];
    if (interval is Map) {
      final hours = interval['hours'] ?? 1;
      final minutes = interval['minutes'] ?? 0;
      return Duration(hours: hours.toInt(), minutes: minutes.toInt());
    }
    return const Duration(hours: 1);
  }

  bool shouldNotifyForQuantity(int remainingQuantity) {
    return quantityAlertEnabled && remainingQuantity <= 5;
  }

  bool shouldNotifyForInventory(int currentQuantity, int minQuantity) {
    return inventoryAlertEnabled && currentQuantity <= minQuantity;
  }

  bool shouldNotifyForAdherence(double adherenceRate) {
    return adherenceAlertEnabled && adherenceRate < adherenceAlertThreshold;
  }
}