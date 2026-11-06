import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subjects = state.summary.where((s) => s.minutes > 0).toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));
    final archived = state.summary
        .where((s) => s.minutes > 0 && (state.subjectById(s.subjectId)?.archived ?? false))
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));
    final active = subjects
        .where((s) => !(state.subjectById(s.subjectId)?.archived ?? false))
        .toList();

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (state.range != SummaryRange.week &&
              state.range != SummaryRange.month) {
            return;
          }
          final delta = details.primaryVelocity ?? 0;
          if (delta.abs() < 300) return;
          final forward = delta < 0; // 向左滑 → 往后
          _shiftRange(state, forward);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text('汇总',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor(context))),
                  const Spacer(),
                  Text(_rangeLabel(state),
                      style: TextStyle(fontSize: 12, color: subColor(context))),
                ],
              ),
            ),
            _segmented(state),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('总计时长',
                              style: TextStyle(fontSize: 11, color: subColor(context))),
                          const SizedBox(height: 3),
                          Text(
                            fmtDuration(state.summaryTotal),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: textColor(context),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (state.range != SummaryRange.today)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('日均', style: TextStyle(fontSize: 11, color: subColor(context))),
                            const SizedBox(height: 3),
                            Text(
                              fmtDuration((state.summaryTotal / state.summaryDays).round()),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor(context)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bars(state),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _heatmap(state),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('科目占比', style: TextStyle(fontSize: 12, color: subColor(context))),
                  const SizedBox(height: 10),
                  if (state.summaryTotal == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Center(
                        child: Text('暂无数据',
                            style: TextStyle(fontSize: 12, color: subColor(context))),
                      ),
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 118,
                          height: 118,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(118, 118),
                                painter: _DonutPainter(
                                  parts: [
                                    for (final s in subjects) (s.minutes, Color(s.color)),
                                  ],
                                  background: isDark(context)
                                      ? const Color(0xFF2A2F36)
                                      : const Color(0xFFEFF4F0),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('总计',
                                      style: TextStyle(fontSize: 10, color: subColor(context))),
                                  Text(
                                    fmtShort(state.summaryTotal),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor(context)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              for (final s in subjects.take(5))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () => _showSubjectDetail(state, s),
                                    child: Row(
                                      children: [
                                        Dot(Color(s.color), size: 7),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(s.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 12, color: textColor(context))),
                                        ),
                                        Text(fmtShort(s.minutes),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: textColor(context))),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (active.isNotEmpty) ...[
              SectionLabel('按科目'),
              _subjectList(state, active),
            ],
            if (archived.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _showArchived = !_showArchived),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                  child: Row(
                    children: [
                      Text('已归档（${archived.length}）',
                          style: TextStyle(fontSize: 12, color: subColor(context))),
                      Icon(
                        _showArchived ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: subColor(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showArchived) _subjectList(state, archived),
            ],
          ],
        ),
      ),
    );
  }

  void _shiftRange(AppState state, bool forward) {
    final cur = state.selectedDay;
    DateTime next;
    if (state.range == SummaryRange.week) {
      next = cur.add(Duration(days: forward ? 7 : -7));
    } else {
      // month
      if (forward) {
        next = DateTime(cur.year, cur.month + 1, cur.day);
      } else {
        next = DateTime(cur.year, cur.month - 1, cur.day);
      }
    }
    // 不超过今天
    final today = studyDayOf(DateTime.now());
    if (next.isAfter(today)) next = today;
    state.selectDay(next);
  }

  String _rangeLabel(AppState state) {
    final day = state.selectedDay;
    switch (state.range) {
      case SummaryRange.today:
        return fmtMd(day);
      case SummaryRange.week:
        return '${fmtMd(weekStart(day))} - ${fmtMd(day)}';
      case SummaryRange.month:
        return '${fmtMd(monthStart(day))} - ${fmtMd(day)}';
      case SummaryRange.all:
        return '全程';
    }
  }

  Widget _segmented(AppState state) {
    const labels = {
      SummaryRange.today: '今日',
      SummaryRange.week: '本周',
      SummaryRange.month: '本月',
      SummaryRange.all: '全程',
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1B1F24) : const Color(0xFFEAF0EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final r in SummaryRange.values)
            Expanded(
              child: GestureDetector(
                onTap: () => state.setRange(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: state.range == r ? cardBg(context) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: state.range == r
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[r]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: state.range == r ? FontWeight.w600 : FontWeight.normal,
                      color: state.range == r ? textColor(context) : subColor(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bars(AppState state) {
    final entries = state.last7.entries.toList();
    final maxValue = math.max(1, entries.fold<int>(0, (a, e) => math.max(a, e.value)));
    final todayKey = dayKey(state.selectedDay);

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => _showDayDetail(state, e.key),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        e.value == 0 ? '' : '${e.value}',
                        style: TextStyle(fontSize: 8, color: subColor(context)),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 4 + 74 * (e.value / maxValue),
                        decoration: BoxDecoration(
                          color: e.key == todayKey
                              ? Theme.of(context).colorScheme.primary
                              : (isDark(context)
                                  ? const Color(0xFF2C3A33)
                                  : const Color(0xFFDDF0E5)),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        e.key == todayKey ? '今天' : fmtWeekday(parseDay(e.key)),
                        style: TextStyle(fontSize: 9, color: subColor(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDayDetail(AppState state, String dayKey) async {
    final map = await state.subjectMinutesOfDay(dayKey);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (a, e) => a + e.value);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fmtDayCn(parseDay(dayKey)),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 260,
          child: entries.isEmpty
              ? Text('当天没有记录', style: TextStyle(fontSize: 13, color: subColor(ctx)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Dot(Color(state.subjectById(e.key)?.color ?? 0xFF23B574),
                                size: 8),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.subjectById(e.key)?.name ?? '未知科目',
                                style: TextStyle(fontSize: 13, color: textColor(ctx)),
                              ),
                            ),
                            Text(fmtDuration(e.value),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor(ctx))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Divider(height: 1, color: lineColor(ctx)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('合计',
                              style:
                                  TextStyle(fontSize: 12, color: subColor(ctx))),
                        ),
                        Text(fmtDuration(total),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textColor(ctx))),
                      ],
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('关闭', style: TextStyle(color: subColor(ctx))),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubjectDetail(AppState state, SubjectSummary s) async {
    final pct = state.summaryTotal == 0
        ? 0
        : (s.minutes * 100 / state.summaryTotal).round();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Dot(Color(s.color), size: 9),
            const SizedBox(width: 8),
            Text(s.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        content: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(ctx, '本范围时长', fmtDuration(s.minutes)),
              const SizedBox(height: 8),
              _detailRow(ctx, '占比', '$pct%'),
              const SizedBox(height: 8),
              _detailRow(
                  ctx,
                  '目标',
                  s.targetMinutes > 0
                      ? '${fmtDuration(s.targetMinutes)}（${fmtDuration(s.totalMinutes)}）'
                      : '未设置'),
              if (s.targetMinutes > 0) ...[
                const SizedBox(height: 10),
                ProgressBar(
                  value: s.targetMinutes > 0
                      ? s.totalMinutes / s.targetMinutes
                      : 0,
                  color: Color(s.color),
                ),
                const SizedBox(height: 4),
                Text(
                  s.totalMinutes >= s.targetMinutes
                      ? '已达成目标'
                      : '还差 ${fmtDuration(s.targetMinutes - s.totalMinutes)}',
                  style: TextStyle(fontSize: 11, color: subColor(ctx)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('关闭', style: TextStyle(color: subColor(ctx))),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext ctx, String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: subColor(ctx))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: textColor(ctx))),
      ],
    );
  }

  Widget _heatmap(AppState state) {
    final day = state.selectedDay;
    final year = day.year;
    final month = day.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = firstDay.weekday - 1; // 周一起
    final cells = <Widget>[];
    // 星期表头
    const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
    for (final w in weekLabels) {
      cells.add(Center(
        child: Text(w, style: TextStyle(fontSize: 10, color: subColor(context))),
      ));
    }
    // 前置空白
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    final todayKey = dayKey(studyDayOf(DateTime.now()));
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final key = dayKey(date);
      final minutes = state.monthHeatmap[key] ?? 0;
      final isToday = key == todayKey;
      cells.add(GestureDetector(
        onTap: () => _showDayDetail(state, key),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: _heatColor(minutes),
            borderRadius: BorderRadius.circular(5),
            border: isToday
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            minutes > 0 ? '$minutes' : '',
            style: TextStyle(
              fontSize: 8,
              color: minutes > 0 ? Colors.white : subColor(context),
              fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$year年$month月',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: textColor(context))),
              const Spacer(),
              Text('左右滑动切换月份',
                  style: TextStyle(fontSize: 10, color: subColor(context))),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
            children: cells,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('少', style: TextStyle(fontSize: 9, color: subColor(context))),
              const SizedBox(width: 4),
              for (final c in [
                _heatColor(0),
                _heatColor(15),
                _heatColor(45),
                _heatColor(90),
                _heatColor(150),
              ])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                ),
              Text('多', style: TextStyle(fontSize: 9, color: subColor(context))),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatColor(int minutes) {
    if (minutes <= 0) {
      return isDark(context) ? const Color(0xFF23282E) : const Color(0xFFEEF3F0);
    }
    final base = isDark(context);
    if (minutes <= 30) return base ? const Color(0xFF1E4D3A) : const Color(0xFFBFE6D2);
    if (minutes <= 60) return base ? const Color(0xFF237050) : const Color(0xFF7FD3A8);
    if (minutes <= 120) return base ? const Color(0xFF2B9968) : const Color(0xFF3FB97E);
    return base ? const Color(0xFF34C982) : const Color(0xFF23B574);
  }

  Widget _subjectList(AppState state, List<SubjectSummary> items) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Dot(Color(items[i].color), size: 7),
                            const SizedBox(width: 6),
                            Text(items[i].name,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textColor(context))),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ProgressBar(
                          value: items[i].targetMinutes > 0
                              ? items[i].totalMinutes / items[i].targetMinutes
                              : 0,
                          color: Color(items[i].color),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmtShort(items[i].minutes),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor(context))),
                      const SizedBox(height: 3),
                      Text(
                        state.summaryTotal == 0
                            ? '0%'
                            : '${(items[i].minutes * 100 / state.summaryTotal).round()}%',
                        style: TextStyle(fontSize: 10, color: subColor(context)),
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
}

class _DonutPainter extends CustomPainter {
  final List<(int, Color)> parts;
  final Color background;

  _DonutPainter({required this.parts, required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;
    paint.color = background;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);

    final total = parts.fold<int>(0, (a, p) => a + p.$1);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final p in parts) {
      if (p.$1 <= 0) continue;
      final sweep = math.pi * 2 * p.$1 / total;
      paint.color = p.$2;
      canvas.drawArc(rect, start, sweep - 0.015, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
