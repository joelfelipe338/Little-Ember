import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/plans/presentation/home_screen.dart';
import '../../features/plans/presentation/create_plan_screen.dart';
import '../../features/connections/presentation/connections_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../supabase/supabase_client.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final session = supabase.auth.currentSession;
    final isLoggedIn = session != null;
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  refreshListenable: _GoRouterAuthNotifier(),
  routes: [
    // Auth routes (sem shell)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // Criar rolê (tela cheia, sem nav bar)
    GoRoute(
      path: '/create-plan',
      builder: (context, state) => const CreatePlanScreen(),
    ),

    // App routes (com shell de navegação)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(
        currentIndex: navigationShell.currentIndex,
        onTabChanged: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        child: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/connections',
              builder: (context, state) => const ConnectionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier() {
    supabase.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}
