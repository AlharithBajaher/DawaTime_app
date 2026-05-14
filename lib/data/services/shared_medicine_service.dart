import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user_model.dart';
import '../models/shared_medicine_model.dart';

class SharedMedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;
  String get _email => _auth.currentUser?.email ?? '';

  Stream<List<SharedMedicineModel>> watchMarketplaceMedicines() {
    return _firestore.collection('shared_medicines').snapshots().map((
      snapshot,
    ) {
      final medicines = snapshot.docs
          .map(SharedMedicineModel.fromFirestore)
          .toList(growable: false);

      return _sortMedicines(medicines);
    });
  }

  Stream<List<SharedMedicineModel>> watchMyPublishedMedicines() {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('shared_medicines')
        .where('pharmacistId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final medicines = snapshot.docs
              .map(SharedMedicineModel.fromFirestore)
              .toList(growable: false);

          return _sortMedicines(medicines);
        });
  }

  Future<SharedMedicineSaveResult> addSharedMedicine({
    required String name,
    required String description,
    required String usageInstructions,
    required String dosage,
    required String packageSize,
    required double price,
    required String category,
    required bool isAvailable,
    required bool requiresPrescription,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated pharmacist found.');
    }
    final profile = await _loadCurrentPharmacistProfile(uid);

    final docRef = _firestore.collection('shared_medicines').doc();
    final uploadOutcome = await _tryUploadImage(
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      medicineId: docRef.id,
    );
    final upload = uploadOutcome.uploadedImage;

    await docRef.set({
      'pharmacistId': uid,
      'pharmacistEmail': _email,
      'pharmacistName': profile.pharmacistName,
      'pharmacyName': profile.pharmacyName,
      'name': name,
      'description': description,
      'usageInstructions': usageInstructions,
      'dosage': dosage,
      'packageSize': packageSize,
      'price': price,
      'location': profile.pharmacyLocation,
      'pharmacyPhone': profile.pharmacyPhone,
      'category': category,
      'isAvailable': isAvailable,
      'requiresPrescription': requiresPrescription,
      'searchIndex': SharedMedicineModel.buildSearchIndex(
        name: name,
        pharmacistName: profile.pharmacistName,
        pharmacyName: profile.pharmacyName,
        description: description,
        dosage: dosage,
        category: category,
        location: profile.pharmacyLocation,
      ),
      'imageUrl': upload?.downloadUrl,
      'imageStoragePath': upload?.storagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return SharedMedicineSaveResult(
      savedWithoutImage: uploadOutcome.savedWithoutImage,
    );
  }

  Future<SharedMedicineSaveResult> updateSharedMedicine({
    required SharedMedicineModel existing,
    required String name,
    required String description,
    required String usageInstructions,
    required String dosage,
    required String packageSize,
    required double price,
    required String category,
    required bool isAvailable,
    required bool requiresPrescription,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    _assertOwner(existing);
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated pharmacist found.');
    }
    final profile = await _loadCurrentPharmacistProfile(uid);

    final uploadOutcome = await _tryUploadImage(
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      medicineId: existing.id,
    );
    final upload = uploadOutcome.uploadedImage;

    await _firestore.collection('shared_medicines').doc(existing.id).update({
      'pharmacistName': profile.pharmacistName,
      'pharmacyName': profile.pharmacyName,
      'name': name,
      'description': description,
      'usageInstructions': usageInstructions,
      'dosage': dosage,
      'packageSize': packageSize,
      'price': price,
      'location': profile.pharmacyLocation,
      'pharmacyPhone': profile.pharmacyPhone,
      'category': category,
      'isAvailable': isAvailable,
      'requiresPrescription': requiresPrescription,
      'searchIndex': SharedMedicineModel.buildSearchIndex(
        name: name,
        pharmacistName: profile.pharmacistName,
        pharmacyName: profile.pharmacyName,
        description: description,
        dosage: dosage,
        category: category,
        location: profile.pharmacyLocation,
      ),
      if (upload != null) 'imageUrl': upload.downloadUrl,
      if (upload != null) 'imageStoragePath': upload.storagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (upload != null &&
        existing.imageStoragePath != null &&
        existing.imageStoragePath!.isNotEmpty &&
        existing.imageStoragePath != upload.storagePath) {
      await _deleteStorageObject(existing.imageStoragePath!);
    }

    return SharedMedicineSaveResult(
      savedWithoutImage: uploadOutcome.savedWithoutImage,
    );
  }

  Future<void> updateAvailability({
    required SharedMedicineModel medicine,
    required bool isAvailable,
  }) async {
    _assertOwner(medicine);
    await _firestore.collection('shared_medicines').doc(medicine.id).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSharedMedicine(SharedMedicineModel medicine) async {
    _assertOwner(medicine);
    await _firestore.collection('shared_medicines').doc(medicine.id).delete();

    final path = medicine.imageStoragePath;
    if (path != null && path.isNotEmpty) {
      await _deleteStorageObject(path);
    }
  }

  List<SharedMedicineModel> _sortMedicines(
    List<SharedMedicineModel> medicines,
  ) {
    final sorted = List<SharedMedicineModel>.from(medicines);
    sorted.sort((a, b) {
      final createdA = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final createdB = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return createdB.compareTo(createdA);
    });
    return sorted;
  }

  Future<_UploadedMedicineImage> _uploadImage({
    required Uint8List bytes,
    required String? fileName,
    required String medicineId,
  }) async {
    final safeName = (fileName == null || fileName.trim().isEmpty)
        ? 'medicine.jpg'
        : fileName.split('/').last.split('\\').last;
    final storagePath =
        'shared_medicines/$medicineId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(storagePath);

    final uploadSnapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: _resolveMimeType(safeName)),
    );

    final downloadUrl = await uploadSnapshot.ref.getDownloadURL();
    return _UploadedMedicineImage(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }

  Future<_ImageUploadOutcome> _tryUploadImage({
    required Uint8List? imageBytes,
    required String? imageFileName,
    required String medicineId,
  }) async {
    if (imageBytes == null) {
      return const _ImageUploadOutcome(uploadedImage: null);
    }

    try {
      final uploaded = await _uploadImage(
        bytes: imageBytes,
        fileName: imageFileName,
        medicineId: medicineId,
      );
      return _ImageUploadOutcome(uploadedImage: uploaded);
    } on FirebaseException catch (error) {
      if (_isStorageUnavailableError(error)) {
        return const _ImageUploadOutcome(
          uploadedImage: null,
          savedWithoutImage: true,
        );
      }
      rethrow;
    }
  }

  bool _isStorageUnavailableError(FirebaseException error) {
    const knownCodes = {
      'object-not-found',
      'bucket-not-found',
      'project-not-found',
      'no-default-bucket',
    };
    if (knownCodes.contains(error.code)) {
      return true;
    }

    final message = (error.message ?? '').toLowerCase();
    return message.contains('no object exists') ||
        message.contains('bucket') ||
        message.contains('storage');
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  String _resolveMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  void _assertOwner(SharedMedicineModel medicine) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated pharmacist found.');
    }
    if (medicine.pharmacistId.isNotEmpty && medicine.pharmacistId != uid) {
      throw StateError(
        'You can only manage medicines published by your account.',
      );
    }
  }

  Future<_PharmacistPublishProfile> _loadCurrentPharmacistProfile(
    String uid,
  ) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) {
      throw StateError('Pharmacist profile was not found.');
    }

    final profile = AppUserModel.fromFirestore(snapshot);
    final pharmacyName = profile.pharmacyName?.trim() ?? '';
    final pharmacyLocation = profile.pharmacyLocation?.trim() ?? '';
    if (pharmacyName.isEmpty || pharmacyLocation.isEmpty) {
      throw StateError(
        'Please complete the pharmacy name and location in your profile before publishing medicines.',
      );
    }

    return _PharmacistPublishProfile(
      pharmacistName: profile.displayName,
      pharmacyName: pharmacyName,
      pharmacyLocation: pharmacyLocation,
      pharmacyPhone: profile.pharmacyPhone?.trim() ?? '',
    );
  }
}

class _UploadedMedicineImage {
  const _UploadedMedicineImage({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class _ImageUploadOutcome {
  const _ImageUploadOutcome({
    required this.uploadedImage,
    this.savedWithoutImage = false,
  });

  final _UploadedMedicineImage? uploadedImage;
  final bool savedWithoutImage;
}

class SharedMedicineSaveResult {
  const SharedMedicineSaveResult({required this.savedWithoutImage});

  final bool savedWithoutImage;
}

class _PharmacistPublishProfile {
  const _PharmacistPublishProfile({
    required this.pharmacistName,
    required this.pharmacyName,
    required this.pharmacyLocation,
    required this.pharmacyPhone,
  });

  final String pharmacistName;
  final String pharmacyName;
  final String pharmacyLocation;
  final String pharmacyPhone;
}
