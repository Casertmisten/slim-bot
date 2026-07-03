import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';

/// 学员列表（带搜索）
final studentListProvider =
    FutureProvider.family<List<Student>, String>((ref, search) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listStudents(search: search.isEmpty ? null : search);
});

/// 单个学员详情
final studentProvider =
    FutureProvider.family<Student, int>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getStudent(id);
});
