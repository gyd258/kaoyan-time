class Subject {
  final int id;
  final String name;
  final int color;
  final int targetMinutes;
  final bool archived;
  final int sortOrder;

  const Subject({
    required this.id,
    required this.name,
    required this.color,
    required this.targetMinutes,
    required this.archived,
    required this.sortOrder,
  });

  Subject copyWith({
    String? name,
    int? color,
    int? targetMinutes,
    bool? archived,
    int? sortOrder,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TaskItem {
  final int id;
  final int subjectId;
  final String name;
  final bool archived;
  final int sortOrder;

  const TaskItem({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.archived,
    required this.sortOrder,
  });
}

class TimeEntry {
  final int id;
  final int subjectId;
  final int? taskId;
  final String day;
  final int minutes;
  final String source;
  final String? note;
  final int? startedAt;
  final int? endedAt;
  final int createdAt;

  const TimeEntry({
    required this.id,
    required this.subjectId,
    required this.taskId,
    required this.day,
    required this.minutes,
    required this.source,
    required this.note,
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
  });
}

class NoteItem {
  final int id;
  final String day;
  final int subjectId;
  final String content;
  final int createdAt;
  final int updatedAt;

  const NoteItem({
    required this.id,
    required this.day,
    required this.subjectId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}

class TimerSession {
  int? subjectId;
  int? taskId;
  String? note;
  int accumulatedMs;
  int? segmentStartedAt;
  int? firstStartedAt;
  bool running;

  TimerSession({
    this.subjectId,
    this.taskId,
    this.note,
    this.accumulatedMs = 0,
    this.segmentStartedAt,
    this.firstStartedAt,
    this.running = false,
  });

  int elapsedMs([DateTime? now]) {
    var total = accumulatedMs;
    if (running && segmentStartedAt != null) {
      final diff = (now ?? DateTime.now()).millisecondsSinceEpoch - segmentStartedAt!;
      if (diff > 0) total += diff;
    }
    return total < 0 ? 0 : total;
  }
}

class SubjectSummary {
  final int subjectId;
  final String name;
  final int color;
  final int minutes;
  final int targetMinutes;
  final int totalMinutes;

  const SubjectSummary({
    required this.subjectId,
    required this.name,
    required this.color,
    required this.minutes,
    required this.targetMinutes,
    required this.totalMinutes,
  });
}

class EntryDraft {
  final int subjectId;
  final int? taskId;
  final String day;
  final int minutes;
  final String source;
  final String? note;
  final int? startedAt;
  final int? endedAt;

  const EntryDraft({
    required this.subjectId,
    required this.taskId,
    required this.day,
    required this.minutes,
    required this.source,
    this.note,
    this.startedAt,
    this.endedAt,
  });
}
