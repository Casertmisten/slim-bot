import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/students/pages/students_list_page.dart';
import '../../features/students/pages/student_detail_page.dart';
import '../../features/students/pages/student_edit_page.dart';
import '../../features/chat/chat_list_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/settings/settings_page.dart';
import '../../shared/widgets/app_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 主导航外壳：学员/对话/设置三个根页面共享底部导航或侧边栏。
      // 用 StatefulShellRoute 让外壳处在路由子树内，AppScaffold 可合法读取 GoRouterState。
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AppScaffold(shell: navigationShell),
        branches: [
          // 学员分支
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const StudentsListPage()),
              GoRoute(
                path: '/students/new',
                builder: (_, _) => const StudentEditPage(studentId: null),
              ),
              GoRoute(
                path: '/students/:id',
                builder: (_, state) =>
                    StudentDetailPage(id: int.parse(state.pathParameters['id']!)),
              ),
              GoRoute(
                path: '/students/:id/edit',
                builder: (_, state) => StudentEditPage(
                    studentId: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          // 对话分支
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/chat', builder: (_, _) => const ChatListPage()),
              GoRoute(
                path: '/chat/:sessionId',
                builder: (_, state) => ChatPage(
                    sessionId: int.parse(state.pathParameters['sessionId']!)),
              ),
            ],
          ),
          // 设置分支
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
            ],
          ),
        ],
      ),
    ],
  );
});
