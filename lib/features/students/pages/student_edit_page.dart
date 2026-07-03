import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../../../core/responsive.dart';
import '../providers/student_providers.dart';

class StudentEditPage extends ConsumerStatefulWidget {
  final int? studentId; // null = 新建
  const StudentEditPage({super.key, this.studentId});

  @override
  ConsumerState<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends ConsumerState<StudentEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _target = TextEditingController();
  final _notes = TextEditingController();
  Gender _gender = Gender.male;
  DateTime _startDate = DateTime(2026, 7, 1);
  bool _loaded = false;
  bool _saving = false;

  bool get _isEdit => widget.studentId != null;

  @override
  void dispose() {
    for (final c in [_name, _age, _height, _target, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadIfEdit(Student s) {
    if (_loaded) return;
    _loaded = true;
    _name.text = s.name;
    _gender = s.gender;
    _age.text = '${s.age}';
    _height.text = '${s.heightCm}';
    _target.text = '${s.targetWeightKg}';
    _startDate = s.startDate;
    _notes.text = s.notes;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final input = StudentInput(
      name: _name.text.trim(),
      gender: _gender,
      age: int.parse(_age.text),
      heightCm: double.parse(_height.text),
      targetWeightKg: double.parse(_target.text),
      startDate: _startDate,
      notes: _notes.text.trim(),
    );
    try {
      if (_isEdit) {
        await repo.updateStudent(widget.studentId!, input);
        ref.invalidate(studentProvider(widget.studentId!));
      } else {
        await repo.createStudent(input);
      }
      if (mounted) {
        ref.invalidate(studentListProvider(''));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑学员' : '新建学员')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoint.containerMax),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isEdit
                  ? ref.watch(studentProvider(widget.studentId!)).when(
                        data: (s) {
                          _loadIfEdit(s);
                          return _form();
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('加载失败：$e'),
                      )
                  : _form(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: '姓名'),
            validator: (v) => (v == null || v.isEmpty) ? '请输入姓名' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Gender>(
            value: _gender,
            decoration: const InputDecoration(labelText: '性别'),
            items: Gender.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _age,
            decoration: const InputDecoration(labelText: '年龄'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                int.tryParse(v ?? '') == null ? '请输入有效年龄' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _height,
            decoration: const InputDecoration(labelText: '身高 (cm)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                double.tryParse(v ?? '') == null ? '请输入有效身高' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _target,
            decoration: const InputDecoration(labelText: '目标体重 (kg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                double.tryParse(v ?? '') == null ? '请输入有效体重' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('开始日期'),
            subtitle: Text(
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
            onTap: _pickDate,
          ),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: '备注'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}
