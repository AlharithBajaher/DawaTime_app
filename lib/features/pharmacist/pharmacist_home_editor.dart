part of 'pharmacist_home.dart';

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({this.existing});

  final PharmacyTaskModel? existing;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minQuantityController;
  late String _category;
  late String _priority;
  late String _unit;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DepthCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existing == null
                        ? context.tr(
                            ar: 'إضافة عنصر مخزون',
                            en: 'Add inventory item',
                          )
                        : context.tr(
                            ar: 'تعديل عنصر المخزون',
                            en: 'Edit inventory item',
                          ),
                    style: const TextStyle(
                      fontSize: AppFontSize.sectionTitle,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        ar: 'اسم العنصر',
                        en: 'Item name',
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.tr(
                            ar: 'أدخل اسم عنصر المخزون.',
                            en: 'Enter the item name.',
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        ar: 'وصف مختصر',
                        en: 'Short description',
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.tr(
                            ar: 'أدخل وصفاً مختصراً.',
                            en: 'Enter a short description.',
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              ar: 'الكمية الحالية',
                              en: 'Current quantity',
                            ),
                          ),
                          validator: (value) {
                            final parsed = int.tryParse((value ?? '').trim());
                            if (parsed == null || parsed < 0) {
                              return context.tr(
                                ar: 'أدخل كمية صحيحة (0 أو أكثر).',
                                en: 'Enter a valid quantity (0 or more).',
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _minQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              ar: 'حد التنبيه',
                              en: 'Low stock threshold',
                            ),
                          ),
                          validator: (value) {
                            final parsed = int.tryParse((value ?? '').trim());
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
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ChoicePill(
                        label: context.tr(ar: 'علبة', en: 'Box'),
                        selected: _unit == 'box',
                        onTap: () => setState(() => _unit = 'box'),
                      ),
                      _ChoicePill(
                        label: context.tr(ar: 'شريط', en: 'Strip'),
                        selected: _unit == 'strip',
                        onTap: () => setState(() => _unit = 'strip'),
                      ),
                      _ChoicePill(
                        label: context.tr(ar: 'عبوة', en: 'Pack'),
                        selected: _unit == 'pack',
                        onTap: () => setState(() => _unit = 'pack'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ChoicePill(
                        label: context.tr(ar: 'صرف', en: 'Dispense'),
                        selected: _category == 'dispense',
                        onTap: () => setState(() => _category = 'dispense'),
                      ),
                      _ChoicePill(
                        label: context.tr(ar: 'مخزون', en: 'Inventory'),
                        selected: _category == 'inventory',
                        onTap: () => setState(() => _category = 'inventory'),
                      ),
                      _ChoicePill(
                        label: context.tr(ar: 'استشارة', en: 'Consultation'),
                        selected: _category == 'consultation',
                        onTap: () => setState(() => _category = 'consultation'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ChoicePill(
                        label: context.tr(ar: 'منخفضة', en: 'Low'),
                        selected: _priority == 'low',
                        onTap: () => setState(() => _priority = 'low'),
                      ),
                      _ChoicePill(
                        label: context.tr(ar: 'متوسطة', en: 'Medium'),
                        selected: _priority == 'medium',
                        onTap: () => setState(() => _priority = 'medium'),
                      ),
                      _ChoicePill(
                        label: context.tr(ar: 'عالية', en: 'High'),
                        selected: _priority == 'high',
                        onTap: () => setState(() => _priority = 'high'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      Navigator.pop(
                        context,
                        _TaskDraft(
                          title: _titleController.text.trim(),
                          details: _detailsController.text.trim(),
                          category: _category,
                          priority: _priority,
                          quantity: int.parse(_quantityController.text.trim()),
                          minQuantity: int.parse(
                            _minQuantityController.text.trim(),
                          ),
                          unit: _unit,
                        ),
                      );
                    },
                    child: Text(
                      widget.existing == null
                          ? context.tr(ar: 'حفظ العنصر', en: 'Save item')
                          : context.tr(ar: 'تحديث العنصر', en: 'Update item'),
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
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TaskDraft {
  const _TaskDraft({
    required this.title,
    required this.details,
    required this.category,
    required this.priority,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
  });

  final String title;
  final String details;
  final String category;
  final String priority;
  final int quantity;
  final int minQuantity;
  final String unit;
}
