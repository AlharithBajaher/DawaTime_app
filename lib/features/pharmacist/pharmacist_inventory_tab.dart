part of 'pharmacist_home.dart';

class _WorkflowTabModern extends StatelessWidget {
  const _WorkflowTabModern({
    required this.tasks,
    required this.onToggle,
    required this.onAdjust,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PharmacyTaskModel> tasks;
  final Future<void> Function(PharmacyTaskModel) onToggle;
  final Future<void> Function(PharmacyTaskModel task, int delta) onAdjust;
  final ValueChanged<PharmacyTaskModel> onEdit;
  final ValueChanged<PharmacyTaskModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pharmacistPagePadding,
      children: [
        Text(
          context.tr(ar: 'إدارة المخزون', en: 'Inventory management'),
          style: const TextStyle(
            fontSize: AppFontSize.pageTitle,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr(
            ar: 'واجهة مخزون واضحة: التحكم بالكمية، حالة النفاد، والتعديل السريع لكل عنصر.',
            en: 'A clear inventory view with quick quantity control, stock status, and edit actions.',
          ),
          style: const TextStyle(fontSize: AppFontSize.body),
        ),
        const SizedBox(height: AppSpacing.md),
        if (tasks.isEmpty)
          DepthCard(
            child: Text(
              context.tr(
                ar: 'لا توجد عناصر مخزون حالياً. أضف عنصراً جديداً من الزر العائم.',
                en: 'No inventory items right now. Add one from the floating button.',
              ),
              style: const TextStyle(fontSize: AppFontSize.body),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InventoryStockCard(
                task: task,
                onToggle: onToggle,
                onAdjust: onAdjust,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ),
      ],
    );
  }
}

class _InventoryStockCard extends StatelessWidget {
  const _InventoryStockCard({
    required this.task,
    required this.onToggle,
    required this.onAdjust,
    required this.onEdit,
    required this.onDelete,
  });

  final PharmacyTaskModel task;
  final Future<void> Function(PharmacyTaskModel) onToggle;
  final Future<void> Function(PharmacyTaskModel task, int delta) onAdjust;
  final ValueChanged<PharmacyTaskModel> onEdit;
  final ValueChanged<PharmacyTaskModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _WorkflowTile(task: task)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: context.tr(
                        ar: 'زيادة وحدة',
                        en: 'Increase by one',
                      ),
                      onPressed: () => onAdjust(task, 1),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppPalette.pharmacistPrimary,
                      ),
                    ),
                    Text(
                      '${task.quantity}',
                      style: const TextStyle(
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr(
                        ar: 'خصم وحدة',
                        en: 'Decrease by one',
                      ),
                      onPressed: task.quantity <= 0
                          ? null
                          : () => onAdjust(task, -1),
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppPalette.muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  context.tr(
                    ar: 'حد التنبيه: ${task.minQuantity} • ${_unitLabel(context, task.unit)}',
                    en: 'Low-stock: ${task.minQuantity} • ${_unitLabel(context, task.unit)}',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(task);
                        } else {
                          onDelete(task);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.tr(ar: 'تعديل', en: 'Edit')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.tr(ar: 'حذف', en: 'Delete')),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: task.isOutOfStock,
                          activeColor: AppPalette.pharmacistPrimary,
                          visualDensity: VisualDensity.compact,
                          onChanged: (_) => onToggle(task),
                        ),
                        Text(
                          context.tr(ar: 'نفد', en: 'Out'),
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: AppFontSize.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _unitLabel(BuildContext context, String unit) {
    switch (unit) {
      case 'strip':
        return context.tr(ar: 'شريط', en: 'strip');
      case 'pack':
        return context.tr(ar: 'عبوة', en: 'pack');
      default:
        return context.tr(ar: 'علبة', en: 'box');
    }
  }
}
