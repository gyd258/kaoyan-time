import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../timer/timer_page.dart';

Future<void> showEntrySheet(
  BuildContext context, {
  TimeEntry? entry,
  int? presetSubjectId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: EntrySheet(entry: entry, presetSubjectId: presetSubjectId),
    ),
  );
}

class EntrySheet extends StatefulWidget {
  final TimeEntry? entry;
  final int? presetSubjectId;

  const EntrySheet({super.key, this.entry, this.presetSubjectId});

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  final _minutesCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int? _subjectId;
  int? _taskId;
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _day = widget.entry != null ? parseDay(widget.entry!.day) : state.selectedDay;
    _subjectId = widget.entry?.subjectId ??
        widget.presetSubjectId ??
        (state.activeSubjects.isNotEmpty ? state.activeSubjects.first.id : null);
    _taskId = widget.entry?.taskId;
    if (widget.entry != null) {
      _minutesCtrl.text = widget.entry!.minutes.toString();
      _noteCtrl.text = widget.entry!.note ?? '';
    }
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _quickAdd(int add) {
    final current = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
    final next = current + add;
    _minutesCtrl.text = next.toString();
    setState(() {});
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final minutes = int.tryParse(_minutesCtrl.text.trim());
    if (_subjectId == null) {
      showToast(context, '请先选择科目');
      return;
    }
    if (minutes == null || minutes < 1 || minutes > 1440) {
      showToast(context, '时长需在 1 到 1440 分钟之间');
      return;
    }
    if (widget.entry != null) {
      await state.updateEntry(
        widget.entry!,
        subjectId: _subjectId!,
        taskId: _taskId,
        minutes: minutes,
        day: _day,
        note: _noteCtrl.text,
      );
    } else {
      await state.addEntry(
        subjectId: _subjectId!,
        taskId: _taskId,
        minutes: minutes,
        day: _day,
        note: _noteCtrl.text,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final ok = await confirmAction(
      context,
      title: '删除这条记录？',
      message: '${fmtDuration(widget.entry!.minutes)} 将从当日学习中扣除。',
      confirmText: '删除',
      danger: true,
    );
    if (!ok) return;
    await state.deleteEntry(widget.entry!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _startTimer() async {
    final state = context.read<AppState>();
    if (_subjectId == null) {
      showToast(context, '请先选择科目');
      return;
    }
    if (state.timer != null) {
      showToast(context, '已有计时在进行，先去结束它');
      return;
    }
    await state.startTimer(
      subjectId: _subjectId!,
      taskId: _taskId,
      note: _noteCtrl.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerPage()));
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subjects = state.activeSubjects;
    final current = state.subjectById(_subjectId ?? -1);
    final shownSubjects = [
      ...subjects,
      if (current != null && current.archived) current,
    ];
    final minutes = int.tryParse(_minutesCtrl.text.trim()) ?? 0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                Text(
                  widget.entry == null ? '记录学习时间' : '编辑记录',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor(context),
                  ),
                ),
                const Spacer(),
                if (widget.entry == null)
                  TextButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.timer_outlined, size: 16),
                    label: const Text('改为计时', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (widget.entry != null)
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _label('科目'),
            if (shownSubjects.isEmpty)
              Text('还没有科目，请先到「设置 - 科目管理」新建',
                  style: TextStyle(fontSize: 12, color: subColor(context)))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in shownSubjects)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _subjectId = s.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: _subjectId == s.id
                              ? mintBg(context)
                              : (isDark(context)
                                  ? const Color(0xFF1E2228)
                                  : const Color(0xFFF5F8F6)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _subjectId == s.id
                                ? (isDark(context)
                                    ? const Color(0xFF2B5B44)
                                    : const Color(0xFFCFEEDF))
                                : Colors.transparent,
                          ),
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
                                    ? (isDark(context)
                                        ? const Color(0xFF7FDDB0)
                                        : AppColors.primaryInk)
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
            _label('时长'),
            Row(
              children: [
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _minutesCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor(context),
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                for (final add in [15, 30, 60]) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _quickAdd(add),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark(context)
                              ? const Color(0xFF1E2228)
                              : const Color(0xFFF2F7F4),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '+$add',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark(context)
                                ? const Color(0xFF7FDDB0)
                                : AppColors.primaryInk,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 14),
            _label('学习日'),
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
                    Text(
                      _day == studyDayOf(DateTime.now())
                          ? '今天 · ${fmtDayCn(_day)}'
                          : fmtDayCn(_day),
                      style: TextStyle(fontSize: 13, color: textColor(context)),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: subColor(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label('备注（可选）'),
            TextField(
              controller: _noteCtrl,
              maxLength: 200,
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: textColor(context)),
              decoration: const InputDecoration(
                hintText: '例如：做完第 3 章',
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: minutes >= 1 && _subjectId != null ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.entry == null ? '保存' : '保存修改',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text, style: TextStyle(fontSize: 12, color: subColor(context))),
      );
}

Future<void> showTimerStartSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: const TimerStartSheet(),
    ),
  );
}

class TimerStartSheet extends StatefulWidget {
  const TimerStartSheet({super.key});

  @override
  State<TimerStartSheet> createState() => _TimerStartSheetState();
}

class _TimerStartSheetState extends State<TimerStartSheet> {
  final _noteCtrl = TextEditingController();
  int? _subjectId;
  int? _taskId;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _subjectId = state.activeSubjects.isNotEmpty ? state.activeSubjects.first.id : null;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final state = context.read<AppState>();
    if (_subjectId == null) return;
    if (state.timer != null) {
      showToast(context, '已有计时在进行');
      return;
    }
    await state.startTimer(
      subjectId: _subjectId!,
      taskId: _taskId,
      note: _noteCtrl.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerPage()));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subjects = state.activeSubjects;

    return Container(
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
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
          Text('开始计时',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: textColor(context))),
          const SizedBox(height: 12),
          Text('科目', style: TextStyle(fontSize: 12, color: subColor(context))),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subjects)
                GestureDetector(
                  onTap: () => setState(() {
                    _subjectId = s.id;
                  }),
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
                            fontWeight: _subjectId == s.id
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _subjectId == s.id
                                ? (isDark(context)
                                    ? const Color(0xFF7FDDB0)
                                    : AppColors.primaryInk)
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
          Text('备注（可选）', style: TextStyle(fontSize: 12, color: subColor(context))),
          const SizedBox(height: 7),
          TextField(
            controller: _noteCtrl,
            maxLength: 200,
            maxLines: 1,
            style: TextStyle(fontSize: 13, color: textColor(context)),
            decoration: const InputDecoration(hintText: '这一段时间要做什么', counterText: ''),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton(
              onPressed: _subjectId == null ? null : _start,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('开始',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
