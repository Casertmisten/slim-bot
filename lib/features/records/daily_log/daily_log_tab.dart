import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/record_providers.dart';

class DailyLogTab extends ConsumerWidget {
  final int studentId;
  const DailyLogTab({super.key, required this.studentId});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final contentCtl = TextEditingController();
    final calCtl = TextEditingController();
    LogType type = LogType.breakfast;
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('录入饮食/运动'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LogType>(
                value: type, decoration: const InputDecoration(labelText: '类型'),
                items: LogType.values.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setSt(() => type = v!),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${date.year}-${date.month}-${date.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx, initialDate: date,
                    firstDate: DateTime(2020), lastDate: DateTime.now(),
                  );
                  if (p != null) setSt(() => date = p);
                },
              ),
              TextFormField(
                controller: contentCtl, decoration: const InputDecoration(labelText: '内容'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: calCtl, decoration: const InputDecoration(labelText: '热量（可选）'),
                keyboardType: TextInputType.number,
              ),
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
      )),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).createDailyLog(studentId, DailyLogInput(
        logDate: date, logType: type, content: contentCtl.text,
        calories: double.tryParse(calCtl.text),
      ));
      ref.invalidate(dailyLogListProvider(studentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyLogListProvider(studentId));
    return Stack(
      children: [
        async.when(
          data: (list) => ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final l = list[i];
              return ListTile(
                leading: Icon(l.logType == LogType.exercise ? Icons.fitness_center : Icons.restaurant),
                title: Text(l.content),
                subtitle: Text('${l.logType.label} · ${l.logDate.year}-${l.logDate.month}-${l.logDate.day}'
                    '${l.calories != null ? " · ${l.calories}kcal" : ""}'),
                onLongPress: () async {
                  await ref.read(repositoryProvider).deleteDailyLog(studentId, l.id);
                  ref.invalidate(dailyLogListProvider(studentId));
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
            heroTag: 'daily_log',
            onPressed: () => _add(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
