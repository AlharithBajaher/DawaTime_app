import 'package:flutter_test/flutter_test.dart';

import 'package:dawatime_app/data/models/medication_model.dart';

void main() {
  test('MedicationModel formats stored schedule time safely', () {
    final medication = MedicationModel(
      id: '1',
      userId: 'patient-1',
      name: 'Vitamin D',
      dose: '1 capsule',
      form: 'capsule',
      quantity: 1,
      doseUnit: 'capsule',
      time: '9:05 AM',
      hour: 9,
      minute: 5,
      frequency: 2,
      notificationIds: const [1, 2],
    );

    expect(medication.displayTime(), '9:05 AM');
    expect(medication.scheduledDateTime(DateTime(2026, 3, 26)).hour, 9);
  });
}
