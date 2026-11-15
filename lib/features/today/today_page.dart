import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../settings/subject_manage_page.dart';
import '../timer/timer_page.dart';
import 'entry_sheet.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = context.read<AppState>();
      if (state.timer != null && state.timer!.running) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverrun());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOverrun();
      setState(() {});
    }
  }

  Future<void> _checkOverrun() async {
    if (!mounted) return;
    final state = context.read<AppState>();
    if (!state.timerOverrun) return;
    final keep = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('计时超过 12 小时',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          '这次计时已经超过 12 小时，可能是忘记结束了。保留只记为 12 小时，丢弃则本次不计入。',
          style: TextStyle(fontSize: 13, color: subColor(ctx), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('丢弃', style: TextStyle(fontSize: 13, color: AppColors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保留 12 小时',
                style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (keep == null) return;
    if (keep) {
      await state.capTimerAtTwelveHours();
    } else {
      await state.discardTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = studyDayOf(DateTime.now());
    final subjects = state.activeSubjects;
    final todays = subjects.where((s) => (state.todayMinutes[s.id] ?? 0) > 0).toList();

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, state.timer != null ? 160 : 96),
            children: [
              _header(state, today),
              _countdown(state),
              _totalBlock(state),
              if (subjects.isEmpty)
                AppCard(
                  child: EmptyState(
                    text: '还没有科目',
                    actionText: '新建科目',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubjectManagePage()),
                    ),
                  ),
                )
              else if (todays.isEmpty)
                AppCard(
                  child: EmptyState(
                    text: '今天还没有学习记录',
                    actionText: '开始记录',
                    onAction: () => showEntrySheet(context),
                  ),
                )
              else
                for (final s in todays)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _subjectCard(state, s),
                  ),
              const SectionLabel('今日记录'),
              if (state.dayEntries.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        subjects.isEmpty ? '先建科目，再记录时间' : '今天还没有记录',
                        style: TextStyle(fontSize: 13, color: subColor(context)),
                      ),
                    ),
                  ),
                )
              else
                _entriesCard(state),
            ],
          ),
          if (state.timer != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: _timerBar(state),
            ),
          Positioned(
            right: 18,
            bottom: state.timer != null ? 96 : 20,
            child: _fab(state),
          ),
        ],
      ),
    );
  }

  Widget _header(AppState state, DateTime today) {
    final canNext = state.selectedDay.isBefore(today);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => state.selectDay(
                state.selectedDay.subtract(const Duration(days: 1))),
            icon: Icon(Icons.chevron_left, color: subColor(context), size: 22),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final today = studyDayOf(DateTime.now());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDay.isAfter(today)
                      ? today
                      : state.selectedDay,
                  firstDate: DateTime(2020),
                  lastDate: today,
                  helpText: '选择学习日',
                );
                if (picked != null) {
                  state.selectDay(dateOnly(picked));
                }
              },
              child: Center(
                child: Text(
                  fmtDayCn(state.selectedDay),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor(context),
                  ),
                ),
              ),
            ),
          ),
          if (canNext)
            IconButton(
              onPressed: () => state.selectDay(
                  state.selectedDay.add(const Duration(days: 1))),
              icon: Icon(Icons.chevron_right, color: subColor(context), size: 22),
              visualDensity: VisualDensity.compact,
            )
          else
            TextButton(
              onPressed: state.selectedDay == today ? null : () => state.selectDay(today),
              child: Text(
                state.selectedDay == today ? '今天' : '回到今天',
                style: TextStyle(fontSize: 12, color: subColor(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _countdown(AppState state) {
    final days = state.examDaysLeft;
    return GestureDetector(
      onTap: () => pickExamDate(context, state),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mintBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark(context) ? const Color(0xFF24503C) : const Color(0xFFD5F0E2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              days == null ? '设置考试日期' : '距考试还有',
              style: TextStyle(
                fontSize: 12,
                color: isDark(context) ? const Color(0xFF7FDDB0) : AppColors.primaryInk,
              ),
            ),
            Text(
              days == null ? '去设置' : '$days 天',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark(context) ? const Color(0xFF7FDDB0) : AppColors.primaryInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBlock(AppState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 16),
      child: Column(
        children: [
          Text(
            fmtDuration(state.dayTotal),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${state.dayEntries.length} 条记录',
            style: TextStyle(fontSize: 12, color: subColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(AppState state, Subject s) {
    final color = Color(s.color);
    final minutes = state.todayMinutes[s.id] ?? 0;
    final week = state.weekMinutes[s.id] ?? 0;
    final total = state.totalMinutes[s.id] ?? 0;
    final target = s.targetMinutes;
    final ratio = target > 0 ? total / target : 0.0;
    final pct = (ratio * 100).clamp(0, 999).toStringAsFixed(0);

    return AppCard(
      onTap: () => showEntrySheet(context, presetSubjectId: s.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Dot(color),
              const SizedBox(width: 7),
              Text(
                s.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor(context),
                ),
              ),
              const Spacer(),
              Text(
                fmtDuration(minutes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ProgressBar(value: ratio, color: color),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周 ${fmtDuration(week)}',
                style: TextStyle(fontSize: 10, color: subColor(context)),
              ),
              Text(
                target > 0 ? '目标 ${fmtShort(target)} · $pct%' : '未设目标',
                style: TextStyle(fontSize: 10, color: subColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entriesCard(AppState state) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < state.dayEntries.length; i++)
            _entryRow(state, state.dayEntries[i],
                last: i == state.dayEntries.length - 1),
        ],
      ),
    );
  }

  Widget _entryRow(AppState state, TimeEntry e, {required bool last}) {
    final subject = state.subjectById(e.subjectId);
    final task = state.taskById(e.taskId);
    final time = e.startedAt != null
        ? fmtClock(DateTime.fromMillisecondsSinceEpoch(e.startedAt!))
        : '';
    final title = task != null ? '${subject?.name ?? ''} · ${task.name}' : (subject?.name ?? '已删除科目');

    return Dismissible(
      key: ValueKey('entry-${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) async {
        return confirmAction(
          context,
          title: '删除这条记录？',
          message: '${fmtDuration(e.minutes)} 将从 ${e.day} 的学习时间中扣除。',
          confirmText: '删除',
          danger: true,
        );
      },
      onDismissed: (_) => state.deleteEntry(e),
      child: InkWell(
        onTap: () => showEntrySheet(context, entry: e),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: lineColor(context))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  time,
                  style: TextStyle(fontSize: 11, color: subColor(context)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (subject != null) ...[
                          Dot(Color(subject.color), size: 6),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor(context),
                            ),
                          ),
                        ),
                        if (e.source == 'timer') ...[
                          const SizedBox(width: 5),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: mintBg(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '计时',
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (e.note != null && e.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          e.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: subColor(context)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.minutes} 分',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timerBar(AppState state) {
    final t = state.timer!;
    final subject = state.subjectById(t.subjectId ?? -1);
    final task = state.taskById(t.taskId);
    final label = [
      if (subject != null) subject.name,
      if (task != null) task.name,
    ].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TimerPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF17251D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${t.running ? '计时中' : '已暂停'} · $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB9C8BF)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmtTimer(t.elapsedMs()),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _smallButton(
              t.running ? '暂停' : '继续',
              () => t.running ? state.pauseTimer() : state.resumeTimer(),
            ),
            const SizedBox(width: 8),
            _smallButton(
              '结束',
              () async {
                final ok = await confirmAction(
                  context,
                  title: '结束计时？',
                  message: '将按已计时长生成一条记录。',
                  confirmText: '结束',
                );
                if (ok) await state.finishTimer();
              },
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: danger ? AppColors.red : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ),
    );
  }

  Widget _fab(AppState state) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (state.activeSubjects.isEmpty) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SubjectManagePage()));
            return;
          }
          showEntrySheet(context);
        },
        onLongPress: () {
          if (state.activeSubjects.isEmpty) return;
          showTimerStartSheet(context);
        },
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

Future<void> pickExamDate(BuildContext context, AppState state) async {
  final now = DateTime.now();
  final initial = state.examDate != null ? parseDay(state.examDate!) : DateTime(now.year, 12, 20);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035, 12, 31),
    helpText: '选择考试日期',
  );
  if (picked != null) {
    await state.setExamDate(picked);
  }
}
