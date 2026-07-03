import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';

/// 会话列表
final chatSessionListProvider =
    FutureProvider.family<List<ChatSession>, int?>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listChatSessions(studentId: studentId);
});

/// 某会话的消息列表
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, int>((ref, sessionId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listMessages(sessionId);
});
