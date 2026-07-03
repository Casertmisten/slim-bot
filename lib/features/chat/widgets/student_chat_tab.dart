import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/chat_providers.dart';

class StudentChatTab extends ConsumerWidget {
  final int studentId;
  const StudentChatTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatSessionListProvider(studentId));
    return Stack(
      children: [
        async.when(
          data: (sessions) => ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = sessions[i];
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(s.title),
                subtitle: Text('${s.createdAt.year}-${s.createdAt.month}-${s.createdAt.day}'),
                onTap: () => context.push('/chat/${s.id}'),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'student_chat',
            onPressed: () async {
              final s = await ref.read(repositoryProvider).createChatSession(
                    ChatSessionInput(studentId: studentId),
                  );
              if (context.mounted) context.push('/chat/${s.id}');
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
