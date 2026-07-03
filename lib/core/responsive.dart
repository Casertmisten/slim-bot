import 'package:flutter/material.dart';

/// 响应式断点：手机 / Web 适配。
/// ≥900px 视为宽屏（Web/平板），用侧边栏导航；
/// <900px 用底部导航。
class Breakpoint {
  static const double desktop = 900;

  /// 当前是否宽屏
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// 容器最大宽度
  static const double containerMax = 1280;

  /// 桌面端内容水平边距
  static const double marginDesktop = 40;
  static const double marginMobile = 16;
}

/// 根据屏幕宽度返回合适的水平内容边距
double contentMargin(BuildContext context) => Breakpoint.isDesktop(context)
    ? Breakpoint.marginDesktop
    : Breakpoint.marginMobile;
