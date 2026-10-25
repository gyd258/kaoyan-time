import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class TaskManagePage extends StatefulWidget {
  const TaskManagePage({super.key});

  @override
  State<TaskManagePage> createState() => _TaskManagePageState();
}

class _TaskManagePageState extends State<TaskManagePage> {
  int? _subjectId;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final list = state.activeSubjects;
    _subjectId = list.isNotEmpty ? list.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subjects = state.activeSubjects;
    final tasks =
        _subjectId == null ? <TaskItem>[] : state.tasksOf(_subjectId!).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('任务管理',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor(context))),
        iconTheme: IconThemeData(color: textColor(context)),
        actions: [
          IconButton(
            onPressed: _subjectId == null
                ? null
                : () => _editTask(context, state, subjectId: _subjectId!),
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final s in subjects)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _subjectId = s.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _subjectId == s.id
                              ? mintBg(context)
                              : (isDark(context)
                                  ? const Color(0xFF1E2228)
                                  : const Color(0xFFF5F8F6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Dot(Color(s.color), size: 7),
                            const SizedBox(width: 5),
                            Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    _subjectId == s.id ? FontWeight.w600 : FontWeight.normal,
                                color: _subjectId == s.id
                                    ? Theme.of(context).colorScheme.primary
                                    : subColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                if (subjects.isEmpty)
                  const EmptyState(text: '请先新建科目')
                else if (tasks.isEmpty)
                  const EmptyState(text: '这个科目还没有任务，点右上角添加')
                else
                  for (final t in tasks) _taskRow(context, state, t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskRow(BuildContext context, AppState state, TaskItem t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => _editTask(context, state, subjectId: t.subjectId, task: t),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t.name,
                style: TextStyle(fontSize: 14, color: textColor(context)),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, size: 20, color: subColor(context)),
              color: cardBg(context),
              onSelected: (v) async {
                if (v == 'edit') {
                  _editTask(context, state, subjectId: t.subjectId, task: t);
                } else {
                  await state.saveTask(TaskItem(
                    id: t.id,
                    subjectId: t.subjectId,
                    name: t.name,
                    archived: !t.archived,
                    sortOrder: t.sortOrder,
                  ));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('重命名', style: TextStyle(fontSize: 13))),
                PopupMenuItem(value: 'archive', child: Text('归档', style: TextStyle(fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTask(
    BuildContext context,
    AppState state, {
    required int subjectId,
    TaskItem? task,
  }) async {
    final ctrl = TextEditingController(text: task?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(task == null ? '新建任务' : '重命名任务',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(hintText: '任务名，如 张宇1000题'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(fontSize: 13, color: subColor(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存', style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) {
      if (context.mounted) showToast(context, '任务名不能为空');
      return;
    }
    if (task == null) {
      await state.addTask(subjectId, name);
    } else {
      await state.saveTask(TaskItem(
        id: task.id,
        subjectId: task.subjectId,
        name: name,
        archived: task.archived,
        sortOrder: task.sortOrder,
      ));
    }
  }
}
