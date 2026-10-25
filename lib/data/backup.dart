import 'dart:convert';

import 'db.dart';
import 'models.dart';
import '../utils/format.dart';

class BackupService {
  final AppDatabase db;

  BackupService(this.db);

  String _csvCell(String? v) {
    final s = v ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<String> exportCsv(List<Subject> subjects, List<TaskItem> tasks) async {
    final subjectMap = {for (final s in subjects) s.id: s.name};
    final taskMap = {for (final t in tasks) t.id: t.name};
    final entries = await db.allEntries();
    final buf = StringBuffer();
    buf.write('学习日,科目,任务,分钟,来源,备注,创建时间\r\n');
    for (final e in entries) {
      buf.write([
        _csvCell(e.day),
        _csvCell(subjectMap[e.subjectId] ?? ''),
        _csvCell(e.taskId == null ? '' : taskMap[e.taskId]),
        e.minutes.toString(),
        _csvCell(e.source == 'timer' ? '计时' : '手动'),
        _csvCell(e.note),
        _csvCell(fmtDateTime(
            DateTime.fromMillisecondsSinceEpoch(e.createdAt))),
      ].join(','));
      buf.write('\r\n');
    }
    return buf.toString();
  }

  Future<String> exportJson() async {
    final data = await db.exportAll();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importJson(String content) async {
    final parsed = jsonDecode(content);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('备份文件格式不正确');
    }
    if (parsed['app'] != 'yanshi') {
      throw const FormatException('不是研时的备份文件');
    }
    if ((parsed['schemaVersion'] as num?)?.toInt() != 1) {
      throw const FormatException('备份版本不兼容');
    }
    await db.importAll(parsed);
  }
}

String timestampName(DateTime t) {
  final d = dayKey(t).replaceAll('-', '');
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${d}_$hh$mm';
}
