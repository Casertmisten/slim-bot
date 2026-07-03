import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';

/// 对话气泡
class ChatBubble extends StatelessWidget {
  final MessageRole role;
  final String content;
  const ChatBubble({super.key, required this.role, required this.content});

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          style: TextStyle(color: isUser ? AppColors.onPrimary : AppColors.onSurface),
        ),
      ),
    );
  }
}
