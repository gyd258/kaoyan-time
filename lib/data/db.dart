import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  static const _dbName = 'yanshi.db';
  static const _version = 1;
  Database? _db;

  Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, _dbName),
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subjects (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            name           TEXT    NOT NULL,
            color          INTEGER NOT NULL,
            target_minutes INTEGER NOT NULL DEFAULT 0,
            archived       INTEGER NOT NULL DEFAULT 0,
            sort_order     INTEGER NOT NULL DEFAULT 0,
            created_at     INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            name       TEXT    NOT NULL,
            archived   INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_subject ON tasks(subject_id)');
        await db.execute('''
          CREATE TABLE time_entries (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            task_id    INTEGER,
            day        TEXT    NOT NULL,
            minutes    INTEGER NOT NULL,
            source     TEXT    NOT NULL,
            note       TEXT,
            started_at INTEGER,
            ended_at   INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_entries_day ON time_entries(day)');
        await db.execute('CREATE INDEX idx_entries_subject ON time_entries(subject_id)');
        await db.execute('''
          CREATE TABLE notes (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            day        TEXT    NOT NULL,
            subject_id INTEGER NOT NULL,
            content    TEXT    NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_notes_day ON notes(day)');
        await db.execute('''
          CREATE TABLE settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE timer_state (
            id               INTEGER PRIMARY KEY CHECK (id = 1),
            subject_id       INTEGER,
            task_id          INTEGER,
            note             TEXT,
            accumulated_ms   INTEGER NOT NULL DEFAULT 0,
            segment_started_at INTEGER,
            first_started_at INTEGER,
            running          INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  // ---------- 科目 ----------

  Future<List<Subject>> loadSubjects() async {
    final db = await instance;
    final rows = await db.query('subjects', orderBy: 'sort_order ASC, id ASC');
    return rows
        .map((r) => Subject(
              id: r['id'] as int,
              name: r['name'] as String,
              color: r['color'] as int,
              targetMinutes: r['target_minutes'] as int,
              archived: (r['archived'] as int) == 1,
              sortOrder: r['sort_order'] as int,
            ))
        .toList();
  }

  Future<int> insertSubject(String name, int color, int targetMinutes) async {
    final db = await instance;
    final maxRow = await db.rawQuery('SELECT MAX(sort_order) AS m FROM subjects');
    final next = ((maxRow.first['m'] as int?) ?? 0) + 1;
    return db.insert('subjects', {
      'name': name,
      'color': color,
      'target_minutes': targetMinutes,
      'archived': 0,
      'sort_order': next,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateSubject(Subject s) async {
    final db = await instance;
    await db.update(
      'subjects',
      {
        'name': s.name,
        'color': s.color,
        'target_minutes': s.targetMinutes,
        'archived': s.archived ? 1 : 0,
        'sort_order': s.sortOrder,
      },
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  // ---------- 任务 ----------

  Future<List<TaskItem>> loadTasks() async {
    final db = await instance;
    final rows = await db.query('tasks', orderBy: 'sort_order ASC, id ASC');
    return rows
        .map((r) => TaskItem(
              id: r['id'] as int,
              subjectId: r['subject_id'] as int,
              name: r['name'] as String,
              archived: (r['archived'] as int) == 1,
              sortOrder: r['sort_order'] as int,
            ))
        .toList();
  }

  Future<int> insertTask(int subjectId, String name) async {
    final db = await instance;
    final maxRow =
        await db.rawQuery('SELECT MAX(sort_order) AS m FROM tasks WHERE subject_id = ?', [subjectId]);
    final next = ((maxRow.first['m'] as int?) ?? 0) + 1;
    return db.insert('tasks', {
      'subject_id': subjectId,
      'name': name,
      'archived': 0,
      'sort_order': next,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateTask(TaskItem t) async {
    final db = await instance;
    await db.update(
      'tasks',
      {'name': t.name, 'archived': t.archived ? 1 : 0, 'sort_order': t.sortOrder},
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  // ---------- 时间条目 ----------

  Future<int> insertEntry(EntryDraft d) async {
    final db = await instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('time_entries', {
      'subject_id': d.subjectId,
      'task_id': d.taskId,
      'day': d.day,
      'minutes': d.minutes,
      'source': d.source,
      'note': d.note,
      'started_at': d.startedAt,
      'ended_at': d.endedAt,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateEntry(int id, EntryDraft d) async {
    final db = await instance;
    await db.update(
      'time_entries',
      {
        'subject_id': d.subjectId,
        'task_id': d.taskId,
        'day': d.day,
        'minutes': d.minutes,
        'source': d.source,
        'note': d.note,
        'started_at': d.startedAt,
        'ended_at': d.endedAt,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = await instance;
    await db.delete('time_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TimeEntry>> entriesOfDay(String day) async {
    final db = await instance;
    final rows = await db.query('time_entries',
        where: 'day = ?', whereArgs: [day], orderBy: 'created_at ASC, id ASC');
    return rows.map(_entryFrom).toList();
  }

  Future<List<TimeEntry>> allEntries() async {
    final db = await instance;
    final rows = await db.query('time_entries', orderBy: 'day ASC, created_at ASC');
    return rows.map(_entryFrom).toList();
  }

  Future<Map<int, int>> minutesBySubject({String? from, String? to}) async {
    final db = await instance;
    final where = <String>[];
    final args = <Object>[];
    if (from != null) {
      where.add('day >= ?');
      args.add(from);
    }
    if (to != null) {
      where.add('day <= ?');
      args.add(to);
    }
    final sql = 'SELECT subject_id, SUM(minutes) AS m FROM time_entries'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} GROUP BY subject_id';
    final rows = await db.rawQuery(sql, args);
    return {
      for (final r in rows) r['subject_id'] as int: ((r['m'] as int?) ?? 0),
    };
  }

  Future<Map<String, int>> minutesByDay({required String from, required String to}) async {
    final db = await instance;
    final rows = await db.rawQuery(
      'SELECT day, SUM(minutes) AS m FROM time_entries WHERE day >= ? AND day <= ? GROUP BY day',
      [from, to],
    );
    return {
      for (final r in rows) r['day'] as String: ((r['m'] as int?) ?? 0),
    };
  }

  Future<int> countEntries({String? from, String? to}) async {
    final db = await instance;
    final where = <String>[];
    final args = <Object>[];
    if (from != null) {
      where.add('day >= ?');
      args.add(from);
    }
    if (to != null) {
      where.add('day <= ?');
      args.add(to);
    }
    final sql = 'SELECT COUNT(*) AS c FROM time_entries'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}';
    final rows = await db.rawQuery(sql, args);
    return (rows.first['c'] as int?) ?? 0;
  }

  // ---------- 笔记 ----------

  Future<List<NoteItem>> loadNotes({int? subjectId, String keyword = ''}) async {
    final db = await instance;
    final where = <String>[];
    final args = <Object>[];
    if (subjectId != null) {
      where.add('subject_id = ?');
      args.add(subjectId);
    }
    final k = keyword.trim();
    if (k.isNotEmpty) {
      where.add('content LIKE ?');
      args.add('%$k%');
    }
    final rows = await db.query(
      'notes',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'day DESC, created_at DESC',
    );
    return rows
        .map((r) => NoteItem(
              id: r['id'] as int,
              day: r['day'] as String,
              subjectId: r['subject_id'] as int,
              content: r['content'] as String,
              createdAt: r['created_at'] as int,
              updatedAt: r['updated_at'] as int,
            ))
        .toList();
  }

  Future<int> insertNote(String day, int subjectId, String content) async {
    final db = await instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('notes', {
      'day': day,
      'subject_id': subjectId,
      'content': content,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateNote(int id, String day, int subjectId, String content) async {
    final db = await instance;
    await db.update(
      'notes',
      {
        'day': day,
        'subject_id': subjectId,
        'content': content,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await instance;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- 设置 ----------

  Future<String?> getSetting(String key) async {
    final db = await instance;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- 计时状态 ----------

  Future<TimerSession?> loadTimer() async {
    final db = await instance;
    final rows = await db.query('timer_state', where: 'id = 1');
    if (rows.isEmpty) return null;
    final r = rows.first;
    if (r['subject_id'] == null && r['accumulated_ms'] == 0 && (r['running'] as int) == 0) {
      return null;
    }
    return TimerSession(
      subjectId: r['subject_id'] as int?,
      taskId: r['task_id'] as int?,
      note: r['note'] as String?,
      accumulatedMs: r['accumulated_ms'] as int,
      segmentStartedAt: r['segment_started_at'] as int?,
      firstStartedAt: r['first_started_at'] as int?,
      running: (r['running'] as int) == 1,
    );
  }

  Future<void> saveTimer(TimerSession s) async {
    final db = await instance;
    await db.insert(
      'timer_state',
      {
        'id': 1,
        'subject_id': s.subjectId,
        'task_id': s.taskId,
        'note': s.note,
        'accumulated_ms': s.accumulatedMs,
        'segment_started_at': s.segmentStartedAt,
        'first_started_at': s.firstStartedAt,
        'running': s.running ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearTimer() async {
    final db = await instance;
    await db.delete('timer_state');
  }

  Future<void> clearAllData() async {
    final db = await instance;
    await db.transaction((txn) async {
      await txn.delete('time_entries');
      await txn.delete('notes');
      await txn.delete('tasks');
      await txn.delete('subjects');
      await txn.delete('settings');
      await txn.delete('timer_state');
    });
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await instance;
    final subjects = await db.query('subjects', orderBy: 'sort_order ASC, id ASC');
    final tasks = await db.query('tasks', orderBy: 'sort_order ASC, id ASC');
    final entries = await db.query('time_entries', orderBy: 'day ASC, created_at ASC');
    final notes = await db.query('notes', orderBy: 'day ASC, created_at ASC');
    final settings = await db.query('settings');
    return {
      'app': 'yanshi',
      'schemaVersion': _version,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'subjects': subjects,
      'tasks': tasks,
      'timeEntries': entries,
      'notes': notes,
      'settings': settings,
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await instance;
    await db.transaction((txn) async {
      await txn.delete('time_entries');
      await txn.delete('notes');
      await txn.delete('tasks');
      await txn.delete('subjects');
      await txn.delete('settings');
      await txn.delete('timer_state');
      for (final s in (data['subjects'] as List? ?? [])) {
        await txn.insert('subjects', Map<String, Object?>.from(s as Map));
      }
      for (final t in (data['tasks'] as List? ?? [])) {
        await txn.insert('tasks', Map<String, Object?>.from(t as Map));
      }
      for (final e in (data['timeEntries'] as List? ?? [])) {
        await txn.insert('time_entries', Map<String, Object?>.from(e as Map));
      }
      for (final n in (data['notes'] as List? ?? [])) {
        await txn.insert('notes', Map<String, Object?>.from(n as Map));
      }
      for (final s in (data['settings'] as List? ?? [])) {
        await txn.insert('settings', Map<String, Object?>.from(s as Map));
      }
    });
  }

  TimeEntry _entryFrom(Map<String, Object?> r) => TimeEntry(
        id: r['id'] as int,
        subjectId: r['subject_id'] as int,
        taskId: r['task_id'] as int?,
        day: r['day'] as String,
        minutes: r['minutes'] as int,
        source: r['source'] as String,
        note: r['note'] as String?,
        startedAt: r['started_at'] as int?,
        endedAt: r['ended_at'] as int?,
        createdAt: r['created_at'] as int,
      );
}
