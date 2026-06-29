import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/prisoners/prisoners_screen.dart';
import '../../presentation/screens/prisoners/prisoner_form_screen.dart';
import '../../presentation/screens/prisoners/prisoner_detail_screen.dart';
import '../../presentation/screens/admitted/admitted_screen.dart';
import '../../presentation/screens/released/released_screen.dart';
import '../../presentation/screens/ipc_lookup/ipc_lookup_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/users/users_screen.dart';
import '../../presentation/screens/users/user_form_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/widgets/navigation/app_shell.dart';

// ── Route names ─────────────────────────────────────────────────────────────
class Routes {
  static const String login          = '/login';
  static const String dashboard      = '/dashboard';
  static const String prisoners      = '/prisoners';
  static const String prisonerAdd    = '/prisoners/add';
  static const String prisonerEdit   = '/prisoners/:id/edit';
  static const String prisonerDetail = '/prisoners/:id';
  static const String admitted       = '/admitted';
  static const String released       = '/released';
  static const String ipcLookup      = '/ipc-lookup';
  static const String reports        = '/reports';
  static const String users          = '/users';
  static const String userAdd        = '/users/add';
  static const String userEdit       = '/users/:id/edit';
  static const String settings       = '/settings';
}

// ── Router provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).value != null;
      final isLoginRoute = state.matchedLocation == Routes.login;

      if (!isLoggedIn && !isLoginRoute) return Routes.login;
      if (isLoggedIn && isLoginRoute) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: Routes.dashboard,  builder: (_, __) => const DashboardScreen()),
          GoRoute(path: Routes.prisoners,  builder: (_, __) => const PrisonersScreen()),
          GoRoute(path: Routes.prisonerAdd, builder: (_, __) => const PrisonerFormScreen()),
          GoRoute(
            path: Routes.prisonerEdit,
            builder: (_, state) => PrisonerFormScreen(prisonerId: state.pathParameters['id']),
          ),
          GoRoute(
            path: Routes.prisonerDetail,
            builder: (_, state) => PrisonerDetailScreen(prisonerId: state.pathParameters['id']!),
          ),
          GoRoute(path: Routes.admitted,   builder: (_, __) => const AdmittedScreen()),
          GoRoute(path: Routes.released,   builder: (_, __) => const ReleasedScreen()),
          GoRoute(path: Routes.ipcLookup,  builder: (_, __) => const IpcLookupScreen()),
          GoRoute(path: Routes.reports,    builder: (_, __) => const ReportsScreen()),
          GoRoute(path: Routes.users,      builder: (_, __) => const UsersScreen()),
          GoRoute(path: Routes.userAdd,    builder: (_, __) => const UserFormScreen()),
          GoRoute(
            path: Routes.userEdit,
            builder: (_, state) => UserFormScreen(userId: state.pathParameters['id']),
          ),
          GoRoute(path: Routes.settings,   builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

/// Bridges Stream<T> → ChangeNotifier for GoRouter.refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
