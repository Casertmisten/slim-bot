// 复现启动崩溃的冒烟测试：渲染整个 SlimCoachApp，验证首帧渲染与导航外壳
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slim_bot/main.dart';

void main() {
  testWidgets('SlimCoachApp 能启动并渲染首页外壳', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SlimCoachApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
    // 初始路由 / 应显示学员列表页内容
    expect(find.text('学员'), findsWidgets);
  });
}

