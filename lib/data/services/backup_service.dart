import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_user_model.dart';
import '../models/medication_model.dart';
import '../models/notification_settings.dart';
import '../models/pharmacy_rating_model.dart';
import '../models/pharmacy_task_model.dart';
import '../models/shared_medicine_model.dart';

const String _kBackupVersion = '1.0';

class BackupMetadata {
  final String id;
  final DateTime createdAt;
  final String appVersion;
  final String userId;
  final String userEmail;
  final String userName;
  final String userRole;
  final String backupType;
  final int medicationsCount;
  final int doseLogsCount;
  final int tasksCount;
  final int ratingsCount;
  final int fileSize;

  const BackupMetadata({
    required this.id,
    required this.createdAt,
    required this.appVersion,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userRole,
    required this.backupType,
    required this.medicationsCount,
    required this.doseLogsCount,
    required this.tasksCount,
    required this.ratingsCount,
    required this.fileSize,
  });

  String get formattedDate {
    final d = createdAt;
    final y = d.year.toString();
    final mo = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$y-$mo-$day $h:$mi';
  }

  String get fileName =>
      'dawatime_backup_${createdAt.millisecondsSinceEpoch}.json';

  String get storagePath => 'backups/$userId/$fileName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userRole': userRole,
        'backupType': backupType,
        'medicationsCount': medicationsCount,
        'doseLogsCount': doseLogsCount,
        'tasksCount': tasksCount,
        'ratingsCount': ratingsCount,
        'fileSize': fileSize,
      };
}

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  String? get _uid => _user?.uid;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<BackupMetadata> createCloudBackup({bool isAutomatic = false}) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }

    final json = await _collectAllUserData(uid);
    final encoded = utf8.encode(const JsonEncoder.withIndent('  ').convert(json));
    final metadata = json['metadata'] as Map<String, dynamic>;
    final fileName = 'dawatime_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final storagePath = 'backups/$uid/$fileName';

    final ref = _storage.ref(storagePath);
    await ref.putData(
      encoded,
      SettableMetadata(
        contentType: 'application/json',
        customMetadata: {
          'userId': uid,
          'createdAt': DateTime.now().toIso8601String(),
          'backupType': isAutomatic ? 'automatic' : 'manual',
        },
      ),
    );

    return BackupMetadata(
      id: fileName,
      createdAt: DateTime.now(),
      appVersion: metadata['appVersion'] as String? ?? '0.0.1+1',
      userId: uid,
      userEmail: metadata['userEmail'] as String? ?? '',
      userName: metadata['userName'] as String? ?? '',
      userRole: metadata['userRole'] as String? ?? '',
      backupType: isAutomatic ? 'automatic' : 'manual',
      medicationsCount: metadata['medicationsCount'] as int? ?? 0,
      doseLogsCount: metadata['doseLogsCount'] as int? ?? 0,
      tasksCount: metadata['tasksCount'] as int? ?? 0,
      ratingsCount: metadata['ratingsCount'] as int? ?? 0,
      fileSize: encoded.length,
    );
  }

  Future<File> exportToLocalFile() async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }

    final json = await _collectAllUserData(uid);
    final encoded = const JsonEncoder.withIndent('  ').convert(json);

    final dir = await getTemporaryDirectory();
    final fileName = 'dawatime_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(encoded, flush: true);

    return file;
  }

  Future<void> shareBackupFile() async {
    final file = await exportToLocalFile();
    await Share.shareXFiles([XFile(file.path)], text: 'DawaTime Backup');
  }

  Future<String> restoreFromCloud(String storagePath) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }

    final ref = _storage.ref(storagePath);
    final bytes = await ref.getData();
    if (bytes == null) {
      throw StateError('Backup file is empty.');
    }

    final json = utf8.decode(bytes);
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _restoreAllData(uid, data);
  }

  Future<String> restoreFromLocalFile(String filePath) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw StateError('Backup file not found.');
    }

    final json = await file.readAsString();
    final data = jsonDecode(json) as Map<String, dynamic>;
    return _restoreAllData(uid, data);
  }

  Future<String> restoreFromJsonString(String jsonString) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return _restoreAllData(uid, data);
  }

  Future<List<BackupMetadata>> listCloudBackups() async {
    final uid = _uid;
    if (uid == null) {
      return [];
    }

    final ref = _storage.ref('backups/$uid');
    final listResult = await ref.listAll();

    final backups = <BackupMetadata>[];
    for (final item in listResult.items) {
      try {
        final meta = await item.getMetadata();
        final custom = meta.customMetadata ?? {};
        final nameParts = item.name.replaceAll('.json', '').split('_');
        final timestampMs = int.tryParse(nameParts.isNotEmpty ? nameParts.last : '0') ?? 0;

        final createdAt = timestampMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
            : (meta.timeCreated ?? DateTime.now());

        final data = await _tryFetchBackupPreview(item);
        final preview = data != null
            ? (data['metadata'] as Map<String, dynamic>?)
            : null;

        backups.add(BackupMetadata(
          id: item.name,
          createdAt: createdAt,
          appVersion: preview?['appVersion'] as String? ?? 'unknown',
          userId: custom['userId'] ?? uid,
          userEmail: preview?['userEmail'] as String? ?? custom['userEmail'] ?? '',
          userName: preview?['userName'] as String? ?? custom['userName'] ?? '',
          userRole: preview?['userRole'] as String? ?? custom['userRole'] ?? '',
          backupType: custom['backupType'] ?? preview?['backupType'] as String? ?? 'manual',
          medicationsCount: preview?['medicationsCount'] as int? ?? 0,
          doseLogsCount: preview?['doseLogsCount'] as int? ?? 0,
          tasksCount: preview?['tasksCount'] as int? ?? 0,
          ratingsCount: preview?['ratingsCount'] as int? ?? 0,
          fileSize: meta.size ?? 0,
        ));
      } catch (_) {}
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  Future<void> deleteCloudBackup(String storagePath) async {
    final ref = _storage.ref(storagePath);
    await ref.delete();
  }

  Future<String> downloadBackupToFile(String storagePath) async {
    final ref = _storage.ref(storagePath);
    final bytes = await ref.getData();
    if (bytes == null) {
      throw StateError('Backup file is empty.');
    }

    final dir = await getTemporaryDirectory();
    final fileName = storagePath.split('/').last;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Auto-backup scheduling (lightweight: saves preference + last backup time)
  // ---------------------------------------------------------------------------

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'autoBackupEnabled': enabled,
      'autoBackupUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isAutoBackupEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return (doc.data()?['autoBackupEnabled'] as bool?) ?? false;
  }

  Future<DateTime?> lastAutoBackupTime() async {
    final uid = _uid;
    if (uid == null) return null;
    final ref = _storage.ref('backups/$uid');
    try {
      final listResult = await ref.listAll();
      final autoBackups = <Reference>[];
      for (final item in listResult.items) {
        try {
          final meta = await item.getMetadata();
          if (meta.customMetadata?['backupType'] == 'automatic') {
            autoBackups.add(item);
          }
        } catch (_) {}
      }
      if (autoBackups.isEmpty) return null;
      autoBackups.sort((a, b) => b.name.compareTo(a.name));
      final latest = await autoBackups.first.getMetadata();
      return latest.updated;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Data collection (serialization)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _collectAllUserData(String uid) async {
    final userProfile = await _fetchUserProfile(uid);
    final medications = await _fetchMedications(uid);
    final medicationReports = await _fetchMedicationReports(uid);
    final notificationSettings = await _fetchNotificationSettings(uid);
    final pharmacyTasks = await _fetchPharmacyTasks(uid);
    final sharedMedicines = await _fetchSharedMedicines(uid);
    final ratingsSent = await _fetchRatingsSent(uid);

    var doseLogsCount = 0;
    final medsJson = medications.map((m) {
      doseLogsCount += m.takenDoseLogs.length + m.skippedDoseLogs.length;
      return _medicationToJson(m);
    }).toList();

    final metadata = <String, dynamic>{
      'schemaVersion': _kBackupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': '0.0.1+1',
      'userId': uid,
      'userEmail': userProfile?.email ?? _user?.email ?? '',
      'userName': userProfile?.name ?? '',
      'userRole': userProfile?.role ?? '',
      'medicationsCount': medications.length,
      'medicationReportsCount': medicationReports.length,
      'doseLogsCount': doseLogsCount,
      'tasksCount': pharmacyTasks.length,
      'ratingsCount': ratingsSent.length,
    };

    return {
      'schemaVersion': _kBackupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': '0.0.1+1',
      'user': {
        'uid': uid,
        'email': userProfile?.email ?? _user?.email ?? '',
        'name': userProfile?.name ?? '',
        'role': userProfile?.role ?? '',
      },
      'metadata': metadata,
      'data': {
        'profile': _profileToJson(userProfile),
        'medications': medsJson,
        'medicationReports': medicationReports.map(_medicationReportToJson).toList(),
        'notificationSettings': _notificationSettingsToJson(notificationSettings),
        'pharmacyTasks': pharmacyTasks.map(_pharmacyTaskToJson).toList(),
        'sharedMedicines': sharedMedicines.map(_sharedMedicineToJson).toList(),
        'pharmacyRatingsSent': ratingsSent.map(_ratingToJson).toList(),
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Data restoration (deserialization)
  // ---------------------------------------------------------------------------

  Future<String> _restoreAllData(String uid, Map<String, dynamic> backup) async {
    final data = backup['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Backup contains no data section.');
    }

    final schemaVersion = backup['schemaVersion'] as String? ?? '0.0';
    if (!_isCompatibleVersion(schemaVersion)) {
      throw StateError(
        'Backup schema version $schemaVersion is not compatible with the current version $_kBackupVersion.',
      );
    }

    if (data['medications'] is List) {
      for (final medJson in data['medications'] as List) {
        await _restoreMedication(uid, medJson as Map<String, dynamic>);
      }
    }

    if (data['medicationReports'] is List) {
      for (final reportJson in data['medicationReports'] as List) {
        await _restoreMedicationReport(uid, reportJson as Map<String, dynamic>);
      }
    }

    if (data['notificationSettings'] is Map) {
      await _restoreNotificationSettings(
        uid,
        data['notificationSettings'] as Map<String, dynamic>,
      );
    }

    if (data['pharmacyTasks'] is List) {
      for (final taskJson in data['pharmacyTasks'] as List) {
        await _restorePharmacyTask(uid, taskJson as Map<String, dynamic>);
      }
    }

    if (data['sharedMedicines'] is List) {
      for (final medJson in data['sharedMedicines'] as List) {
        await _restoreSharedMedicine(uid, medJson as Map<String, dynamic>);
      }
    }

    final summary = StringBuffer();
    final medCount = (data['medications'] as List?)?.length ?? 0;
    final reportCount = (data['medicationReports'] as List?)?.length ?? 0;
    final taskCount = (data['pharmacyTasks'] as List?)?.length ?? 0;
    final sharedCount = (data['sharedMedicines'] as List?)?.length ?? 0;

    summary.write('Restored $medCount medications');
    if (reportCount > 0) summary.write(', $reportCount medication reports');
    if (taskCount > 0) summary.write(', $taskCount inventory items');
    if (sharedCount > 0) summary.write(', $sharedCount shared medicines');

    final meta = backup['metadata'] as Map<String, dynamic>?;
    final doseLogs = meta?['doseLogsCount'] as int? ?? 0;
    if (doseLogs > 0) {
      summary.write(' with $doseLogs dose logs');
    }

    summary.write('.');

    return summary.toString();
  }

  bool _isCompatibleVersion(String version) {
    final parts = version.split('.');
    final currentParts = _kBackupVersion.split('.');
    if (parts.isEmpty || currentParts.isEmpty) return false;
    return parts[0] == currentParts[0];
  }

  // ---------------------------------------------------------------------------
  // Per-type restoration
  // ---------------------------------------------------------------------------

  Future<void> _restoreMedication(String uid, Map<String, dynamic> json) async {
    final existingId = json['id'] as String?;
    if (existingId == null || existingId.isEmpty) return;

    final existing = await _firestore.collection('medications').doc(existingId).get();
    if (existing.exists) return;

    final takenLogs = json['takenDoseLogs'] as Map<String, dynamic>? ?? {};
    final skippedLogs = json['skippedDoseLogs'] as Map<String, dynamic>? ?? {};

    final convertedTaken = <String, dynamic>{};
    for (final entry in takenLogs.entries) {
      convertedTaken[entry.key] = _parseTimestamp(entry.value);
    }
    final convertedSkipped = <String, dynamic>{};
    for (final entry in skippedLogs.entries) {
      convertedSkipped[entry.key] = _parseTimestamp(entry.value);
    }

    await _firestore.collection('medications').doc(existingId).set({
      'userId': uid,
      'name': json['name'] ?? '',
      'dose': json['dose'] ?? '',
      'form': json['form'] ?? 'tablet',
      'quantity': json['quantity'] ?? 1,
      'remainingQuantity': json['remainingQuantity'] ?? json['quantity'] ?? 1,
      'doseUnit': json['doseUnit'] ?? 'tablet',
      'time': json['time'] ?? '',
      'hour': json['hour'],
      'minute': json['minute'],
      'frequency': json['frequency'] ?? 1,
      'doseTimes': json['doseTimes'] ?? [],
      'intervalDays': json['intervalDays'] ?? 1,
      'notificationIds': json['notificationIds'] ?? [],
      'takenDoseLogs': convertedTaken,
      'skippedDoseLogs': convertedSkipped,
      'isArchived': json['isArchived'] ?? false,
      'archivedAt': _parseTimestamp(json['archivedAt']),
      'createdAt': _parseTimestamp(json['createdAt']),
    });
  }

  Future<void> _restoreMedicationReport(
    String uid,
    Map<String, dynamic> json,
  ) async {
    final existingId = json['id'] as String?;
    if (existingId == null || existingId.isEmpty) return;

    final existing = await _firestore
        .collection('medication_reports')
        .doc(existingId)
        .get();
    if (existing.exists) return;

    final takenLogs = json['takenDoseLogs'] as Map<String, dynamic>? ?? {};
    final skippedLogs = json['skippedDoseLogs'] as Map<String, dynamic>? ?? {};

    final convertedTaken = <String, dynamic>{};
    for (final entry in takenLogs.entries) {
      convertedTaken[entry.key] = _parseTimestamp(entry.value);
    }
    final convertedSkipped = <String, dynamic>{};
    for (final entry in skippedLogs.entries) {
      convertedSkipped[entry.key] = _parseTimestamp(entry.value);
    }

    await _firestore.collection('medication_reports').doc(existingId).set({
      'userId': uid,
      'sourceMedicationId': json['sourceMedicationId'] ?? existingId,
      'name': json['name'] ?? '',
      'dose': json['dose'] ?? '',
      'form': json['form'] ?? 'tablet',
      'quantity': json['quantity'] ?? 1,
      'remainingQuantity': json['remainingQuantity'] ?? json['quantity'] ?? 1,
      'doseUnit': json['doseUnit'] ?? 'tablet',
      'time': json['time'] ?? '',
      'hour': json['hour'],
      'minute': json['minute'],
      'frequency': json['frequency'] ?? 1,
      'doseTimes': json['doseTimes'] ?? [],
      'intervalDays': json['intervalDays'] ?? 1,
      'notificationIds': json['notificationIds'] ?? [],
      'takenDoseLogs': convertedTaken,
      'skippedDoseLogs': convertedSkipped,
      'isArchived': json['isArchived'] ?? false,
      'archivedAt': _parseTimestamp(json['archivedAt']),
      'isDeleted': json['isDeleted'] ?? false,
      'deletedReason': json['deletedReason'],
      'deletedAt': _parseTimestamp(json['deletedAt']),
      'createdAt': _parseTimestamp(json['createdAt']),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _restoreNotificationSettings(
    String uid,
    Map<String, dynamic> json,
  ) async {
    final docRef = _firestore
        .collection('notification_settings')
        .doc(uid);

    final existing = await docRef.get();
    if (existing.exists) return;

    await docRef.set({
      'userId': uid,
      'quantityAlertEnabled': json['quantityAlertEnabled'] ?? true,
      'quantityAlertSchedule': json['quantityAlertSchedule'] ?? {
        'times': [9, 13, 17, 21],
        'repeatCount': 1,
        'repeatInterval': {'hours': 1},
      },
      'inventoryAlertEnabled': json['inventoryAlertEnabled'] ?? true,
      'inventoryAlertSchedule': json['inventoryAlertSchedule'] ?? {
        'times': [9, 13, 17, 21],
        'urgentThreshold': 2,
      },
      'adherenceAlertEnabled': json['adherenceAlertEnabled'] ?? true,
      'adherenceAlertThreshold': (json['adherenceAlertThreshold'] as num?)?.toDouble() ?? 0.7,
      'soundEnabled': json['soundEnabled'] ?? true,
      'vibrationEnabled': json['vibrationEnabled'] ?? true,
      'createdAt': _parseTimestamp(json['createdAt']),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _restorePharmacyTask(
    String uid,
    Map<String, dynamic> json,
  ) async {
    final existingId = json['id'] as String?;
    if (existingId == null || existingId.isEmpty) return;

    final existing = await _firestore.collection('pharmacy').doc(existingId).get();
    if (existing.exists) return;

    await _firestore.collection('pharmacy').doc(existingId).set({
      'pharmacistId': uid,
      'title': json['title'] ?? '',
      'details': json['details'] ?? '',
      'category': json['category'] ?? 'dispense',
      'priority': json['priority'] ?? 'medium',
      'isCompleted': json['isCompleted'] ?? json['isOutOfStock'] ?? false,
      'quantity': json['quantity'] ?? 0,
      'minQuantity': json['minQuantity'] ?? 5,
      'unit': json['unit'] ?? 'box',
      'isOutOfStock': json['isOutOfStock'] ?? json['isCompleted'] ?? false,
      'createdAt': _parseTimestamp(json['createdAt']),
      'updatedAt': _parseTimestamp(json['updatedAt']),
    });
  }

  Future<void> _restoreSharedMedicine(
    String uid,
    Map<String, dynamic> json,
  ) async {
    final existingId = json['id'] as String?;
    if (existingId == null || existingId.isEmpty) return;

    final existing = await _firestore
        .collection('shared_medicines')
        .doc(existingId)
        .get();
    if (existing.exists) return;

    await _firestore.collection('shared_medicines').doc(existingId).set({
      'pharmacistId': uid,
      'pharmacistEmail': json['pharmacistEmail'] ?? '',
      'pharmacistName': json['pharmacistName'] ?? '',
      'pharmacyName': json['pharmacyName'] ?? '',
      'name': json['name'] ?? '',
      'description': json['description'] ?? '',
      'usageInstructions': json['usageInstructions'] ?? '',
      'dosage': json['dosage'] ?? '',
      'packageSize': json['packageSize'] ?? '',
      'price': (json['price'] as num?)?.toDouble() ?? 0.0,
      'location': json['location'] ?? '',
      'pharmacyPhone': json['pharmacyPhone'] ?? '',
      'category': json['category'] ?? 'General',
      'isAvailable': json['isAvailable'] ?? true,
      'requiresPrescription': json['requiresPrescription'] ?? false,
      'searchIndex': json['searchIndex'] ?? [],
      'imageUrl': json['imageUrl'],
      'imageStoragePath': json['imageStoragePath'],
      'createdAt': _parseTimestamp(json['createdAt']),
      'updatedAt': _parseTimestamp(json['updatedAt']),
    });
  }

  // ---------------------------------------------------------------------------
  // Firestore fetch helpers
  // ---------------------------------------------------------------------------

  Future<AppUserModel?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Future<List<MedicationModel>> _fetchMedications(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: uid)
          .get();
      return snapshot.docs.map(MedicationModel.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMedicationReports(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('medication_reports')
          .where('userId', isEqualTo: uid)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<NotificationSettings?> _fetchNotificationSettings(String uid) async {
    try {
      final doc = await _firestore
          .collection('notification_settings')
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return NotificationSettings.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Future<List<PharmacyTaskModel>> _fetchPharmacyTasks(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('pharmacy')
          .where('pharmacistId', isEqualTo: uid)
          .get();
      return snapshot.docs.map(PharmacyTaskModel.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SharedMedicineModel>> _fetchSharedMedicines(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('shared_medicines')
          .where('pharmacistId', isEqualTo: uid)
          .get();
      return snapshot.docs.map(SharedMedicineModel.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PharmacyRatingModel>> _fetchRatingsSent(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('pharmacy_ratings')
          .where('patientId', isEqualTo: uid)
          .get();
      return snapshot.docs.map(PharmacyRatingModel.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // JSON serialization helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _profileToJson(AppUserModel? profile) {
    if (profile == null) return {};
    return {
      'name': profile.name,
      'username': profile.username,
      'email': profile.email,
      'role': profile.role,
      'approvalStatus': profile.approvalStatus,
      'authProvider': profile.authProvider,
      'photoUrl': profile.photoUrl,
      'pharmacyName': profile.pharmacyName,
      'pharmacyLocation': profile.pharmacyLocation,
      'pharmacyPhone': profile.pharmacyPhone,
    };
  }

  Map<String, dynamic> _medicationToJson(MedicationModel m) {
    final takenLogs = <String, String>{};
    for (final entry in m.takenDoseLogs.entries) {
      takenLogs[entry.key] = entry.value.toIso8601String();
    }
    final skippedLogs = <String, String>{};
    for (final entry in m.skippedDoseLogs.entries) {
      skippedLogs[entry.key] = entry.value.toIso8601String();
    }

    return {
      'id': m.id,
      'userId': m.userId,
      'name': m.name,
      'dose': m.dose,
      'form': m.form,
      'quantity': m.quantity,
      'remainingQuantity': m.remainingQuantity,
      'doseUnit': m.doseUnit,
      'time': m.time,
      'hour': m.hour,
      'minute': m.minute,
      'frequency': m.frequency,
      'doseTimes': m.doseTimes.map((dt) => dt.toMap()).toList(),
      'intervalDays': m.intervalDays,
      'notificationIds': m.notificationIds,
      'isArchived': m.isArchived,
      'archivedAt': m.archivedAt?.toDate().toIso8601String(),
      'createdAt': m.createdAt?.toDate().toIso8601String(),
      'takenDoseLogs': takenLogs,
      'skippedDoseLogs': skippedLogs,
    };
  }

  Map<String, dynamic> _medicationReportToJson(Map<String, dynamic> report) {
    final takenLogs = report['takenDoseLogs'] as Map<String, dynamic>? ?? {};
    final skippedLogs = report['skippedDoseLogs'] as Map<String, dynamic>? ?? {};
    final serializedTaken = <String, String>{};
    for (final entry in takenLogs.entries) {
      if (entry.value is DateTime) {
        serializedTaken[entry.key] = (entry.value as DateTime).toIso8601String();
      } else {
        serializedTaken[entry.key] = entry.value.toString();
      }
    }
    final serializedSkipped = <String, String>{};
    for (final entry in skippedLogs.entries) {
      if (entry.value is DateTime) {
        serializedSkipped[entry.key] = (entry.value as DateTime).toIso8601String();
      } else {
        serializedSkipped[entry.key] = entry.value.toString();
      }
    }
    return {
      'id': report['id'],
      'userId': report['userId'],
      'sourceMedicationId': report['sourceMedicationId'],
      'name': report['name'],
      'dose': report['dose'],
      'form': report['form'],
      'quantity': report['quantity'],
      'remainingQuantity': report['remainingQuantity'],
      'doseUnit': report['doseUnit'],
      'time': report['time'],
      'hour': report['hour'],
      'minute': report['minute'],
      'frequency': report['frequency'],
      'doseTimes': report['doseTimes'],
      'intervalDays': report['intervalDays'],
      'notificationIds': report['notificationIds'],
      'takenDoseLogs': serializedTaken,
      'skippedDoseLogs': serializedSkipped,
      'isArchived': report['isArchived'],
      'archivedAt': _serializeTimestamp(report['archivedAt']),
      'isDeleted': report['isDeleted'],
      'deletedReason': report['deletedReason'],
      'deletedAt': _serializeTimestamp(report['deletedAt']),
      'createdAt': _serializeTimestamp(report['createdAt']),
      'updatedAt': _serializeTimestamp(report['updatedAt']),
    };
  }

  Map<String, dynamic> _notificationSettingsToJson(
    NotificationSettings? ns,
  ) {
    if (ns == null) return {};
    return {
      'userId': ns.userId,
      'quantityAlertEnabled': ns.quantityAlertEnabled,
      'quantityAlertSchedule': ns.quantityAlertSchedule,
      'inventoryAlertEnabled': ns.inventoryAlertEnabled,
      'inventoryAlertSchedule': ns.inventoryAlertSchedule,
      'adherenceAlertEnabled': ns.adherenceAlertEnabled,
      'adherenceAlertThreshold': ns.adherenceAlertThreshold,
      'soundEnabled': ns.soundEnabled,
      'vibrationEnabled': ns.vibrationEnabled,
      'createdAt': ns.createdAt.toIso8601String(),
      'updatedAt': ns.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _pharmacyTaskToJson(PharmacyTaskModel t) {
    return {
      'id': t.id,
      'pharmacistId': t.pharmacistId,
      'title': t.title,
      'details': t.details,
      'category': t.category,
      'priority': t.priority,
      'isCompleted': t.isCompleted,
      'quantity': t.quantity,
      'minQuantity': t.minQuantity,
      'unit': t.unit,
      'isOutOfStock': t.isOutOfStock,
      'createdAt': t.createdAt?.toDate().toIso8601String(),
      'updatedAt': t.updatedAt?.toDate().toIso8601String(),
    };
  }

  Map<String, dynamic> _sharedMedicineToJson(SharedMedicineModel m) {
    return {
      'id': m.id,
      'pharmacistId': m.pharmacistId,
      'pharmacistEmail': m.pharmacistEmail,
      'pharmacistName': m.pharmacistName,
      'pharmacyName': m.pharmacyName,
      'name': m.name,
      'description': m.description,
      'usageInstructions': m.usageInstructions,
      'dosage': m.dosage,
      'packageSize': m.packageSize,
      'price': m.price,
      'location': m.location,
      'pharmacyPhone': m.pharmacyPhone,
      'category': m.category,
      'isAvailable': m.isAvailable,
      'requiresPrescription': m.requiresPrescription,
      'searchIndex': m.searchIndex,
      'imageUrl': m.imageUrl,
      'imageStoragePath': m.imageStoragePath,
      'createdAt': m.createdAt?.toDate().toIso8601String(),
      'updatedAt': m.updatedAt?.toDate().toIso8601String(),
    };
  }

  Map<String, dynamic> _ratingToJson(PharmacyRatingModel r) {
    return {
      'id': r.id,
      'pharmacistId': r.pharmacistId,
      'patientId': r.patientId,
      'patientName': r.patientName,
      'rating': r.rating,
      'comment': r.comment,
      'createdAt': r.createdAt?.toDate().toIso8601String(),
      'updatedAt': r.updatedAt?.toDate().toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  dynamic _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp.fromDate(parsed);
      return null;
    }
    if (value is num) {
      return Timestamp.fromDate(
        DateTime.fromMillisecondsSinceEpoch(value.toInt()),
      );
    }
    return value;
  }

  String? _serializeTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is String) return value;
    return null;
  }

  Future<Map<String, dynamic>?> _tryFetchBackupPreview(Reference ref) async {
    try {
      final bytes = await ref.getData(4096);
      if (bytes == null) return null;
      final chunk = utf8.decode(bytes, allowMalformed: true);
      final firstBrace = chunk.indexOf('{');
      if (firstBrace < 0) return null;
      final trimmed = chunk.substring(firstBrace);
      final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
      return parsed;
    } catch (_) {
      return null;
    }
  }
}
