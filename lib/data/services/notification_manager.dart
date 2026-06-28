import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'medication_service.dart';
import 'notification_service.dart';
import 'pharmacy_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  Timer? _dailyCheckTimer;
  Timer? _quantityCheckTimer;
  Timer? _inventoryCheckTimer;

  // Configuration
  static const Map<int, List<int>> _quantityNotificationSchedule = {
    1: [9, 13, 17, 21],  // When 1 dose left: 4 times daily
    2: [9, 17],          // When 2 doses left: 2 times daily  
    3: [9],              // When 3 doses left: 1 time daily
    4: [9],              // When 4 doses left: 1 time daily
    5: [9],              // When 5 doses left: 1 time daily
  };

  static const List<int> _inventoryNotificationTimes = [9, 13, 17, 21]; // 4 times daily

  void initialize() {
    // Schedule daily checks at 2:00 AM
    _scheduleDailyCheck();
    
    // Start immediate quantity monitoring
    _startQuantityMonitoring();
    
    // Start immediate inventory monitoring
    _startInventoryMonitoring();
  }

  void _scheduleDailyCheck() {
    final now = DateTime.now();
    final nextCheck = DateTime(
      now.year,
      now.month,
      now.day,
      2,  // 2:00 AM
      0,
    );

    if (nextCheck.isBefore(now)) {
      nextCheck.add(const Duration(days: 1));
    }

    final initialDelay = nextCheck.difference(now);
    
    _dailyCheckTimer = Timer.periodic(
      const Duration(days: 1),
      (_) => _performDailyChecks(),
    );

    // Start first check after delay
    Timer(initialDelay, () => _performDailyChecks());
  }

  Future<void> _performDailyChecks() async {
    debugPrint('Performing daily notification checks...');
    
    try {
      // Check for expired medications
      await _checkExpiredMedications();
      
      // Check for low adherence
      await _checkLowAdherence();
      
      // Clean up old notifications
      await _cleanupOldNotifications();
    } catch (e) {
      debugPrint('Daily check error: $e');
    }
  }

  void _startQuantityMonitoring() {
    // Check medication quantities every hour
    _quantityCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkMedicationQuantities(),
    );
    
    // Initial check
    _checkMedicationQuantities();
  }

  Future<void> _checkMedicationQuantities() async {
    debugPrint('Checking medication quantities...');
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final medicationService = MedicationService();
      final medications = await medicationService.getUserMedications().first;

      for (final medication in medications) {
        final remaining = medication.remainingQuantity;
        if (remaining <= 0) continue;

        if (_quantityNotificationSchedule.containsKey(remaining)) {
          final times = _quantityNotificationSchedule[remaining]!;
          for (final hour in times) {
            await schedulePreciseQuantityNotification(
              medicationId: medication.id,
              medicationName: medication.name,
              remainingQuantity: remaining,
              isArabic: false,
              hour: hour,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Quantity check error: $e');
    }
  }

  void _startInventoryMonitoring() {
    // Check inventory every 4 hours
    _inventoryCheckTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => _checkInventoryLevels(),
    );
    
    // Initial check
    _checkInventoryLevels();
  }

  Future<void> _checkInventoryLevels() async {
    debugPrint('Checking inventory levels...');
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final pharmacyService = PharmacyService();
      final tasks = await pharmacyService.watchTasks().first;

      for (final task in tasks) {
        if (task.quantity <= task.minQuantity) {
          for (final hour in _inventoryNotificationTimes) {
            await schedulePreciseInventoryNotification(
              itemId: task.id,
              itemName: task.title,
              currentQuantity: task.quantity,
              minQuantity: task.minQuantity,
              isArabic: false,
              hour: hour,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Inventory check error: $e');
    }
  }

  Future<void> _checkExpiredMedications() async {
    debugPrint('Checking for depleted medications...');
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final medicationService = MedicationService();
      final medications = await medicationService
          .getUserMedications(includeArchived: true)
          .first;
      final now = DateTime.now();

      for (final medication in medications) {
        if (medication.remainingQuantity <= 0 && !medication.isArchived) {
          final id = _generateDepletionNotificationId(medication.id);
          await NotificationService.scheduleOneTimeReminder(
            id: id,
            title: '⚠️ DawaTime - Medication Depleted',
            body: '${medication.name} has run out. Please refill.',
            reminderAt: now.add(const Duration(minutes: 5)),
            medicationId: medication.id,
            medicationName: medication.name,
          );
        }
      }
    } catch (e) {
      debugPrint('Depletion check error: $e');
    }
  }

  Future<void> _checkLowAdherence() async {
    debugPrint('Checking medication adherence...');
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final medicationService = MedicationService();
      final medications = await medicationService.getUserMedications().first;

      for (final medication in medications) {
        final takenCount = medication.takenDoseLogs.length;
        final skippedCount = medication.skippedDoseLogs.length;
        final totalDoses = takenCount + skippedCount;

        if (totalDoses > 0) {
          final adherenceRate = takenCount / totalDoses;
          if (adherenceRate < 0.8) {
            final id = _generateAdherenceNotificationId(medication.id);
            await NotificationService.scheduleOneTimeReminder(
              id: id,
              title: '💊 DawaTime - Low Adherence',
              body:
                  '${medication.name}: ${(adherenceRate * 100).round()}% adherence. Please stay on track.',
              reminderAt:
                  DateTime.now().add(const Duration(minutes: 10)),
              medicationId: medication.id,
              medicationName: medication.name,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Adherence check error: $e');
    }
  }

  Future<void> _cleanupOldNotifications() async {
    debugPrint('Cleaning up old notifications...');
    try {
      // Cancel all scheduled notifications; the daily cycle will
      // re-schedule fresh reminders for upcoming doses.
      await NotificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  // Helper methods for precise notification scheduling
  Future<void> schedulePreciseQuantityNotification({
    required String medicationId,
    required String medicationName,
    required int remainingQuantity,
    required bool isArabic,
    required int hour,
    int minute = 0,
  }) async {
    final title = isArabic
        ? 'تنبيه الكمية - $medicationName'
        : 'Quantity Alert - $medicationName';
    
    final body = isArabic
        ? 'تبقى $remainingQuantity جرعة فقط من $medicationName. يرجى تجديد الوصفة.'
        : 'Only $remainingQuantity doses left of $medicationName. Please renew prescription.';

    // Calculate next occurrence
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Generate unique ID
    final notificationId = _generateQuantityNotificationId(
      medicationId,
      hour,
      minute,
    );

    await NotificationService.scheduleOneTimeReminder(
      id: notificationId,
      title: title,
      body: body,
      reminderAt: scheduledTime,
      medicationId: medicationId,
    );
  }

  Future<void> schedulePreciseInventoryNotification({
    required String itemId,
    required String itemName,
    required int currentQuantity,
    required int minQuantity,
    required bool isArabic,
    required int hour,
    int minute = 0,
  }) async {
    final title = isArabic
        ? 'تنبيه المخزون - $itemName'
        : 'Inventory Alert - $itemName';
    
    final status = currentQuantity <= 0
        ? (isArabic ? 'نفذ من المخزون' : 'Out of stock')
        : (isArabic ? 'منخفض' : 'Low stock');
    
    final body = isArabic
        ? '$itemName: $status (المتبقي: $currentQuantity، الحد الأدنى: $minQuantity)'
        : '$itemName: $status (Remaining: $currentQuantity, Minimum: $minQuantity)';

    // Calculate next occurrence
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Generate unique ID
    final notificationId = _generateInventoryNotificationId(
      itemId,
      hour,
      minute,
    );

    await NotificationService.scheduleOneTimeReminder(
      id: notificationId,
      title: title,
      body: body,
      reminderAt: scheduledTime,
      medicationId: itemId,
    );
  }

  int _generateQuantityNotificationId(String medicationId, int hour, int minute) {
    return 2000000000 + 
           (medicationId.hashCode.abs() % 1000000) +
           (hour * 10000) +
           (minute * 100);
  }

  int _generateInventoryNotificationId(String itemId, int hour, int minute) {
    return 3000000000 + 
           (itemId.hashCode.abs() % 1000000) +
           (hour * 10000) +
           (minute * 100);
  }

  // Real-time monitoring methods
  void onDoseTaken({
    required String medicationId,
    required String medicationName,
    required int newRemainingQuantity,
    required bool isArabic,
  }) {
    debugPrint('Dose taken: $medicationName, remaining: $newRemainingQuantity');
    
    // Check if we need to schedule quantity notifications
    if (_quantityNotificationSchedule.containsKey(newRemainingQuantity)) {
      final times = _quantityNotificationSchedule[newRemainingQuantity]!;
      
      for (final hour in times) {
        schedulePreciseQuantityNotification(
          medicationId: medicationId,
          medicationName: medicationName,
          remainingQuantity: newRemainingQuantity,
          isArabic: isArabic,
          hour: hour,
        );
      }
    }
    
    // Cancel any existing quantity notifications for higher counts
    _cancelHigherQuantityNotifications(medicationId, newRemainingQuantity);
  }

  void onInventoryUpdated({
    required String itemId,
    required String itemName,
    required int newQuantity,
    required int minQuantity,
    required bool isArabic,
  }) {
    debugPrint('Inventory updated: $itemName, quantity: $newQuantity');
    
    if (newQuantity <= minQuantity) {
      // Schedule inventory notifications at all configured times
      for (final hour in _inventoryNotificationTimes) {
        schedulePreciseInventoryNotification(
          itemId: itemId,
          itemName: itemName,
          currentQuantity: newQuantity,
          minQuantity: minQuantity,
          isArabic: isArabic,
          hour: hour,
        );
      }
    } else {
      // Cancel all inventory notifications for this item
      _cancelAllInventoryNotifications(itemId);
    }
  }

  void _cancelHigherQuantityNotifications(
    String medicationId,
    int currentRemaining,
  ) {
    // Cancel notifications for quantities higher than current
    for (final quantity in _quantityNotificationSchedule.keys) {
      if (quantity > currentRemaining) {
        final times = _quantityNotificationSchedule[quantity]!;
        
        for (final hour in times) {
          final notificationId = _generateQuantityNotificationId(
            medicationId,
            hour,
            0, // Default minute
          );
          
          NotificationService.cancelNotification(notificationId);
        }
      }
    }
  }

  void _cancelAllInventoryNotifications(String itemId) {
    for (final hour in _inventoryNotificationTimes) {
      final notificationId = _generateInventoryNotificationId(
        itemId,
        hour,
        0, // Default minute
      );
      
      NotificationService.cancelNotification(notificationId);
    }
  }

  int _generateDepletionNotificationId(String medicationId) {
    return 4000000000 + (medicationId.hashCode.abs() % 100000000);
  }

  int _generateAdherenceNotificationId(String medicationId) {
    return 5000000000 + (medicationId.hashCode.abs() % 100000000);
  }

  void dispose() {
    _dailyCheckTimer?.cancel();
    _quantityCheckTimer?.cancel();
    _inventoryCheckTimer?.cancel();
  }
}