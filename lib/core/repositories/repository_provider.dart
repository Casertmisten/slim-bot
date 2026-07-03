import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'repository.dart';
import 'http_repository.dart';
import 'mock_repository.dart';

/// Repository 全局 provider。
/// - 开发期（ApiClient 未配置）→ MockRepository
/// - 对接期（ApiClient 已配置）→ HttpRepository
final repositoryProvider = Provider<Repository>((ref) {
  final client = ref.watch(apiClientProvider);
  return client == null ? MockRepository() : HttpRepository(client);
});
