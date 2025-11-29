import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/attendance/screens/attendance_list_screen.dart';
import 'features/attendance/screens/attendance_detail_screen.dart';
import 'features/attendance/screens/attendance_add_screen.dart';
import 'features/attendance/screens/attendance_edit_screen.dart';
import 'features/schedule/screens/schedule_screen.dart';
import 'features/schedule/screens/match_detail_screen.dart';
import 'features/schedule/screens/player_detail_screen.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/standings/screens/standings_screen.dart';
import 'features/team/screens/team_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/profile_edit_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';

      // 로그인하지 않은 경우 로그인 페이지로 리다이렉트
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 이미 로그인한 경우 로그인 페이지 접근 시 홈으로 리다이렉트
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Match Detail (outside shell - full screen)
      GoRoute(
        path: '/match/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return MatchDetailScreen(eventId: eventId);
        },
      ),

      // Player Detail (outside shell - full screen)
      GoRoute(
        path: '/player/:playerId',
        builder: (context, state) {
          final playerId = state.pathParameters['playerId']!;
          return PlayerDetailScreen(playerId: playerId);
        },
      ),

      // Team Detail (outside shell - full screen)
      GoRoute(
        path: '/team/:teamId',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return TeamDetailScreen(teamId: teamId);
        },
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home (Dashboard)
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Schedule
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),

          // Attendance (직관 일기)
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AttendanceAddScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AttendanceDetailScreen(recordId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AttendanceEditScreen(recordId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Standings (리그 순위)
          GoRoute(
            path: '/standings',
            builder: (context, state) => const StandingsScreen(),
          ),

          // Favorites (즐겨찾기 - 프로필에서 접근)
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),

          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const ProfileEditScreen(),
              ),
            ],
          ),

          // Diary routes redirect to attendance (backwards compatibility)
          GoRoute(
            path: '/diary',
            redirect: (context, state) => '/attendance',
          ),
          GoRoute(
            path: '/diary/add',
            redirect: (context, state) => '/attendance/add',
          ),
        ],
      ),
    ],
  );
});

// Main Shell with Bottom Navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: '직관 일기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: '순위',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/attendance')) return 2;
    if (location.startsWith('/standings')) return 3;
    if (location.startsWith('/profile')) return 4;

    return 0; // Default to home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/schedule');
        break;
      case 2:
        context.go('/attendance');
        break;
      case 3:
        context.go('/standings');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
