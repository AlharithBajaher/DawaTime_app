import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_settings.dart';
import 'notification_service.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<NotificationSettings> getUserSettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore
        .collection('notification_settings')
        .doc(userId)
        .get();

    if (doc.exists) {
      return NotificationSettings.fromFirestore(doc);
    }

    // Create default settings
    final defaultSettings = NotificationSettings(
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('notification_settings')
        .doc(userId)
        .set(defaultSettings.toFirestore());

    return defaultSettings;
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final updatedSettings = settings.copyWith(updatedAt: DateTime.now());

    await _firestore
        .collection('notification_settings')
        .doc(userId)
        .set(updatedSettings.toFirestore(), SetOptions(merge: true));

    // Re-initialize notification manager with new settings
    _applySettingsToManager(updatedSettings);
  }

  Future<void> updateQuantityAlertSettings({
    bool? enabled,
    List<int>? times,
    int? repeatCount,
    Duration? repeatInterval,
  }) async {
    final currentSettings = await getUserSettings();
    
    final newSchedule = Map<String, dynamic>.from(
      currentSettings.quantityAlertSchedule,
    );
    
    if (times != null) {
      newSchedule['times'] = times;
    }
    if (repeatCount != null) {
      newSchedule['repeatCount'] = repeatCount;
    }
    if (repeatInterval != null) {
      newSchedule['repeatInterval'] = {
        'hours': repeatInterval.inHours,
        'minutes': repeatInterval.inMinutes % 60,
      };
    }

    final updatedSettings = currentSettings.copyWith(
      quantityAlertEnabled: enabled ?? currentSettings.quantityAlertEnabled,
      quantityAlertSchedule: newSchedule,
    );

    await updateSettings(updatedSettings);
  }

  Future<void> updateInventoryAlertSettings({
    bool? enabled,
    List<int>? times,
    int? urgentThreshold,
  }) async {
    final currentSettings = await getUserSettings();
    
    final newSchedule = Map<String, dynamic>.from(
      currentSettings.inventoryAlertSchedule,
    );
    
    if (times != null) {
      newSchedule['times'] = times;
    }
    if (urgentThreshold != null) {
      newSchedule['urgentThreshold'] = urgentThreshold;
    }

    final updatedSettings = currentSettings.copyWith(
      inventoryAlertEnabled: enabled ?? currentSettings.inventoryAlertEnabled,
      inventoryAlertSchedule: newSchedule,
    );

    await updateSettings(updatedSettings);
  }

  Future<void> updateAdherenceAlertSettings({
    bool? enabled,
    double? threshold,
  }) async {
    final currentSettings = await getUserSettings();

    final updatedSettings = currentSettings.copyWith(
      adherenceAlertEnabled: enabled ?? currentSettings.adherenceAlertEnabled,
      adherenceAlertThreshold: threshold ?? currentSettings.adherenceAlertThreshold,
    );

    await updateSettings(updatedSettings);
  }

  Future<void> updateSoundVibrationSettings({
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    final currentSettings = await getUserSettings();

    final updatedSettings = currentSettings.copyWith(
      soundEnabled: soundEnabled ?? currentSettings.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? currentSettings.vibrationEnabled,
    );

    await updateSettings(updatedSettings);
  }

  void _applySettingsToManager(NotificationSettings settings) {
    if (!settings.quantityAlertEnabled) {
      NotificationService.cancelAllNotifications();
    }
    if (!settings.inventoryAlertEnabled) {
      NotificationService.cancelAllNotifications();
    }
    if (!settings.adherenceAlertEnabled) {
      NotificationService.cancelAllNotifications();
    }
  }

  // Helper methods for UI
  Future<Map<String, dynamic>> getSettingsForUI() async {
    final settings = await getUserSettings();
    
    return {
      'quantityAlert': {
        'enabled': settings.quantityAlertEnabled,
        'times': settings.quantityAlertTimes,
        'repeatCount': settings.quantityAlertRepeatCount,
        'repeatInterval': settings.quantityAlertRepeatInterval,
      },
      'inventoryAlert': {
        'enabled': settings.inventoryAlertEnabled,
        'times': settings.inventoryAlertTimes,
        'urgentThreshold': settings.inventoryUrgentThreshold,
      },
      'adherenceAlert': {
        'enabled': settings.adherenceAlertEnabled,
        'threshold': settings.adherenceAlertThreshold,
      },
      'soundVibration': {
        'soundEnabled': settings.soundEnabled,
        'vibrationEnabled': settings.vibrationEnabled,
      },
    };
  }

  // Check if we should schedule notifications for specific conditions
  Future<bool> shouldScheduleQuantityAlert(int remainingQuantity) async {
    final settings = await getUserSettings();
    return settings.shouldNotifyForQuantity(remainingQuantity);
  }

  Future<bool> shouldScheduleInventoryAlert(
    int currentQuantity,
    int minQuantity,
  ) async {
    final settings = await getUserSettings();
    return settings.shouldNotifyForInventory(currentQuantity, minQuantity);
  }

  Future<bool> shouldScheduleAdherenceAlert(double adherenceRate) async {
    final settings = await getUserSettings();
    return settings.shouldNotifyForAdherence(adherenceRate);
  }

  // Schedule notifications based on settings
  Future<void> scheduleQuantityNotifications({
    required String medicationId,
    required String medicationName,
    required int remainingQuantity,
    required bool isArabic,
  }) async {
    final settings = await getUserSettings();
    
    if (!settings.shouldNotifyForQuantity(remainingQuantity)) {
      return;
    }

    final times = settings.quantityAlertTimes;
    final repeatCount = settings.quantityAlertRepeatCount;
    final repeatInterval = settings.quantityAlertRepeatInterval;

    for (final hour in times) {
      // Import the enhanced notifications extension
      await _scheduleEnhancedQuantityNotification(
        medicationId: medicationId,
        medicationName: medicationName,
        remainingQuantity: remainingQuantity,
        isArabic: isArabic,
        hour: hour,
        repeatCount: repeatCount,
        repeatInterval: repeatInterval,
      );
    }
  }

  Future<void> scheduleInventoryNotifications({
    required String itemId,
    required String itemName,
    required int currentQuantity,
    required int minQuantity,
    required bool isArabic,
  }) async {
    final settings = await getUserSettings();
    
    if (!settings.shouldNotifyForInventory(currentQuantity, minQuantity)) {
      return;
    }

    final times = settings.inventoryAlertTimes;
    final isUrgent = currentQuantity <= settings.inventoryUrgentThreshold;

    for (final hour in times) {
      // Import the enhanced notifications extension
      await _scheduleEnhancedInventoryNotification(
        itemId: itemId,
        itemName: itemName,
        currentQuantity: currentQuantity,
        minQuantity: minQuantity,
        isArabic: isArabic,
        hour: hour,
        isUrgent: isUrgent,
      );
    }
  }

  Future<void> _scheduleEnhancedQuantityNotification({
    required String medicationId,
    required String medicationName,
    required int remainingQuantity,
    required bool isArabic,
    required int hour,
    required int repeatCount,
    required Duration repeatInterval,
  }) async {
    final now = DateTime.now();
    var scheduledAt = DateTime(now.year, now.month, now.day, hour, 0);
    if (scheduledAt.isBefore(now)) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }

    final title = isArabic
        ? 'تنبيه الكمية - $medicationName'
        : 'Quantity Alert - $medicationName';
    final body = isArabic
        ? 'تبقى $remainingQuantity جرعة فقط من $medicationName. يرجى تجديد الوصفة.'
        : 'Only $remainingQuantity doses left of $medicationName. Please renew prescription.';

    final id = 6000000000 +
        (medicationId.hashCode.abs() % 100000000) +
        (hour * 10000);

    await NotificationService.scheduleOneTimeReminder(
      id: id,
      title: title,
      body: body,
      reminderAt: scheduledAt,
      medicationId: medicationId,
      medicationName: medicationName,
    );

    // Schedule repeat notifications if repeatCount > 1
    for (var i = 1; i < repeatCount; i++) {
      final repeatAt = scheduledAt.add(repeatInterval * i);
      final repeatId = id + i;
      await NotificationService.scheduleOneTimeReminder(
        id: repeatId,
        title: title,
        body: body,
        reminderAt: repeatAt,
        medicationId: medicationId,
        medicationName: medicationName,
      );
    }
  }

  Future<void> _scheduleEnhancedInventoryNotification({
    required String itemId,
    required String itemName,
    required int currentQuantity,
    required int minQuantity,
    required bool isArabic,
    required int hour,
    required bool isUrgent,
  }) async {
    final now = DateTime.now();
    var scheduledAt = DateTime(now.year, now.month, now.day, hour, 0);
    if (scheduledAt.isBefore(now)) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }

    final status = currentQuantity <= 0
        ? (isArabic ? 'نفذ من المخزون' : 'Out of stock')
        : (isArabic ? 'منخفض' : 'Low stock');

    final title = isArabic
        ? 'تنبيه المخزون - $itemName'
        : 'Inventory Alert - $itemName';
    final body = isArabic
        ? '$itemName: $status (المتبقي: $currentQuantity، الحد الأدنى: $minQuantity)'
        : '$itemName: $status (Remaining: $currentQuantity, Minimum: $minQuantity)';

    final id = 7000000000 +
        (itemId.hashCode.abs() % 100000000) +
        (hour * 10000);

    await NotificationService.scheduleOneTimeReminder(
      id: id,
      title: title,
      body: body,
      reminderAt: scheduledAt,
      medicationId: itemId,
      medicationName: itemName,
    );
  }
}