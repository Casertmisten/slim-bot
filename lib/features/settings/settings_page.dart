import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import 'widgets/server_config_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final client = ref.watch(apiClientProvider);
    final useMock = client == null;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('服务器配置'),
            subtitle: Text(useMock
                ? '未配置（当前使用本地 Mock 数据）'
                : '已连接：${config.baseUrl}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ServerConfigDialog(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('检查更新'),
            subtitle: const Text('后端版本与 APP 更新'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUpdateInfo(context, client),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('减肥教练助手 v0.1.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateInfo(BuildContext context, ApiClient? client) async {
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置后端地址')),
      );
      return;
    }
    // 调用后端 /admin/version
    try {
      final r = await client.dio.get('/admin/version');
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('版本信息'),
          content: Text('后端版本：${r.data['commit']}\n时间：${r.data['time']}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('查询失败：$e')));
    }
  }
}
