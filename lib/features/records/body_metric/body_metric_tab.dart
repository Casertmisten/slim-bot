import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/record_providers.dart';

class BodyMetricTab extends ConsumerWidget {
  final int studentId;
  const BodyMetricTab({super.key, required this.studentId});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final typeCtl = TextEditingController();
    final valCtl = TextEditingController();
    final unitCtl = TextEditingController(text: 'cm');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('录入围度/体脂'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeCtl, decoration: const InputDecoration(labelText: '类型（腰围/臀围/体脂率…）'),
                validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: valCtl, decoration: const InputDecoration(labelText: '数值'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => double.tryParse(v ?? '') == null ? '无效' : null,
              ),
              TextFormField(controller: unitCtl, decoration: const InputDecoration(labelText: '单位')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).createBodyMetric(studentId, BodyMetricInput(
        recordDate: DateTime.now(), metricType: typeCtl.text, value: double.parse(valCtl.text), unit: unitCtl.text,
      ));
      ref.invalidate(bodyMetricListProvider(studentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bodyMetricListProvider(studentId));
    return Stack(
      children: [
        async.when(
          data: (list) => ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = list[i];
              return ListTile(
                leading: const Icon(Icons.straighten_outlined),
                title: Text('${m.metricType}: ${m.value} ${m.unit}'),
                subtitle: Text('${m.recordDate.year}-${m.recordDate.month}-${m.recordDate.day}'),
                onLongPress: () async {
                  await ref.read(repositoryProvider).deleteBodyMetric(studentId, m.id);
                  ref.invalidate(bodyMetricListProvider(studentId));
                },
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'body_metric',
            onPressed: () => _add(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
