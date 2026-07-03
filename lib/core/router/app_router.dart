import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/students/pages/students_list_page.dart';
import '../../features/students/pages/student_detail_page.dart';
import '../../features/students/pages/student_edit_page.dart';
import '../../features/chat/chat_list_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/settings/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
        builder: (_, state) =>
            StudentEditPage(studentId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/chat', builder: (_, _) => const ChatListPage()),
      GoRoute(
        path: '/chat/:sessionId',
        builder: (_, state) => ChatPage(
            sessionId: int.parse(state.pathParameters['sessionId']!)),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    ],
  );
});
