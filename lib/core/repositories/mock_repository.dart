import 'dart:async';
import '../models/models.dart';
import 'repository.dart';

/// Mock 实现：返回内存假数据，前端开发期使用。
class MockRepository implements Repository {
  final List<Student> _students = [];
  final List<WeightRecord> _weights = [];
  final List<BodyMetricRecord> _metrics = [];
  final List<DailyLog> _logs = [];
  final List<ChatSession> _sessions = [];
  final List<ChatMessage> _messages = [];
  int _seq = 1;

  int _next() => _seq++;

  MockRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime(2026, 7, 1);
    final s = Student(
      id: _next(),
      name: '小王',
      gender: Gender.male,
      age: 30,
      heightCm: 175,
      targetWeightKg: 70,
      startDate: now,
      notes: '久坐办公',
      createdAt: now,
      updatedAt: now,
    );
    _students.add(s);
    for (var i = 0; i < 14; i++) {
      _weights.add(WeightRecord(
        id: _next(),
        studentId: s.id,
        recordDate: now.subtract(Duration(days: 13 - i)),
        weightKg: 82 - i * 0.4,
        note: '',
        createdAt: now,
      ));
    }
  }

  Future<T> _delay<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 300), () => value);

  // ===== 学员 =====
  @override
  Future<List<Student>> listStudents(
      {String? search, int page = 1, int pageSize = 20}) async {
    var list = _students
        .where((s) => search == null || s.name.contains(search))
        .toList();
    return _delay(list);
  }

  @override
  Future<Student> getStudent(int id) async =>
      _delay(_students.firstWhere((s) => s.id == id));

  @override
  Future<Student> createStudent(StudentInput input) async {
    final now = DateTime.now();
    final s = Student(
      id: _next(),
      name: input.name,
      gender: input.gender,
      age: input.age,
      heightCm: input.heightCm,
      targetWeightKg: input.targetWeightKg,
      startDate: input.startDate,
      notes: input.notes,
      createdAt: now,
      updatedAt: now,
    );
    _students.add(s);
    return _delay(s);
  }

  @override
  Future<Student> updateStudent(int id, StudentInput input) async {
    final idx = _students.indexWhere((s) => s.id == id);
    final old = _students[idx];
    final updated = Student(
      id: id,
      name: input.name,
      gender: input.gender,
      age: input.age,
      heightCm: input.heightCm,
      targetWeightKg: input.targetWeightKg,
      startDate: input.startDate,
      notes: input.notes,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _students[idx] = updated;
    return _delay(updated);
  }

  @override
  Future<void> deleteStudent(int id) async {
    _students.removeWhere((s) => s.id == id);
    _weights.removeWhere((w) => w.studentId == id);
    return _delay(null);
  }

  // ===== 体重 =====
  @override
  Future<List<WeightRecord>> listWeights(int studentId,
          {DateTime? start, DateTime? end}) async =>
      _delay(_weights.where((w) => w.studentId == studentId).toList());

  @override
  Future<WeightRecord> upsertWeight(int studentId, WeightInput input) async {
    final existingIdx = _weights.indexWhere(
      (w) => w.studentId == studentId && w.recordDate == input.recordDate,
    );
    if (existingIdx >= 0) {
      final old = _weights[existingIdx];
      final updated = WeightRecord(
        id: old.id,
        studentId: studentId,
        recordDate: input.recordDate,
        weightKg: input.weightKg,
        note: input.note,
        createdAt: old.createdAt,
      );
      _weights[existingIdx] = updated;
      return _delay(updated);
    }
    final w = WeightRecord(
      id: _next(),
      studentId: studentId,
      recordDate: input.recordDate,
      weightKg: input.weightKg,
      note: input.note,
      createdAt: DateTime.now(),
    );
    _weights.add(w);
    return _delay(w);
  }

  @override
  Future<void> deleteWeight(int studentId, int recordId) async {
    _weights.removeWhere((w) => w.id == recordId && w.studentId == studentId);
    return _delay(null);
  }

  // ===== 围度/体脂 =====
  @override
  Future<List<BodyMetricRecord>> listBodyMetrics(int studentId,
          {DateTime? start, DateTime? end}) async =>
      _delay(_metrics.where((m) => m.studentId == studentId).toList());

  @override
  Future<BodyMetricRecord> createBodyMetric(
      int studentId, BodyMetricInput input) async {
    final m = BodyMetricRecord(
      id: _next(),
      studentId: studentId,
      recordDate: input.recordDate,
      metricType: input.metricType,
      value: input.value,
      unit: input.unit,
      createdAt: DateTime.now(),
    );
    _metrics.add(m);
    return _delay(m);
  }

  @override
  Future<void> deleteBodyMetric(int studentId, int recordId) async {
    _metrics.removeWhere((m) => m.id == recordId);
    return _delay(null);
  }

  // ===== 饮食/运动 =====
  @override
  Future<List<DailyLog>> listDailyLogs(int studentId, {DateTime? date}) async =>
      _delay(_logs.where((l) => l.studentId == studentId).toList());

  @override
  Future<DailyLog> createDailyLog(int studentId, DailyLogInput input) async {
    final l = DailyLog(
      id: _next(),
      studentId: studentId,
      logDate: input.logDate,
      logType: input.logType,
      content: input.content,
      calories: input.calories,
      createdAt: DateTime.now(),
    );
    _logs.add(l);
    return _delay(l);
  }

  @override
  Future<void> deleteDailyLog(int studentId, int recordId) async {
    _logs.removeWhere((l) => l.id == recordId);
    return _delay(null);
  }

  // ===== 对话 =====
  @override
  Future<ChatSession> createChatSession(ChatSessionInput input) async {
    final s = ChatSession(
      id: _next(),
      studentId: input.studentId,
      title: input.title ?? '新会话',
      createdAt: DateTime.now(),
    );
    _sessions.add(s);
    return _delay(s);
  }

  @override
  Future<List<ChatSession>> listChatSessions({int? studentId}) async =>
      _delay(_sessions
          .where((s) => studentId == null || s.studentId == studentId)
          .toList());

  @override
  Future<List<ChatMessage>> listMessages(int sessionId) async =>
      _delay(_messages.where((m) => m.sessionId == sessionId).toList());

  @override
  Future<void> deleteChatSession(int sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    _messages.removeWhere((m) => m.sessionId == sessionId);
    return _delay(null);
  }

  /// 模拟流式回复：把一段假文本逐字推送。
  @override
  Future<void> sendMessageStream(
    int sessionId,
    String content, {
    required void Function(String chunk) onChunk,
  }) async {
    _messages.add(ChatMessage(
      id: _next(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    ));
    const reply =
        '根据小王近7天体重数据，从 82kg 下降到 76.4kg，趋势良好。建议保持当前饮食结构，注意蛋白质摄入。';
    for (final ch in reply.split('')) {
      await Future.delayed(const Duration(milliseconds: 30));
      onChunk(ch);
    }
    _messages.add(ChatMessage(
      id: _next(),
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: reply,
      createdAt: DateTime.now(),
    ));
  }
}
