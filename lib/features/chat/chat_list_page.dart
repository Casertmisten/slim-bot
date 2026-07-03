import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/responsive.dart';
import '../../core/repositories/repository_provider.dart';
import 'providers/chat_providers.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  Future<void> _newSession(BuildContext context, WidgetRef ref) async {
    final session = await ref.read(repositoryProvider).createChatSession(
          const ChatSessionInput(title: '新会话'),
        );
    if (context.mounted) {
      ref.invalidate(chatSessionListProvider(null));
      context.push('/chat/${session.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatSessionListProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('对话')),
      body: Padding(
        padding: EdgeInsets.all(contentMargin(context)),
        child: async.when(
          data: (sessions) => sessions.isEmpty
              ? const Center(child: Text('暂无会话，点右下角新建'))
              : ListView.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(s.title),
                      subtitle: Text('${s.createdAt.year}-${s.createdAt.month}-${s.createdAt.day}'
                          '${s.studentId != null ? " · 已绑定学员" : ""}'),
                      onTap: () => context.push('/chat/${s.id}'),
                      onLongPress: () async {
                        await ref.read(repositoryProvider).deleteChatSession(s.id);
                        ref.invalidate(chatSessionListProvider(null));
                      },
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newSession(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
