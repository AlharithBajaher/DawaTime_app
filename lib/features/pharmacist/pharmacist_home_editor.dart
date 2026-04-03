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
  late String _category;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _detailsController = TextEditingController(
      text: widget.existing?.details ?? '',
    );
    _category = widget.existing?.category ?? 'dispense';
    _priority = widget.existing?.priority ?? 'medium';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
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
                        ? 'إضافة مهمة صيدلية'
                        : 'تعديل المهمة',
                    style: const TextStyle(
                      fontSize: AppFontSize.sectionTitle,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المهمة',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل عنوان المهمة.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'وصف مختصر',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل وصفاً مختصراً.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ChoicePill(
                        label: 'صرف',
                        selected: _category == 'dispense',
                        onTap: () => setState(() => _category = 'dispense'),
                      ),
                      _ChoicePill(
                        label: 'مخزون',
                        selected: _category == 'inventory',
                        onTap: () => setState(() => _category = 'inventory'),
                      ),
                      _ChoicePill(
                        label: 'استشارة',
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
                        label: 'منخفضة',
                        selected: _priority == 'low',
                        onTap: () => setState(() => _priority = 'low'),
                      ),
                      _ChoicePill(
                        label: 'متوسطة',
                        selected: _priority == 'medium',
                        onTap: () => setState(() => _priority = 'medium'),
                      ),
                      _ChoicePill(
                        label: 'عالية',
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
                        ),
                      );
                    },
                    child: Text(
                      widget.existing == null
                          ? 'حفظ المهمة'
                          : 'تحديث المهمة',
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
  });

  final String title;
  final String details;
  final String category;
  final String priority;
}
