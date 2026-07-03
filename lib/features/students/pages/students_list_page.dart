import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../providers/student_providers.dart';
import '../widgets/student_card.dart';

class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentListProvider(_search));
    return Scaffold(
      appBar: AppBar(title: const Text('学员')),
      body: Padding(
        padding: EdgeInsets.all(contentMargin(context)),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索学员姓名',
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                data: (students) => students.isEmpty
                    ? const Center(child: Text('暂无学员，点右下角添加'))
                    : ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => StudentCard(student: students[i]),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('加载失败'),
                      TextButton(
                          onPressed: () =>
                              ref.invalidate(studentListProvider(_search)),
                          child: const Text('重试')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/students/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
