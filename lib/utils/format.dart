const _cnWeek = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 学习日：凌晨 4 点分界
DateTime studyDayOf(DateTime t) {
  final d = DateTime(t.year, t.month, t.day);
  return t.hour < 4 ? d.subtract(const Duration(days: 1)) : d;
}

DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDay(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String fmtDayCn(DateTime d) => '${d.month}月${d.day}日 ${_cnWeek[d.weekday - 1]}';

String fmtMd(DateTime d) => '${d.month}月${d.day}日';

String fmtClock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String fmtDuration(int minutes) {
  if (minutes <= 0) return '0 分';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m 分';
  if (m == 0) return '$h 小时';
  return '$h 小时 $m 分';
}

String fmtShort(int minutes) {
  if (minutes <= 0) return '0分';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m分';
  if (m == 0) return '$h时';
  return '$h时$m分';
}

String fmtTimer(int ms) {
  final total = ms ~/ 1000;
  final h = (total ~/ 3600).toString().padLeft(2, '0');
  final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// 周一为起点
DateTime weekStart(DateTime d) {
  final base = dateOnly(d);
  return base.subtract(Duration(days: base.weekday - 1));
}

DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

int daysBetween(DateTime a, DateTime b) => dateOnly(b).difference(dateOnly(a)).inDays;

String fmtDateTime(DateTime t) =>
    '${dayKey(t)} ${fmtClock(t)}';
