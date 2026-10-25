import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class SubjectManagePage extends StatelessWidget {
  const SubjectManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.subjects.where((s) => !s.archived).toList();
    final archived = state.subjects.where((s) => s.archived).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('科目管理',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor(context))),
        iconTheme: IconThemeData(color: textColor(context)),
        actions: [
          IconButton(
            onPressed: () => _editSubject(context, state),
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (active.isEmpty && archived.isEmpty)
            const EmptyState(text: '还没有科目，点右上角添加'),
          for (final s in active) _subjectRow(context, state, s),
          if (archived.isNotEmpty) ...[
            const SectionLabel('已归档'),
            for (final s in archived) _subjectRow(context, state, s),
          ],
        ],
      ),
    );
  }

  Widget _subjectRow(BuildContext context, AppState state, Subject s) {
    final total = state.totalMinutes[s.id] ?? 0;
    final target = s.targetMinutes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => _editSubject(context, state, subject: s),
        child: Row(
          children: [
            Dot(Color(s.color), size: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    target > 0
                        ? '目标 ${fmtShort(target)} · 已累计 ${fmtShort(total)}'
                        : '未设目标 · 已累计 ${fmtShort(total)}',
                    style: TextStyle(fontSize: 10, color: subColor(context)),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, size: 20, color: subColor(context)),
              color: cardBg(context),
              onSelected: (v) async {
                if (v == 'edit') {
                  _editSubject(context, state, subject: s);
                } else if (v == 'archive') {
                  await state.saveSubject(s.copyWith(archived: !s.archived));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('编辑', style: TextStyle(fontSize: 13))),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(s.archived ? '恢复' : '归档',
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSubject(BuildContext context, AppState state, {Subject? subject}) async {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final targetCtrl = TextEditingController(
      text: subject != null && subject.targetMinutes > 0
          ? (subject.targetMinutes % 60 == 0
              ? '${subject.targetMinutes ~/ 60}'
              : (subject.targetMinutes / 60).toStringAsFixed(1))
          : '',
    );
    var color = subject != null
        ? Color(subject.color)
        : kSubjectPalette[state.subjects.length % kSubjectPalette.length];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(subject == null ? '新建科目' : '编辑科目',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(hintText: '科目名，如 数学'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '目标小时数，留空表示不设目标',
                    suffixText: '小时',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in kSubjectPalette)
                      GestureDetector(
                        onTap: () => setDlg(() => color = c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: color == c
                                ? Border.all(color: textColor(context), width: 2)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
      ),
    );

    if (saved != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      if (context.mounted) showToast(context, '科目名不能为空');
      return;
    }
    final hours = int.tryParse(targetCtrl.text.trim()) ?? 0;
    final targetMinutes = hours > 0 ? hours * 60 : 0;
    if (subject == null) {
      await state.addSubject(name, color.toARGB32(), targetMinutes);
    } else {
      await state.saveSubject(subject.copyWith(
        name: name,
        color: color.toARGB32(),
        targetMinutes: targetMinutes,
      ));
    }
  }
}
