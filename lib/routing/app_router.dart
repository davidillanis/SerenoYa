import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/routing/auth_router_notifier.dart';
import 'package:sereno_ya/routing/role_route_resolver.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/forgot_password_screen.dart';
import 'package:sereno_ya/ui/auth/login_screen.dart';
import 'package:sereno_ya/ui/auth/register_screen.dart';
import 'package:sereno_ya/ui/auth/reset_password_screen.dart';
import 'package:sereno_ya/ui/auth/session_gate_screen.dart';
import 'package:sereno_ya/ui/auth/view_models/forgot_password_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/login_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/register_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/reset_password_view_model.dart';
import 'package:sereno_ya/ui/core/role_home_screen.dart';
import 'package:sereno_ya/ui/core/unauthorized_screen.dart';

GoRouter createAppRouter({
  required AuthRepository authRepository,
  required AuthRouterNotifier routerNotifier,
}) {
  const publicRoutes = {
    RouteNames.login,
    RouteNames.register,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
  };

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = authRepository.state;
      final location = state.matchedLocation;

      if (authState.status == AuthStatus.unknown) {
        return location == RouteNames.splash ? null : RouteNames.splash;
      }
      if (authState.status == AuthStatus.authenticating) {
        return location == RouteNames.login ? null : RouteNames.splash;
      }
      if (authState.status == AuthStatus.refreshing) return null;
      if (!authState.isAuthenticated) {
        return publicRoutes.contains(location) ? null : RouteNames.login;
      }

      final role = authState.session?.user.primaryRole;
      final roleRoute = RoleRouteResolver.routeFor(role);
      if (location == RouteNames.splash || publicRoutes.contains(location)) {
        return roleRoute;
      }
      if (location == RouteNames.unauthorized) {
        return role == null ? null : roleRoute;
      }
      if (role == null || !RoleRouteResolver.canAccess(location, role)) {
        return roleRoute;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, _) => const SessionGateScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, _) => ChangeNotifierProvider(
          create: (_) => LoginViewModel(authRepository),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, _) => ChangeNotifierProvider(
          create: (_) => RegisterViewModel(authRepository),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, _) => ChangeNotifierProvider(
          create: (_) => ForgotPasswordViewModel(authRepository),
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (_, state) => ChangeNotifierProvider(
          create: (_) => ResetPasswordViewModel(authRepository),
          child: ResetPasswordScreen(
            initialEmail: state.uri.queryParameters['email'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.citizen,
        builder: (_, _) => const RoleHomeScreen(
          title: 'Ciudadano',
          description: 'Desde aquí podrás reportar y seguir incidentes.',
          icon: Icons.person_pin_circle_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.officer,
        builder: (_, _) => const RoleHomeScreen(
          title: 'Serenazgo',
          description:
              'Desde aquí recibirás y atenderás incidentes de tu zona.',
          icon: Icons.local_police_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (_, _) => const RoleHomeScreen(
          title: 'Administración',
          description: 'Gestión de usuarios, zonas e incidentes.',
          icon: Icons.admin_panel_settings_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.dev,
        builder: (_, _) => const RoleHomeScreen(
          title: 'Herramientas de desarrollo',
          description: 'Diagnóstico y herramientas internas de SerenoYa.',
          icon: Icons.developer_mode_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.unauthorized,
        builder: (_, _) => const UnauthorizedScreen(),
      ),
    ],
  );
}
