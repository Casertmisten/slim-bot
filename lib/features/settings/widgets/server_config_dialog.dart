import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';

/// 配置后端 URL + Token 的对话框
class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late final _url = TextEditingController();
  late final _token = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(appConfigProvider);
    _url.text = cfg.baseUrl;
    _token.text = cfg.token;
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('服务器配置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            decoration: const InputDecoration(labelText: '后端地址', hintText: 'https://your-server.com'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _token,
            decoration: const InputDecoration(labelText: '访问令牌'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            ref.read(appConfigProvider.notifier).save(
                  baseUrl: _url.text.trim(),
                  token: _token.text.trim(),
                );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
