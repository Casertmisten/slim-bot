import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// 统一封装：baseURL、Bearer Token、错误处理。
class ApiClient {
  ApiClient(this._config) {
    _dio = Dio(BaseOptions(
      baseUrl: '${_config.baseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        if (_config.token.isNotEmpty) 'Authorization': 'Bearer ${_config.token}',
      },
    ));
  }

  final AppConfig _config;
  late final Dio _dio;

  Dio get dio => _dio;
}

/// 提供给 Repository 使用的 dio 实例 provider
final apiClientProvider = Provider<ApiClient?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.isConfigured) return null;
  return ApiClient(config);
});
