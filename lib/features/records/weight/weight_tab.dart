import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/record_providers.dart';
import 'weight_chart.dart';

class WeightTab extends ConsumerStatefulWidget {
  final int studentId;
  const WeightTab({super.key, required this.studentId});

  @override
  ConsumerState<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends ConsumerState<WeightTab> {
  Future<void> _add() async {
    final input = await showDialog<WeightInput>(
      context: context,
      builder: (ctx) => _WeightDialog(),
    );
    if (input == null) return;
    await ref.read(repositoryProvider).upsertWeight(widget.studentId, input);
    ref.invalidate(weightListProvider(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weightListProvider(widget.studentId));
    return async.when(
      data: (records) => Column(
        children: [
          WeightChart(records: records),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: records.length,
              reverse: true,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = records[records.length - 1 - i];
                return ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${r.weightKg} kg'),
                  subtitle: Text('${r.recordDate.year}-${r.recordDate.month}-${r.recordDate.day}'),
                  trailing: Text(r.note),
                  onLongPress: () async {
                    await ref.read(repositoryProvider).deleteWeight(widget.studentId, r.id);
                    ref.invalidate(weightListProvider(widget.studentId));
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('录入体重'),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
    );
  }
}

class _WeightDialog extends StatefulWidget {
  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  DateTime _date = DateTime.now();
  final _weight = TextEditingController();
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('录入体重'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${_date.year}-${_date.month}-${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              controller: _weight,
              decoration: const InputDecoration(labelText: '体重 (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => double.tryParse(v ?? '') == null ? '请输入有效数值' : null,
            ),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                WeightInput(
                  recordDate: _date,
                  weightKg: double.parse(_weight.text),
                  note: _note.text,
                ),
              );
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
