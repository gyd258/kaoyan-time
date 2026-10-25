import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = <String, List<NoteItem>>{};
    for (final n in state.notes) {
      groups.putIfAbsent(n.day, () => []).add(n);
    }
    final subjects = state.activeSubjects.isEmpty && state.subjects.isEmpty
        ? <Subject>[]
        : state.subjects;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text('笔记',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor(context))),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (state.subjects.isEmpty) {
                      showToast(context, '请先在设置里建科目');
                      return;
                    }
                    showNoteSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: mintBg(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '＋ 写一条',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _searchCtrl,
            onChanged: state.setNoteQuery,
            style: TextStyle(fontSize: 13, color: textColor(context)),
            decoration: InputDecoration(
              hintText: '搜索关键词',
              hintStyle: TextStyle(fontSize: 12, color: subColor(context)),
              prefixIcon: Icon(Icons.search, size: 18, color: subColor(context)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  context,
                  label: '全部',
                  selected: state.noteFilterSubjectId == null,
                  color: null,
                  onTap: () => state.setNoteFilter(null),
                ),
                for (final s in subjects)
                  _filterChip(
                    context,
                    label: s.name,
                    selected: state.noteFilterSubjectId == s.id,
                    color: Color(s.color),
                    onTap: () => state.setNoteFilter(s.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  state.noteQuery.isNotEmpty ? '没有匹配的笔记' : '还没有笔记，写一条试试',
                  style: TextStyle(fontSize: 13, color: subColor(context)),
                ),
              ),
            )
          else
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
                child: Row(
                  children: [
                    Text(fmtDayCn(parseDay(entry.key)),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor(context))),
                    const Spacer(),
                    Text('${entry.value.length} 条',
                        style: TextStyle(fontSize: 10, color: subColor(context))),
                  ],
                ),
              ),
              for (final n in entry.value)
                _noteCard(state, n),
            ],
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? mintBg(context)
                : (isDark(context) ? const Color(0xFF1E2228) : const Color(0xFFF5F8F6)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Dot(color, size: 6),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : subColor(context),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteCard(AppState state, NoteItem n) {
    final subject = state.subjectById(n.subjectId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        onTap: () => showNoteSheet(context, note: n),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (subject != null) ...[
                  Dot(Color(subject.color), size: 7),
                  const SizedBox(width: 6),
                ],
                Text(subject?.name ?? '已删除科目',
                    style: TextStyle(fontSize: 11, color: subColor(context))),
                const Spacer(),
                Text(fmtClock(DateTime.fromMillisecondsSinceEpoch(n.createdAt)),
                    style: TextStyle(fontSize: 10, color: subColor(context))),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              n.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, height: 1.6, color: textColor(context)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showNoteSheet(BuildContext context, {NoteItem? note}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: NoteSheet(note: note),
    ),
  );
}

class NoteSheet extends StatefulWidget {
  final NoteItem? note;
  const NoteSheet({super.key, this.note});

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  final _ctrl = TextEditingController();
  int? _subjectId;
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _day = widget.note != null ? parseDay(widget.note!.day) : state.selectedDay;
    _subjectId = widget.note?.subjectId ??
        (state.activeSubjects.isNotEmpty ? state.activeSubjects.first.id : null);
    if (widget.note != null) _ctrl.text = widget.note!.content;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = studyDayOf(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isAfter(today) ? today : _day,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: '选择学习日',
    );
    if (picked != null) setState(() => _day = dateOnly(picked));
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    if (_subjectId == null) {
      showToast(context, '请选择科目');
      return;
    }
    if (_ctrl.text.trim().isEmpty) {
      showToast(context, '内容不能为空');
      return;
    }
    if (widget.note != null) {
      await state.saveNote(widget.note!, _subjectId!, _day, _ctrl.text);
    } else {
      await state.addNote(_subjectId!, _day, _ctrl.text);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final ok = await confirmAction(
      context,
      title: '删除这条笔记？',
      message: '删除后无法恢复。',
      confirmText: '删除',
      danger: true,
    );
    if (!ok) return;
    await state.deleteNote(widget.note!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subjects = state.activeSubjects;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark(context) ? const Color(0xFF3A4048) : const Color(0xFFE4EAE6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(widget.note == null ? '写一条笔记' : '编辑笔记',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor(context))),
                const Spacer(),
                if (widget.note != null)
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in subjects)
                  GestureDetector(
                    onTap: () => setState(() => _subjectId = s.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDay,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark(context) ? const Color(0xFF1E2228) : const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lineColor(context)),
                ),
                child: Row(
                  children: [
                    Text(fmtDayCn(_day),
                        style: TextStyle(fontSize: 13, color: textColor(context))),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: subColor(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              minLines: 4,
              maxLength: 1000,
              style: TextStyle(fontSize: 13, height: 1.6, color: textColor(context)),
              decoration: const InputDecoration(
                hintText: '记录今天的学习方法、状态、调整思路……不写具体知识点',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(widget.note == null ? '保存' : '保存修改',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
