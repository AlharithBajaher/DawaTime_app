import 'package:flutter/material.dart';
import '../../data/services/medication_service.dart';
import '../../data/models/medication_model.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});
 
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {

  final MedicationService _medicationService = MedicationService();

  void _showAddMedicationDialog() {

    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Medication"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Medication Name"),
              ),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: "Dose"),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: "Time"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {

              if (nameController.text.isEmpty ||
                  doseController.text.isEmpty ||
                  timeController.text.isEmpty) {
                return;
              }

              await _medicationService.addMedication(
                name: nameController.text.trim(),
                dose: doseController.text.trim(),
                time: timeController.text.trim(),
              );

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medications"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<MedicationModel>>(
        stream: _medicationService.getUserMedications(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No medications yet"),
            );
          }

          final medications = snapshot.data!;

          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {

              final med = medications[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(med.name),
                  subtitle: Text("${med.dose} • ${med.time}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromARGB(255, 239, 76, 64)),
                    onPressed: () async {
                      await _medicationService.deleteMedication(med.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}