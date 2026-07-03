import 'package:flutter/material.dart';

/// 设计令牌，来自 DESIGN.md「Vitality Logic」配色。
/// 高对比浅色主题，主色活力绿。
class AppColors {
  AppColors._();

  // 表面层
  static const surface = Color(0xFFF8FAF8); // 页面背景
  static const surfaceContainerLowest = Color(0xFFFFFFFF); // 卡片
  static const surfaceContainerLow = Color(0xFFF2F4F2);
  static const surfaceContainer = Color(0xFFECEEEC);

  // 文本
  static const onSurface = Color(0xFF191C1B);
  static const onSurfaceVariant = Color(0xFF40493D);
  static const outline = Color(0xFFBFCAB9); // 卡片/输入描边
  static const outlineVariant = Color(0xFFE0E4E0);

  // 品牌色
  static const primary = Color(0xFF0B6B1D); // 主操作
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2E8534);
  static const tertiary = Color(0xFF276929); // 深森林绿（高对比文本）

  // 错误
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
}
