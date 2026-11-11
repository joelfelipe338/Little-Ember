import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/plans/presentation/home_screen.dart';
import '../../features/plans/presentation/create_plan_screen.dart';
import '../../features/plans/presentation/plan_detail_screen.dart';
import '../../features/connections/presentation/connections_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/guest/guest_plan_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../supabase/supabase_client.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    // A splash animada decide sozinha para onde ir quando termina.
    if (state.matchedLocation == '/splash') return null;
    // Página do convidado (link web): pública, com ou sem sessão.
    if (state.matchedLocation.startsWith('/r/')) return null;

    // Sessão anônima é só do convidado no navegador: não conta como login.
    final isLoggedIn = isRealUserSession();
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  refreshListenable: _GoRouterAuthNotifier(),
  routes: [
    // Splash animada (abre o app)
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
    ),

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

    // Página do convidado: link compartilhado `/#/r/<slug>`
    GoRoute(
      path: '/r/:slug',
      builder: (context, state) => GuestPlanScreen(slug: state.pathParameters['slug']!),
    ),

    // Painel do rolê (tela cheia, sem nav bar)
    GoRoute(
      path: '/plan/:id',
      builder: (context, state) => PlanDetailScreen(planId: state.pathParameters['id']!),
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
