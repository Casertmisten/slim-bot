// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => ChatSession(
  id: (json['id'] as num).toInt(),
  studentId: (json['student_id'] as num?)?.toInt(),
  title: json['title'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ChatSessionToJson(ChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
    };

ChatSessionInput _$ChatSessionInputFromJson(Map<String, dynamic> json) =>
    ChatSessionInput(
      studentId: (json['student_id'] as num?)?.toInt(),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$ChatSessionInputToJson(ChatSessionInput instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'title': instance.title,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num).toInt(),
  sessionId: (json['session_id'] as num).toInt(),
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
};
