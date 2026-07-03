import 'package:json_annotation/json_annotation.dart';
part 'chat.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatSession {
  final int id;
  final int? studentId;
  final String title;
  final DateTime createdAt;

  const ChatSession({
    required this.id,
    this.studentId,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatSessionInput {
  final int? studentId;
  final String? title;

  const ChatSessionInput({this.studentId, this.title});

  factory ChatSessionInput.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionInputFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionInputToJson(this);
}

enum MessageRole {
  @JsonValue('user') user,
  @JsonValue('assistant') assistant,
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatMessage {
  final int id;
  final int sessionId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
