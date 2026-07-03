import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import 'repository.dart';

/// 真实 HTTP 实现（对接后端时使用）。
class HttpRepository implements Repository {
  HttpRepository(this._client);
  final ApiClient _client;
  Dio get _dio => _client.dio;

  // ===== 学员 =====
  @override
  Future<List<Student>> listStudents(
      {String? search, int page = 1, int pageSize = 20}) async {
    final r = await _dio.get('/students', queryParameters: {
      if (search != null) 'search': search,
      'page': page,
      'page_size': pageSize,
    });
    final data = r.data['items'] as List;
    return data
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Student> getStudent(int id) async {
    final r = await _dio.get('/students/$id');
    return Student.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<Student> createStudent(StudentInput input) async {
    final r = await _dio.post('/students', data: input.toJson());
    return Student.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<Student> updateStudent(int id, StudentInput input) async {
    final r = await _dio.put('/students/$id', data: input.toJson());
    return Student.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteStudent(int id) async {
    await _dio.delete('/students/$id');
  }

  // ===== 体重 =====
  @override
  Future<List<WeightRecord>> listWeights(int studentId,
      {DateTime? start, DateTime? end}) async {
    final r = await _dio.get('/students/$studentId/weights', queryParameters: {
      if (start != null) 'start': start.toIso8601String().substring(0, 10),
      if (end != null) 'end': end.toIso8601String().substring(0, 10),
    });
    final data = r.data as List;
    return data
        .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WeightRecord> upsertWeight(int studentId, WeightInput input) async {
    final r =
        await _dio.post('/students/$studentId/weights', data: input.toJson());
    return WeightRecord.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteWeight(int studentId, int recordId) async {
    await _dio.delete('/students/$studentId/weights/$recordId');
  }

  // ===== 围度/体脂 =====
  @override
  Future<List<BodyMetricRecord>> listBodyMetrics(int studentId,
      {DateTime? start, DateTime? end}) async {
    final r = await _dio.get('/students/$studentId/body-metrics',
        queryParameters: {
          if (start != null) 'start': start.toIso8601String().substring(0, 10),
          if (end != null) 'end': end.toIso8601String().substring(0, 10),
        });
    final data = r.data as List;
    return data
        .map((e) => BodyMetricRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BodyMetricRecord> createBodyMetric(
      int studentId, BodyMetricInput input) async {
    final r = await _dio.post('/students/$studentId/body-metrics',
        data: input.toJson());
    return BodyMetricRecord.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBodyMetric(int studentId, int recordId) async {
    await _dio.delete('/students/$studentId/body-metrics/$recordId');
  }

  // ===== 饮食/运动 =====
  @override
  Future<List<DailyLog>> listDailyLogs(int studentId, {DateTime? date}) async {
    final r =
        await _dio.get('/students/$studentId/daily-logs', queryParameters: {
      if (date != null) 'date': date.toIso8601String().substring(0, 10),
    });
    final data = r.data as List;
    return data
        .map((e) => DailyLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DailyLog> createDailyLog(
      int studentId, DailyLogInput input) async {
    final r = await _dio.post('/students/$studentId/daily-logs',
        data: input.toJson());
    return DailyLog.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDailyLog(int studentId, int recordId) async {
    await _dio.delete('/students/$studentId/daily-logs/$recordId');
  }

  // ===== 对话 =====
  @override
  Future<ChatSession> createChatSession(ChatSessionInput input) async {
    final r = await _dio.post('/chat/sessions', data: input.toJson());
    return ChatSession.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<List<ChatSession>> listChatSessions({int? studentId}) async {
    final r = await _dio.get('/chat/sessions',
        queryParameters: {
          if (studentId != null) 'student_id': studentId,
        });
    final data = r.data as List;
    return data
        .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ChatMessage>> listMessages(int sessionId) async {
    final r = await _dio.get('/chat/sessions/$sessionId/messages');
    final data = r.data as List;
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteChatSession(int sessionId) async {
    await _dio.delete('/chat/sessions/$sessionId');
  }

  /// SSE 流式：responseType=stream，逐行解析 `data: {...}`。
  @override
  Future<void> sendMessageStream(
    int sessionId,
    String content, {
    required void Function(String chunk) onChunk,
  }) async {
    final response = await _dio.post<ResponseBody>(
      '/chat/sessions/$sessionId/messages',
      data: {'content': content},
      options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'}),
    );
    final stream = response.data!.stream;
    await for (final bytes in stream) {
      final text = utf8.decode(bytes);
      for (final line in text.split('\n')) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        final obj = jsonDecode(payload) as Map<String, dynamic>;
        if (obj['type'] == 'chunk') {
          onChunk(obj['content'] as String);
        }
      }
    }
  }
}
