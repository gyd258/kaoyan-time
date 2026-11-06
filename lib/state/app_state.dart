import 'package:flutter/foundation.dart';

import '../data/backup.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../utils/format.dart';

enum SummaryRange { today, week, month, all }

class AppState extends ChangeNotifier {
  final AppDatabase db;
  late final BackupService backup;

  AppState(this.db) {
    backup = BackupService(db);
  }

  List<Subject> subjects = [];
  List<TaskItem> allTasks = [];
  List<TimeEntry> dayEntries = [];
  List<NoteItem> notes = [];

  DateTime selectedDay = studyDayOf(DateTime.now());
  String? examDate;
  TimerSession? timer;

  Map<int, int> todayMinutes = {};
  Map<int, int> weekMinutes = {};
  Map<int, int> totalMinutes = {};
  int dayTotal = 0;
  int weekTotal = 0;

  SummaryRange range = SummaryRange.week;
  List<SubjectSummary> summary = [];
  int summaryTotal = 0;
  int summaryCount = 0;
  int summaryDays = 1;
  Map<String, int> last7 = {};
  Map<String, int> monthHeatmap = {};
  String? firstDay; // 最早一条记录的学习日

  int? noteFilterSubjectId;
  String noteQuery = '';

  bool loaded = false;

  Future<void> init() async {
    await _loadStructure();
    examDate = await db.getSetting('exam_date');
    timer = await db.loadTimer();
    selectedDay = studyDayOf(DateTime.now());
    await refreshDay();
    await refreshSummary();
    await loadNotes();
    loaded = true;
    notifyListeners();
  }

  Future<void> _loadStructure() async {
    subjects = await db.loadSubjects();
    allTasks = await db.loadTasks();
  }

  List<Subject> get activeSubjects => subjects.where((s) => !s.archived).toList();

  List<Subject> get archivedSubjects => subjects.where((s) => s.archived).toList();

  List<TaskItem> tasksOf(int subjectId) =>
      allTasks.where((t) => t.subjectId == subjectId && !t.archived).toList();

  Subject? subjectById(int id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  TaskItem? taskById(int? id) {
    if (id == null) return null;
    for (final t in allTasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// 某一天各科目学习分钟数（subjectId -> minutes）
  Future<Map<int, int>> subjectMinutesOfDay(String dayKey) async {
    return db.minutesBySubject(from: dayKey, to: dayKey);
  }

  int? get examDaysLeft {
    final raw = examDate;
    if (raw == null) return null;
    return daysBetween(DateTime.now(), parseDay(raw));
  }

  // ---------------- 今日 ----------------

  Future<void> refreshDay() async {
    final key = dayKey(selectedDay);
    dayEntries = await db.entriesOfDay(key);
    todayMinutes = await db.minutesBySubject(from: key, to: key);
    dayTotal = todayMinutes.values.fold(0, (a, b) => a + b);
    final ws = dayKey(weekStart(selectedDay));
    weekMinutes = await db.minutesBySubject(from: ws, to: key);
    weekTotal = weekMinutes.values.fold(0, (a, b) => a + b);
    totalMinutes = await db.minutesBySubject();
    notifyListeners();
  }

  Future<void> selectDay(DateTime day) async {
    final today = studyDayOf(DateTime.now());
    final target = dateOnly(day);
    selectedDay = target.isAfter(today) ? today : target;
    await refreshDay();
    await refreshSummary();
  }

  Future<void> addEntry({
    required int subjectId,
    int? taskId,
    required int minutes,
    DateTime? day,
    String source = 'manual',
    String? note,
    int? startedAt,
    int? endedAt,
  }) async {
    await db.insertEntry(EntryDraft(
      subjectId: subjectId,
      taskId: taskId,
      day: dayKey(day ?? selectedDay),
      minutes: minutes,
      source: source,
      note: _clean(note),
      startedAt: startedAt,
      endedAt: endedAt,
    ));
    await refreshDay();
    await refreshSummary();
  }

  Future<void> updateEntry(
    TimeEntry entry, {
    required int subjectId,
    int? taskId,
    required int minutes,
    required DateTime day,
    String? note,
  }) async {
    await db.updateEntry(
      entry.id,
      EntryDraft(
        subjectId: subjectId,
        taskId: taskId,
        day: dayKey(day),
        minutes: minutes,
        source: entry.source,
        note: _clean(note),
        startedAt: entry.startedAt,
        endedAt: entry.endedAt,
      ),
    );
    await refreshDay();
    await refreshSummary();
  }

  Future<void> deleteEntry(TimeEntry entry) async {
    await db.deleteEntry(entry.id);
    await refreshDay();
    await refreshSummary();
  }

  // ---------------- 科目与任务 ----------------

  Future<void> addSubject(String name, int color, int targetMinutes) async {
    await db.insertSubject(name.trim(), color, targetMinutes);
    await _reloadStructureAndData();
  }

  Future<void> saveSubject(Subject subject) async {
    await db.updateSubject(subject);
    await _reloadStructureAndData();
  }

  Future<void> deleteSubject(Subject subject) async {
    await db.deleteSubject(subject.id);
    await _reloadStructureAndData();
  }

  Future<void> addTask(int subjectId, String name) async {
    await db.insertTask(subjectId, name.trim());
    await _reloadStructureAndData();
  }

  Future<void> saveTask(TaskItem task) async {
    await db.updateTask(task);
    await _reloadStructureAndData();
  }

  Future<void> _reloadStructureAndData() async {
    await _loadStructure();
    await refreshDay();
    await refreshSummary();
    await loadNotes();
    notifyListeners();
  }

  // ---------------- 汇总 ----------------

  Future<void> setRange(SummaryRange value) async {
    range = value;
    await refreshSummary();
  }

  Future<void> refreshSummary() async {
    final today = dateOnly(selectedDay);
    final from = _rangeStart(today);
    final to = range == SummaryRange.all ? null : dayKey(today);
    final minutes = await db.minutesBySubject(from: from, to: to);
    if (totalMinutes.isEmpty && subjects.isNotEmpty) {
      totalMinutes = await db.minutesBySubject();
    }
    summary = [
      for (final s in subjects)
        SubjectSummary(
          subjectId: s.id,
          name: s.name,
          color: s.color,
          minutes: minutes[s.id] ?? 0,
          targetMinutes: s.targetMinutes,
          totalMinutes: totalMinutes[s.id] ?? 0,
        )
    ];
    summaryTotal = summary.fold(0, (a, b) => a + b.minutes);
    summaryCount = await db.countEntries(from: from, to: to);
    summaryDays = await _rangeDays(today, from);
    final start7 = today.subtract(const Duration(days: 6));
    final end7 = dayKey(today);
    final raw = await db.minutesByDay(from: dayKey(start7), to: end7);
    last7 = {
      for (var i = 0; i < 7; i++)
        dayKey(start7.add(Duration(days: i))): raw[dayKey(start7.add(Duration(days: i)))] ?? 0,
    };
    // 月度热力图（selectedDay 所在月）
    final mStart = monthStart(today);
    final mEndDay = DateTime(today.year, today.month + 1, 0).day;
    final mEnd = DateTime(today.year, today.month, mEndDay);
    monthHeatmap = await db.minutesByDay(from: dayKey(mStart), to: dayKey(mEnd));
    firstDay = await db.firstEntryDay();
    notifyListeners();
  }

  String? _rangeStart(DateTime today) {
    switch (range) {
      case SummaryRange.today:
        return dayKey(today);
      case SummaryRange.week:
        return dayKey(weekStart(today));
      case SummaryRange.month:
        return dayKey(monthStart(today));
      case SummaryRange.all:
        return null;
    }
  }

  Future<int> _rangeDays(DateTime today, String? from) async {
    if (range == SummaryRange.all) {
      final first = await db.firstEntryDay();
      if (first == null) return 1;
      final realToday = dateOnly(DateTime.now());
      final span = daysBetween(parseDay(first), realToday) + 1;
      return span < 1 ? 1 : span;
    }
    if (from == null) return 1;
    final d = daysBetween(parseDay(from), today) + 1;
    return d < 1 ? 1 : d;
  }

  // ---------------- 笔记 ----------------

  Future<void> loadNotes() async {
    notes = await db.loadNotes(subjectId: noteFilterSubjectId, keyword: noteQuery);
    notifyListeners();
  }

  Future<void> setNoteFilter(int? subjectId) async {
    noteFilterSubjectId = subjectId;
    await loadNotes();
  }

  Future<void> setNoteQuery(String q) async {
    noteQuery = q;
    await loadNotes();
  }

  Future<void> addNote(int subjectId, DateTime day, String content) async {
    await db.insertNote(dayKey(day), subjectId, content.trim());
    await loadNotes();
  }

  Future<void> saveNote(NoteItem item, int subjectId, DateTime day, String content) async {
    await db.updateNote(item.id, dayKey(day), subjectId, content.trim());
    await loadNotes();
  }

  Future<void> deleteNote(NoteItem item) async {
    await db.deleteNote(item.id);
    await loadNotes();
  }

  // ---------------- 设置 ----------------

  Future<void> setExamDate(DateTime? day) async {
    if (day == null) {
      await db.setSetting('exam_date', '');
      examDate = null;
    } else {
      final v = dayKey(dateOnly(day));
      await db.setSetting('exam_date', v);
      examDate = v;
    }
    notifyListeners();
  }

  // ---------------- 计时器 ----------------

  TimerSession? get runningTimer => timer;

  Future<void> startTimer({required int subjectId, int? taskId, String? note}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    timer = TimerSession(
      subjectId: subjectId,
      taskId: taskId,
      note: _clean(note),
      accumulatedMs: 0,
      segmentStartedAt: now,
      firstStartedAt: now,
      running: true,
    );
    await db.saveTimer(timer!);
    notifyListeners();
  }

  Future<void> pauseTimer() async {
    final t = timer;
    if (t == null) return;
    if (t.running) {
      t.accumulatedMs = t.elapsedMs();
      t.segmentStartedAt = null;
      t.running = false;
      await db.saveTimer(t);
    }
    notifyListeners();
  }

  Future<void> resumeTimer() async {
    final t = timer;
    if (t == null || t.running) return;
    t.segmentStartedAt = DateTime.now().millisecondsSinceEpoch;
    t.running = true;
    await db.saveTimer(t);
    notifyListeners();
  }

  Future<void> finishTimer() async {
    final t = timer;
    if (t == null) return;
    final totalMs = t.elapsedMs();
    final minutes = (totalMs / 60000).round().clamp(1, 1440);
    final firstStart = t.firstStartedAt ?? DateTime.now().millisecondsSinceEpoch;
    final end = DateTime.now().millisecondsSinceEpoch;
    final day = studyDayOf(DateTime.fromMillisecondsSinceEpoch(firstStart));
    await db.insertEntry(EntryDraft(
      subjectId: t.subjectId!,
      taskId: t.taskId,
      day: dayKey(day),
      minutes: minutes,
      source: 'timer',
      note: t.note,
      startedAt: firstStart,
      endedAt: end,
    ));
    timer = null;
    await db.clearTimer();
    await refreshDay();
    await refreshSummary();
    notifyListeners();
  }

  Future<void> discardTimer() async {
    timer = null;
    await db.clearTimer();
    notifyListeners();
  }

  bool get timerOverrun {
    final t = timer;
    if (t == null || !t.running || t.segmentStartedAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch - t.segmentStartedAt! >=
        const Duration(hours: 12).inMilliseconds;
  }

  Future<void> capTimerAtTwelveHours() async {
    final t = timer;
    if (t == null) return;
    t.accumulatedMs = const Duration(hours: 12).inMilliseconds;
    t.segmentStartedAt = null;
    t.running = false;
    await db.saveTimer(t);
    notifyListeners();
  }

  // ---------------- 数据 ----------------

  Future<String> exportCsv() => backup.exportCsv(subjects, allTasks);

  Future<String> exportJson() => backup.exportJson();

  Future<void> importJson(String content) async {
    await backup.importJson(content);
    await _reloadAll();
  }

  Future<void> clearAll() async {
    await db.clearAllData();
    await _reloadAll();
  }

  Future<void> _reloadAll() async {
    await _loadStructure();
    examDate = await db.getSetting('exam_date');
    if (examDate != null && examDate!.isEmpty) examDate = null;
    timer = await db.loadTimer();
    noteFilterSubjectId = null;
    noteQuery = '';
    await refreshDay();
    await refreshSummary();
    await loadNotes();
  }

  String? _clean(String? s) {
    final v = s?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
