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
    required this.doseTimes,
    required this.intervalDays,
  });

  final String name;
  final String form;
  final int quantity;
  final String doseUnit;
  final String doseText;
  final List<MedicationDoseTime> doseTimes;
  final int intervalDays;

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
  late String _selectedForm;
  late String _doseUnit;
  late int _dailyDoseCount;
  late int _intervalDays;
  late List<TimeOfDay> _doseTimes;

  final List<_FormChoice> _forms = const [
    _FormChoice(id: 'tablet', icon: Icons.medication_rounded),
    _FormChoice(id: 'capsule', icon: Icons.science_rounded),
    _FormChoice(id: 'syrup', icon: Icons.medication_liquid_rounded),
    _FormChoice(id: 'drops', icon: Icons.water_drop_rounded),
    _FormChoice(id: 'injection', icon: Icons.vaccines_rounded),
    _FormChoice(id: 'inhaler', icon: Icons.air_rounded),
    _FormChoice(id: 'ointment', icon: Icons.spa_rounded),
    _FormChoice(id: 'powder', icon: Icons.blur_on_rounded),
    _FormChoice(id: 'patch', icon: Icons.healing_rounded),
    _FormChoice(id: 'spray', icon: Icons.shower_rounded),
  ];

  final List<int> _intervalOptions = const [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    10,
    14,
    21,
    30,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _quantityController = TextEditingController(
      text: '${widget.existing?.quantity ?? 1}',
    );
    _selectedForm = _normalizeForm(widget.existing?.form);
    _doseUnit = _resolvedDoseUnitForForm(
      _selectedForm,
      preferred: widget.existing?.doseUnit,
    );
    _dailyDoseCount = (widget.existing?.sortedDoseTimes.length ?? 1).clamp(
      1,
      6,
    );
    _intervalDays = _intervalOptions.contains(widget.existing?.intervalDays)
        ? widget.existing!.intervalDays
        : 1;
    _doseTimes = _initialDoseTimes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  List<TimeOfDay> _initialDoseTimes() {
    final existingTimes = widget.existing?.sortedDoseTimes
        .map((item) => TimeOfDay(hour: item.hour, minute: item.minute))
        .toList(growable: false);
    if (existingTimes != null && existingTimes.isNotEmpty) {
      return List<TimeOfDay>.generate(_dailyDoseCount, (index) {
        return index < existingTimes.length
            ? existingTimes[index]
            : _suggestTimeForIndex(index, existingTimes.first);
      });
    }

    const baseTime = TimeOfDay(hour: 8, minute: 0);
    return List<TimeOfDay>.generate(
      _dailyDoseCount,
      (index) => _suggestTimeForIndex(index, baseTime),
    );
  }

  TimeOfDay _suggestTimeForIndex(int index, TimeOfDay baseTime) {
    final totalMinutes =
        (baseTime.hour * 60 + baseTime.minute + index * 360) % 1440;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  void _syncDoseTimeCount(int count) {
    setState(() {
      _dailyDoseCount = count;
      if (_doseTimes.length > count) {
        _doseTimes = _doseTimes.take(count).toList(growable: false);
        return;
      }

      while (_doseTimes.length < count) {
        final baseTime = _doseTimes.isEmpty
            ? const TimeOfDay(hour: 8, minute: 0)
            : _doseTimes.first;
        _doseTimes = [
          ..._doseTimes,
          _suggestTimeForIndex(_doseTimes.length, baseTime),
        ];
      }
    });
  }

  Future<void> _pickDoseTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index],
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _doseTimes = List<TimeOfDay>.from(_doseTimes)..[index] = picked;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final doseTimes =
        _doseTimes
            .map(
              (doseTime) => MedicationDoseTime(
                hour: doseTime.hour,
                minute: doseTime.minute,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.sortValue.compareTo(b.sortValue));

    Navigator.of(context).pop(
      MedicationEditorResult(
        name: _nameController.text.trim(),
        form: _selectedForm,
        quantity: quantity,
        doseUnit: _doseUnit,
        doseText: '$quantity ${_doseUnitLabel(_doseUnit)}',
        doseTimes: doseTimes,
        intervalDays: _intervalDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doseUnits = _doseUnitsForForm(_selectedForm);
    final selectedDoseUnit = doseUnits.contains(_doseUnit)
        ? _doseUnit
        : doseUnits.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? _tr(ar: 'إضافة دواء', en: 'Add medicine')
              : _tr(ar: 'تعديل الدواء', en: 'Edit medicine'),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        color: AppPalette.canvas,
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
                          _SectionTitle(
                            title: _tr(ar: 'اسم الدواء', en: 'Medicine name'),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: _tr(
                                ar: 'اكتب اسم الدواء',
                                en: 'Enter medicine name',
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
                          _SectionTitle(
                            title: _tr(ar: 'شكل الدواء', en: 'Medicine form'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 108,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _forms.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final choice = _forms[index];
                                return _FormCard(
                                  icon: choice.icon,
                                  label: _formLabel(choice.id),
                                  selected: _selectedForm == choice.id,
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
                                      en: 'Stock quantity',
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
                                    labelText: _tr(
                                      ar: 'وحدة الجرعة',
                                      en: 'Dose unit',
                                    ),
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
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _dailyDoseCount,
                                  decoration: InputDecoration(
                                    labelText: _tr(
                                      ar: 'عدد الجرعات اليومية',
                                      en: 'Daily doses',
                                    ),
                                  ),
                                  items:
                                      List<int>.generate(
                                            6,
                                            (index) => index + 1,
                                          )
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(
                                                _tr(
                                                  ar: '$value مرة يومياً',
                                                  en: '$value time(s) daily',
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _syncDoseTimeCount(value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _intervalDays,
                                  decoration: InputDecoration(
                                    labelText: _tr(
                                      ar: 'يتكرر كل',
                                      en: 'Repeats every',
                                    ),
                                  ),
                                  items: _intervalOptions
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(
                                            value == 1
                                                ? _tr(
                                                    ar: 'كل يوم',
                                                    en: 'Every day',
                                                  )
                                                : _tr(
                                                    ar: 'كل $value أيام',
                                                    en: 'Every $value days',
                                                  ),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _intervalDays = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _SectionTitle(
                            title: _tr(ar: 'أوقات الجرعات', en: 'Dose times'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: Column(
                              key: ValueKey(_doseTimes.length),
                              children: List.generate(_doseTimes.length, (
                                index,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _DoseTimeTile(
                                    index: index,
                                    timeLabel: _doseTimes[index].format(
                                      context,
                                    ),
                                    onTap: () => _pickDoseTime(index),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppPalette.patientPrimary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Text(
                              _tr(
                                ar: 'سيتم تذكيرك ${_doseTimes.length} مرة، ${_intervalDays == 1 ? 'كل يوم' : 'كل $_intervalDays أيام'}.',
                                en: 'You will be reminded ${_doseTimes.length} time(s), ${_intervalDays == 1 ? 'every day' : 'every $_intervalDays days'}.',
                              ),
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontSize: AppFontSize.body,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              _tr(ar: 'حفظ الدواء', en: 'Save medicine'),
                            ),
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
      case 'syrup':
        return _tr(ar: 'شراب', en: 'Syrup');
      case 'drops':
        return _tr(ar: 'قطرات', en: 'Drops');
      case 'injection':
        return _tr(ar: 'حقنة', en: 'Injection');
      case 'inhaler':
        return _tr(ar: 'بخاخ تنفس', en: 'Inhaler');
      case 'ointment':
        return _tr(ar: 'مرهم', en: 'Ointment');
      case 'powder':
        return _tr(ar: 'بودرة', en: 'Powder');
      case 'patch':
        return _tr(ar: 'لاصقة', en: 'Patch');
      case 'spray':
        return _tr(ar: 'رذاذ', en: 'Spray');
      default:
        return _tr(ar: 'قرص', en: 'Tablet');
    }
  }

  String _normalizeForm(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'capsule':
        return 'capsule';
      case 'liquid':
      case 'syrup':
        return 'syrup';
      case 'drops':
        return 'drops';
      case 'injection':
        return 'injection';
      case 'inhaler':
        return 'inhaler';
      case 'ointment':
        return 'ointment';
      case 'powder':
        return 'powder';
      case 'patch':
        return 'patch';
      case 'spray':
        return 'spray';
      default:
        return 'tablet';
    }
  }

  List<String> _doseUnitsForForm(String form) {
    switch (form) {
      case 'capsule':
        return const ['capsule', 'mg'];
      case 'syrup':
      case 'drops':
      case 'spray':
        return const ['ml', 'drop', 'puff', 'mg'];
      case 'injection':
        return const ['ml', 'mg', 'iu'];
      case 'inhaler':
        return const ['puff', 'mg'];
      case 'ointment':
        return const ['g', 'mg'];
      case 'powder':
        return const ['g', 'sachet', 'mg'];
      case 'patch':
        return const ['patch', 'mg'];
      default:
        return const ['tablet', 'mg'];
    }
  }

  String _resolvedDoseUnitForForm(String form, {String? preferred}) {
    final allowedUnits = _doseUnitsForForm(form);
    final normalized = _normalizeDoseUnit(preferred);
    return allowedUnits.contains(normalized) ? normalized : allowedUnits.first;
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
      case 'drop':
      case 'drops':
      case 'قطرة':
        return 'drop';
      case 'puff':
      case 'بخة':
        return 'puff';
      case 'g':
      case 'جم':
        return 'g';
      case 'patch':
      case 'لاصقة':
        return 'patch';
      case 'sachet':
      case 'كيس':
        return 'sachet';
      case 'iu':
        return 'iu';
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
      case 'drop':
        return _tr(ar: 'قطرة', en: 'Drop');
      case 'puff':
        return _tr(ar: 'بخة', en: 'Puff');
      case 'g':
        return _tr(ar: 'جم', en: 'g');
      case 'patch':
        return _tr(ar: 'لاصقة', en: 'Patch');
      case 'sachet':
        return _tr(ar: 'كيس', en: 'Sachet');
      case 'iu':
        return 'IU';
      default:
        return _tr(ar: 'قرص', en: 'Tablet');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppFontSize.title,
        fontWeight: FontWeight.w800,
        color: AppPalette.text,
      ),
    );
  }
}

class _DoseTimeTile extends StatelessWidget {
  const _DoseTimeTile({
    required this.index,
    required this.timeLabel,
    required this.onTap,
  });

  final int index;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFDCE4F4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppPalette.patientPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppPalette.patientPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      ar: 'وقت الجرعة ${index + 1}',
                      en: 'Dose ${index + 1} time',
                    ),
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontSize: AppFontSize.title,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: AppPalette.patientPrimary,
            ),
          ],
        ),
      ),
    );
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 94,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
