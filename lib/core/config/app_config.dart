import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地配置：后端 URL + Bearer Token。
/// 首次使用需在设置页填写。
class AppConfig {
  AppConfig({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  bool get isConfigured => baseUrl.isNotEmpty && token.isNotEmpty;
}

/// 配置状态管理（持久化到 shared_preferences）
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(AppConfig(baseUrl: '', token: '')) {
    _load();
  }

  static const _keyBaseUrl = 'base_url';
  static const _keyToken = 'token';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppConfig(
      baseUrl: prefs.getString(_keyBaseUrl) ?? '',
      token: prefs.getString(_keyToken) ?? '',
    );
  }

  Future<void> save({required String baseUrl, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
    await prefs.setString(_keyToken, token);
    state = AppConfig(baseUrl: baseUrl, token: token);
  }
}

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>(
  (ref) => AppConfigNotifier(),
);
