import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/pharmacy_task_model.dart';
import '../../data/services/pharmacy_service.dart';

class PharmacistInventoryEditorPage extends StatefulWidget {
  const PharmacistInventoryEditorPage({super.key, this.existing});

  final PharmacyTaskModel? existing;

  @override
  State<PharmacistInventoryEditorPage> createState() =>
      _PharmacistInventoryEditorPageState();
}

class _PharmacistInventoryEditorPageState
    extends State<PharmacistInventoryEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final PharmacyService _pharmacyService = PharmacyService();
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minQuantityController;
  late String _category;
  late String _priority;
  late String _unit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _detailsController = TextEditingController(
      text: widget.existing?.details ?? '',
    );
    _quantityController = TextEditingController(
      text: '${widget.existing?.quantity ?? 0}',
    );
    _minQuantityController = TextEditingController(
      text: '${widget.existing?.minQuantity ?? 5}',
    );
    _category = widget.existing?.category ?? 'dispense';
    _priority = widget.existing?.priority ?? 'medium';
    _unit = widget.existing?.unit ?? 'box';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    super.dispose();
  }

  String get _pageTitle {
    final isEdit = widget.existing != null;
    return context.tr(
      ar: isEdit ? 'تعديل عنصر المخزون' : 'إضافة عنصر مخزون',
      en: isEdit ? 'Edit inventory item' : 'Add inventory item',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.existing == null) {
        await _pharmacyService.addTask(
          title: _titleController.text.trim(),
          details: _detailsController.text.trim(),
          category: _category,
          priority: _priority,
          quantity: int.parse(_quantityController.text.trim()),
          minQuantity: int.parse(_minQuantityController.text.trim()),
          unit: _unit,
        );
      } else {
        await _pharmacyService.updateTask(
          taskId: widget.existing!.id,
          title: _titleController.text.trim(),
          details: _detailsController.text.trim(),
          category: _category,
          priority: _priority,
          quantity: int.parse(_quantityController.text.trim()),
          minQuantity: int.parse(_minQuantityController.text.trim()),
          unit: _unit,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تعذر حفظ عنصر المخزون: $error',
              en: 'Unable to save inventory item: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.existing == null
                            ? Icons.add_rounded
                            : Icons.save_rounded,
                        size: 18,
                      ),
                label: Text(
                  widget.existing == null
                      ? context.tr(ar: 'حفظ', en: 'Save')
                      : context.tr(ar: 'تحديث', en: 'Update'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          120,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            ar: 'اسم العنصر',
                            en: 'Item name',
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? context.tr(
                                    ar: 'أدخل اسم عنصر المخزون.',
                                    en: 'Enter the item name.',
                                  )
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _detailsController,
                        textInputAction: TextInputAction.next,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            ar: 'وصف مختصر',
                            en: 'Short description',
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? context.tr(
                                    ar: 'أدخل وصفاً مختصراً.',
                                    en: 'Enter a short description.',
                                  )
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSection(
                    title: context.tr(ar: 'الكمية', en: 'Quantity'),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  ar: 'الكمية الحالية',
                                  en: 'Current quantity',
                                ),
                              ),
                              validator: (value) {
                                final parsed =
                                    int.tryParse((value ?? '').trim());
                                if (parsed == null || parsed < 0) {
                                  return context.tr(
                                    ar: 'أدخل كمية صحيحة.',
                                    en: 'Enter a valid quantity.',
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _minQuantityController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  ar: 'حد التنبيه',
                                  en: 'Low stock threshold',
                                ),
                              ),
                              validator: (value) {
                                final parsed =
                                    int.tryParse((value ?? '').trim());
                                if (parsed == null || parsed < 0) {
                                  return context.tr(
                                    ar: 'أدخل حد تنبيه صحيح.',
                                    en: 'Enter a valid threshold.',
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSection(
                    title: context.tr(ar: 'الوحدة', en: 'Unit'),
                    children: [
                      _ChoicePillRow(
                        options: [
                          _ChoiceOption(
                            value: 'box',
                            labelAr: 'علبة',
                            labelEn: 'Box',
                          ),
                          _ChoiceOption(
                            value: 'strip',
                            labelAr: 'شريط',
                            labelEn: 'Strip',
                          ),
                          _ChoiceOption(
                            value: 'pack',
                            labelAr: 'عبوة',
                            labelEn: 'Pack',
                          ),
                        ],
                        selected: _unit,
                        onSelected: (v) => setState(() => _unit = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSection(
                    title: context.tr(ar: 'التصنيف', en: 'Category'),
                    children: [
                      _ChoicePillRow(
                        options: [
                          _ChoiceOption(
                            value: 'dispense',
                            labelAr: 'صرف',
                            labelEn: 'Dispense',
                          ),
                          _ChoiceOption(
                            value: 'inventory',
                            labelAr: 'مخزون',
                            labelEn: 'Inventory',
                          ),
                          _ChoiceOption(
                            value: 'consultation',
                            labelAr: 'استشارة',
                            labelEn: 'Consultation',
                          ),
                        ],
                        selected: _category,
                        onSelected: (v) => setState(() => _category = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSection(
                    title: context.tr(ar: 'الأولوية', en: 'Priority'),
                    children: [
                      _ChoicePillRow(
                        options: [
                          _ChoiceOption(
                            value: 'low',
                            labelAr: 'منخفضة',
                            labelEn: 'Low',
                          ),
                          _ChoiceOption(
                            value: 'medium',
                            labelAr: 'متوسطة',
                            labelEn: 'Medium',
                          ),
                          _ChoiceOption(
                            value: 'high',
                            labelAr: 'عالية',
                            labelEn: 'High',
                          ),
                        ],
                        selected: _priority,
                        onSelected: (v) => setState(() => _priority = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    String? title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w800,
                color: AppPalette.muted,
              ),
            ),
          ),
        ],
        ...children,
      ],
    );
  }
}

class _ChoiceOption {
  const _ChoiceOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
  });

  final String value;
  final String labelAr;
  final String labelEn;
}

class _ChoicePillRow extends StatelessWidget {
  const _ChoicePillRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_ChoiceOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: option == options.last ? 0 : AppSpacing.xs,
                right: option == options.first ? 0 : AppSpacing.xs,
              ),
              child: ChoiceChip(
                label: Text(
                  context.tr(ar: option.labelAr, en: option.labelEn),
                  textAlign: TextAlign.center,
                ),
                selected: selected == option.value,
                onSelected: (_) => onSelected(option.value),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
