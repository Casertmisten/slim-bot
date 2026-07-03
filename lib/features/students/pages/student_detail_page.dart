import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../../../features/records/body_metric/body_metric_tab.dart';
import '../../../features/records/daily_log/daily_log_tab.dart';
import '../../../features/records/weight/weight_tab.dart';
import '../providers/student_providers.dart';
import '../widgets/student_header.dart';

class StudentDetailPage extends ConsumerWidget {
  final int id;
  const StudentDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: async.maybeWhen(
            data: (s) => Text(s.name), orElse: () => const Text('学员详情')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/students/$id/edit'),
          ),
        ],
      ),
      body: async.when(
        data: (student) => _DetailTabs(id: id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

class _DetailTabs extends ConsumerStatefulWidget {
  final int id;
  const _DetailTabs({required this.id});

  @override
  ConsumerState<_DetailTabs> createState() => _DetailTabsState();
}

class _DetailTabsState extends ConsumerState<_DetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentProvider(widget.id)).valueOrNull;
    return Column(
      children: [
        if (student != null) StudentHeader(student: student),
        TabBar(
          controller: _tab,
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          tabs: const [
            Tab(text: '档案'),
            Tab(text: '体重'),
            Tab(text: '围度'),
            Tab(text: '饮食运动'),
            Tab(text: '对话'),
          ],
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(contentMargin(context)),
            child: TabBarView(
              controller: _tab,
              // 占位：后续阶段填充真实内容
              children: [
                const Center(child: Text('档案')),
                WeightTab(studentId: widget.id),
                BodyMetricTab(studentId: widget.id),
                DailyLogTab(studentId: widget.id),
                const Center(child: Text('对话（阶段4实现）')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
