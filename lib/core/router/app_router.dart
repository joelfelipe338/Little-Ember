import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/plans/presentation/home_screen.dart';
import '../../features/plans/presentation/create_plan_screen.dart';
import '../../features/plans/presentation/plan_detail_screen.dart';
import '../../features/connections/presentation/connections_screen.dart';
import '../../features/connections/presentation/select_people_screen.dart';
import '../../features/plans/domain/invited_person.dart';
import '../../features/places/domain/place.dart';
import '../../features/places/presentation/map_picker_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
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
    // Link do site aberto no app: https://chamma.site/#/r/<slug> chega como "/#/r/<slug>".
    final fragment = state.uri.fragment;
    if (fragment.startsWith('/r/')) return fragment;

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
      builder: (context, state) => CreatePlanScreen(
        // Vem das Conexões com a galera já escolhida.
        initialConvidados: state.extra is List<InvitedPerson> ? state.extra! as List<InvitedPerson> : const [],
      ),
    ),

    // Escolher quem chamar pro rolê (vem das Conexões)
    GoRoute(
      path: '/connections/select',
      builder: (context, state) => SelectPeopleScreen(
        args: state.extra is SelectPeopleArgs ? state.extra! as SelectPeopleArgs : const SelectPeopleArgs(),
      ),
    ),

    // Assinatura (CHAMMA+)
    GoRoute(
      path: '/assinatura',
      builder: (context, state) => const SubscriptionScreen(),
    ),

    // Escolher o local no mapa (devolve um PlaceDraft com pop)
    GoRoute(
      path: '/map-picker',
      builder: (context, state) => MapPickerScreen(
        initial: state.extra is PlaceDraft ? state.extra! as PlaceDraft : null,
      ),
    ),

    // Editar perfil (tela cheia, sem nav bar)
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
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
