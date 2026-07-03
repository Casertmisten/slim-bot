import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slim_bot/core/theme/app_theme.dart';
import 'package:slim_bot/core/theme/app_colors.dart';

void main() {
  test('主题主色为活力绿', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  test('卡片为白底 1px 描边 16 圆角', () {
    final theme = AppTheme.light;
    final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
    expect(theme.cardTheme.color, AppColors.surfaceContainerLowest);
    expect(cardShape.side.width, 1);
    expect(cardShape.borderRadius, BorderRadius.circular(16));
  });
}
