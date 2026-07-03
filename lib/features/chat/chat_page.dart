import 'package:flutter/material.dart';

final class ChatPage extends StatelessWidget {
  final int sessionId;
  const ChatPage({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('对话 $sessionId')));
}
