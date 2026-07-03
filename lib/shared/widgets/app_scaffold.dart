import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';

/// 主导航项
class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}

const _navItems = [
  _NavItem('/', Icons.people_outline, '学员'),
  _NavItem('/chat', Icons.chat_bubble_outline, '对话'),
  _NavItem('/settings', Icons.settings_outlined, '设置'),
];

/// 响应式外壳：手机用底部导航，宽屏用左侧侧边栏。
class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = Breakpoint.isDesktop(context);

    // 仅在主导航根路径显示外壳
    final showShell = _navItems.any((n) => location == n.path);

    if (!showShell) {
      return Scaffold(body: child);
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(location: location),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: _MobileNavBar(location: location),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final String location;
  const _DesktopSidebar({required this.location});

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
          for (final item in _navItems)
            _NavTile(item: item, selected: location == item.path),
        ],
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  final String location;
  const _MobileNavBar({required this.location});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _navItems.indexWhere((n) => location == n.path),
      onDestinationSelected: (i) => GoRouter.of(context).go(_navItems[i].path),
      destinations: [
        for (final item in _navItems)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _NavTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.label),
      selected: selected,
      onTap: () => GoRouter.of(context).go(item.path),
    );
  }
}
