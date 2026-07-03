// Repository 抽象接口。
// 真实实现走 HTTP，Mock 实现返回假数据。
// 前端开发期用 Mock，后端就绪后切换到 HttpRepository。
import '../models/models.dart';

abstract class Repository {
  // ===== 学员 =====
  Future<List<Student>> listStudents(
      {String? search, int page = 1, int pageSize = 20});
  Future<Student> getStudent(int id);
  Future<Student> createStudent(StudentInput input);
  Future<Student> updateStudent(int id, StudentInput input);
  Future<void> deleteStudent(int id);

  // ===== 体重 =====
  Future<List<WeightRecord>> listWeights(int studentId,
      {DateTime? start, DateTime? end});
  Future<WeightRecord> upsertWeight(int studentId, WeightInput input);
  Future<void> deleteWeight(int studentId, int recordId);

  // ===== 围度/体脂 =====
  Future<List<BodyMetricRecord>> listBodyMetrics(int studentId,
      {DateTime? start, DateTime? end});
  Future<BodyMetricRecord> createBodyMetric(
      int studentId, BodyMetricInput input);
  Future<void> deleteBodyMetric(int studentId, int recordId);

  // ===== 饮食/运动 =====
  Future<List<DailyLog>> listDailyLogs(int studentId, {DateTime? date});
  Future<DailyLog> createDailyLog(int studentId, DailyLogInput input);
  Future<void> deleteDailyLog(int studentId, int recordId);

  // ===== 对话 =====
  Future<ChatSession> createChatSession(ChatSessionInput input);
  Future<List<ChatSession>> listChatSessions({int? studentId});
  Future<List<ChatMessage>> listMessages(int sessionId);
  Future<void> deleteChatSession(int sessionId);

  /// 发送消息并以 SSE 流式接收。onChunk 收到文本增量。
  Future<void> sendMessageStream(
    int sessionId,
    String content, {
    required void Function(String chunk) onChunk,
  });
}
