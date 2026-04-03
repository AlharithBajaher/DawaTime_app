import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/models/pharmacy_task_model.dart';
import '../../data/services/pharmacy_service.dart';

part 'pharmacist_home_sections.dart';
part 'pharmacist_home_editor.dart';

class PharmacistHome extends StatefulWidget {
  const PharmacistHome({super.key});

  @override
  State<PharmacistHome> createState() => _PharmacistHomeState();
}

class _PharmacistHomeState extends State<PharmacistHome> {
  final PharmacyService _pharmacyService = PharmacyService();

  int _selectedIndex = 0;
  bool _isSaving = false;
  bool _hasWelcomedUser = false;

  void _showWelcomeMessage(String email) {
    if (_hasWelcomedUser) {
      return;
    }

    _hasWelcomedUser = true;
    final userName = email.split('@').first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'مرحباً بعودتك، $userName',
              en: 'Welcome back, $userName',
            ),
          ),
        ),
      );
    });
  }

  Future<void> _openTaskEditor([PharmacyTaskModel? task]) async {
    final draft = await showModalBottomSheet<_TaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TaskEditorSheet(existing: task),
    );

    if (draft == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (task == null) {
        await _pharmacyService.addTask(
          title: draft.title,
          details: draft.details,
          category: draft.category,
          priority: draft.priority,
        );
      } else {
        await _pharmacyService.updateTask(
          taskId: task.id,
          title: draft.title,
          details: draft.details,
          category: draft.category,
          priority: draft.priority,
          isCompleted: task.isCompleted,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حفظ المهمة: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteTask(PharmacyTaskModel task) async {
    try {
      await _pharmacyService.deleteTask(task.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حذف المهمة: $error')));
    }
  }

  Widget _buildPage(
    List<PharmacyTaskModel> tasks,
    int active,
    int urgent,
    int completed,
    String email,
  ) {
    final pages = [
      _PharmacistOverviewTab(
        active: active,
        urgent: urgent,
        completed: completed,
        tasks: tasks,
        onCreateTask: () {
          _openTaskEditor();
        },
      ),
      _WorkflowTab(
        tasks: tasks,
        onToggle: _pharmacyService.toggleTask,
        onEdit: _openTaskEditor,
        onDelete: _deleteTask,
      ),
      _InsightsTab(tasks: tasks),
      _PharmacistAccountTab(
        email: email,
        onSignOut: () {
          FirebaseAuth.instance.signOut();
        },
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: KeyedSubtree(
        key: ValueKey(_selectedIndex),
        child: pages[_selectedIndex],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'pharmacist@dawatime.app';

    _showWelcomeMessage(email);

    return StreamBuilder<List<PharmacyTaskModel>>(
      stream: _pharmacyService.watchTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const <PharmacyTaskModel>[];
        final active = tasks.where((task) => !task.isCompleted).length;
        final urgent = tasks
            .where((task) => task.priority == 'high' && !task.isCompleted)
            .length;
        final completed = tasks.where((task) => task.isCompleted).length;

        return Scaffold(
          extendBody: true,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppPalette.pharmacistPrimary,
            foregroundColor: Colors.white,
            onPressed: _isSaving
                ? null
                : () {
                    _openTaskEditor();
                  },
            icon: const Icon(Icons.playlist_add_rounded),
            label: Text(
              _isSaving
                  ? context.t(AppText.saving)
                  : context.t(AppText.newTask),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppLayout.bottomNavInset,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard_rounded),
                    label: context.t(AppText.dashboard),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.fact_check_outlined),
                    selectedIcon: const Icon(Icons.fact_check_rounded),
                    label: context.t(AppText.tasks),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.insights_outlined),
                    selectedIcon: const Icon(Icons.insights_rounded),
                    label: context.t(AppText.insights),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: context.t(AppText.account),
                  ),
                ],
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5FBFA), Color(0xFFE3F5F1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: snapshot.hasError
                  ? const Center(
                      child: Text('تعذر تحميل مهام الصيدلية حالياً.'),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.maxContentWidth,
                        ),
                        child: _buildPage(
                          tasks,
                          active,
                          urgent,
                          completed,
                          email,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
