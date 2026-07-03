import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/repositories/repository_provider.dart';
import 'providers/chat_providers.dart';
import 'widgets/chat_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int sessionId;
  const ChatPage({super.key, required this.sessionId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <ChatMessage>[];
  bool _sending = false;
  String _streaming = '';

  @override
  void dispose() {
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _messages.add(ChatMessage(
        id: -1, sessionId: widget.sessionId, role: MessageRole.user,
        content: text, createdAt: DateTime.now(),
      ));
      _streaming = '';
    });
    _scrollDown();

    final repo = ref.read(repositoryProvider);
    try {
      await repo.sendMessageStream(widget.sessionId, text, onChunk: (chunk) {
        setState(() => _streaming += chunk);
        _scrollDown();
      });
      // 流结束后刷新历史（拿到带 id 的真实消息）
      ref.invalidate(chatMessagesProvider(widget.sessionId));
      final fresh = await ref.read(chatMessagesProvider(widget.sessionId).future);
      setState(() {
        _messages.clear();
        _messages.addAll(fresh);
        _streaming = '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatMessagesProvider(widget.sessionId));
    // 首次加载历史
    if (_messages.isEmpty) {
      history.whenData((list) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messages.isEmpty && mounted) {
            setState(() {
              _messages.addAll(list);
            });
            _scrollDown();
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('对话')),
      body: Column(
        children: [
          Expanded(
            child: history.when(
              data: (_) => ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final m in _messages) ...[
                    ChatBubble(role: m.role, content: m.content),
                    const SizedBox(height: 8),
                  ],
                  if (_streaming.isNotEmpty) ...[
                    ChatBubble(role: MessageRole.assistant, content: _streaming),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: '输入消息...'),
                      onSubmitted: (_) => _send(),
                      enabled: !_sending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
