import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_scaffold.dart';

void main() {
  runApp(const ProviderScope(child: SlimCoachApp()));
}

class SlimCoachApp extends ConsumerWidget {
  const SlimCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '减肥教练助手',
      theme: AppTheme.light,
      routerConfig: router,
      builder: (_, child) => AppScaffold(child: child!),
    );
  }
}
