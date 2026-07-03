import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';

/// 某学员体重记录
final weightListProvider =
    FutureProvider.family<List<WeightRecord>, int>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listWeights(studentId);
});

/// 某学员围度记录
final bodyMetricListProvider =
    FutureProvider.family<List<BodyMetricRecord>, int>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listBodyMetrics(studentId);
});

/// 某学员饮食运动记录
final dailyLogListProvider =
    FutureProvider.family<List<DailyLog>, int>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listDailyLogs(studentId);
});
