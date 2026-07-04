import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';

/// 主导航项
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.people_outline, '学员'),
  _NavItem(Icons.chat_bubble_outline, '对话'),
  _NavItem(Icons.settings_outlined, '设置'),
];

/// 响应式外壳：手机用底部导航，宽屏用左侧侧边栏。
///
/// 通过 StatefulShellRoute 接入，外壳处在路由子树内，
/// 导航跳转走 navigationShell.goBranch，保留各分支的页面栈状态。
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const AppScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoint.isDesktop(context);
    final currentIndex = shell.currentIndex;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: currentIndex,
              onTap: (i) => shell.goBranch(i, initialLocation: i == currentIndex),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == currentIndex),
        destinations: [
          for (final item in _navItems)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;
  const _DesktopSidebar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('减肥教练助手',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < _navItems.length; i++)
            ListTile(
              leading: Icon(_navItems[i].icon),
              title: Text(_navItems[i].label),
              selected: i == selectedIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}
