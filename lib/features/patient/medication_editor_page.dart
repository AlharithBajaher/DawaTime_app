import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/models/medication_model.dart';

class MedicationEditorResult {
  const MedicationEditorResult({
    required this.name,
    required this.form,
    required this.quantity,
    required this.doseUnit,
    required this.doseText,
    required this.time,
    required this.frequency,
  });

  final String name;
  final String form;
  final int quantity;
  final String doseUnit;
  final String doseText;
  final TimeOfDay time;
  final int frequency;

  String get dose => doseText;
}

class MedicationEditorPage extends StatefulWidget {
  const MedicationEditorPage({super.key, this.existing});

  final MedicationModel? existing;

  @override
  State<MedicationEditorPage> createState() => _MedicationEditorPageState();
}

class _MedicationEditorPageState extends State<MedicationEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late TimeOfDay _time;
  late String _selectedForm;
  late String _doseUnit;
  late int _frequency;

  final List<_FormChoice> _forms = const [
    _FormChoice(id: 'tablet', icon: Icons.circle_outlined),
    _FormChoice(id: 'capsule', icon: Icons.medication_outlined),
    _FormChoice(id: 'liquid', icon: Icons.water_drop_outlined),
    _FormChoice(id: 'injection', icon: Icons.vaccines_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final existingDate = widget.existing?.scheduledDateTime(DateTime.now());
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _quantityController = TextEditingController(
      text: '${widget.existing?.quantity ?? 1}',
    );
    _selectedForm = _normalizeForm(widget.existing?.form);
    _doseUnit = _resolvedDoseUnitForForm(
      _selectedForm,
      preferred: widget.existing?.doseUnit,
    );
    _frequency = widget.existing?.frequency ?? 1;
    _time = existingDate == null
        ? const TimeOfDay(hour: 14, minute: 8)
        : TimeOfDay(hour: existingDate.hour, minute: existingDate.minute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      MedicationEditorResult(
        name: _nameController.text.trim(),
        form: _selectedForm,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        doseUnit: _doseUnit,
        doseText:
            '${int.tryParse(_quantityController.text.trim()) ?? 1} ${_doseUnitLabel(_doseUnit)}',
        time: _time,
        frequency: _frequency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doseUnits = _doseUnitsForForm(_selectedForm);
    final selectedDoseUnit = doseUnits.contains(_doseUnit)
        ? _doseUnit
        : doseUnits.first;
    final frequencyItems = <int, String>{
      1: _tr(ar: 'مرة يومياً', en: '1 time daily'),
      2: _tr(ar: 'مرتان يومياً', en: '2 times daily'),
      3: _tr(ar: '3 مرات يومياً', en: '3 times daily'),
      4: _tr(ar: '4 مرات يومياً', en: '4 times daily'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? _tr(ar: 'إضافة دواء', en: 'Add Medication')
              : _tr(ar: 'تعديل الدواء', en: 'Edit Medication'),
        ),
      ),
      body: Container(
        color: const Color(0xFFF3F6FB),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: AppSpacing.pagePaddingWide,
                children: [
                  DepthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr(ar: 'اسم الدواء', en: "Pill's Name"),
                            style: const TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: _tr(
                                ar: 'اسم الدواء',
                                en: 'Medicine Name',
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return _tr(
                                  ar: 'أدخل اسم الدواء.',
                                  en: 'Enter the medicine name.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _tr(ar: 'شكل الدواء', en: 'Medicine Form'),
                            style: const TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _forms.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final choice = _forms[index];
                                final isSelected = _selectedForm == choice.id;
                                return _FormCard(
                                  icon: choice.icon,
                                  label: _formLabel(choice.id),
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedForm = choice.id;
                                      _doseUnit = _resolvedDoseUnitForForm(
                                        choice.id,
                                        preferred: _doseUnit,
                                      );
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: _tr(
                                      ar: 'الكمية',
                                      en: 'Pills Quantity',
                                    ),
                                  ),
                                  validator: (value) {
                                    final parsed = int.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return _tr(
                                        ar: 'أدخل كمية صحيحة.',
                                        en: 'Enter a valid quantity.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedDoseUnit,
                                  decoration: InputDecoration(
                                    labelText: _tr(ar: 'الجرعة', en: 'Dose'),
                                  ),
                                  items: doseUnits
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(_doseUnitLabel(item)),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _doseUnit = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<int>(
                            initialValue: _frequency,
                            decoration: InputDecoration(
                              labelText: _tr(
                                ar: 'التكرار اليومي',
                                en: 'Set Frequency',
                              ),
                            ),
                            items: frequencyItems.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _frequency = value);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _tr(ar: 'وقت التذكير', en: 'Schedule Time'),
                            style: const TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFDCE4F4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.watch_later_outlined,
                                        color: AppPalette.muted,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        _time.format(context),
                                        style: const TextStyle(
                                          fontSize: AppFontSize.bodyLarge,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _pickTime,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(Icons.add_rounded),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ElevatedButton(
                            onPressed: _submit,
                            child: Text(_tr(ar: 'تم', en: 'Done')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formLabel(String id) {
    switch (id) {
      case 'capsule':
        return _tr(ar: 'كبسولة', en: 'Capsule');
      case 'liquid':
        return _tr(ar: 'سائل', en: 'Liquid');
      case 'injection':
        return _tr(ar: 'حقنة', en: 'Injection');
      default:
        return _tr(ar: 'قرص', en: 'Tablet');
    }
  }

  String _normalizeForm(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'capsule':
        return 'capsule';
      case 'liquid':
        return 'liquid';
      case 'injection':
        return 'injection';
      default:
        return 'tablet';
    }
  }

  List<String> _doseUnitsForForm(String form) {
    switch (form) {
      case 'capsule':
        return const ['capsule', 'mg'];
      case 'liquid':
        return const ['ml', 'mg'];
      case 'injection':
        return const ['mg', 'ml'];
      default:
        return const ['tablet', 'mg'];
    }
  }

  String _resolvedDoseUnitForForm(String form, {String? preferred}) {
    final allowedUnits = _doseUnitsForForm(form);
    final normalized = _normalizeDoseUnit(preferred);
    if (allowedUnits.contains(normalized)) {
      return normalized;
    }
    return allowedUnits.first;
  }

  String _normalizeDoseUnit(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'tablet':
      case 'tab':
      case 'pill':
      case 'قرص':
        return 'tablet';
      case 'capsule':
      case 'cap':
      case 'كبسولة':
        return 'capsule';
      case 'ml':
      case 'مل':
        return 'ml';
      case 'mg':
      case 'مجم':
        return 'mg';
      default:
        return '';
    }
  }

  String _doseUnitLabel(String id) {
    switch (id) {
      case 'capsule':
        return _tr(ar: 'كبسولة', en: 'Capsule');
      case 'ml':
        return _tr(ar: 'مل', en: 'ml');
      case 'mg':
        return _tr(ar: 'مجم', en: 'mg');
      default:
        return _tr(ar: 'قرص', en: 'Tablet');
    }
  }
}

class _FormChoice {
  const _FormChoice({required this.id, required this.icon});

  final String id;
  final IconData icon;
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppPalette.patientPrimary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? AppPalette.patientPrimary
                : const Color(0xFFDFE7F6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.10 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? Colors.white : AppPalette.muted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppPalette.text,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
