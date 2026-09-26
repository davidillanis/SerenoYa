import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/routing/role_route_resolver.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>().state.session;
    return Drawer(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                session?.user.displayName ?? 'Usuario',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(session?.user.email ?? 'Sin correo'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text(
                  (session?.user.displayName.isNotEmpty == true)
                      ? session!.user.displayName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            if (session != null && session.user.roles.length > 1) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Tus interfaces',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
              ...session.user.roles.map((role) {
                final isCurrent = GoRouterState.of(context).matchedLocation
                    .startsWith(RoleRouteResolver.routeFor(role));
                return ListTile(
                  leading: Icon(
                    _getRoleIcon(role),
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    _getRoleName(role),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : null,
                    ),
                  ),
                  selected: isCurrent,
                  onTap: () {
                    context.pop();
                    if (!isCurrent) {
                      context.go(RoleRouteResolver.routeFor(role));
                    }
                  },
                );
              }),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Rol asignado'),
                subtitle: Text(
                  session?.user.primaryRole != null
                      ? _getRoleName(session!.user.primaryRole!)
                      : 'Sin rol asignado',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mi perfil'),
              subtitle: const Text('Datos de tu cuenta y tema'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push(RouteNames.profile);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => context.read<SessionViewModel>().logout(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

String _getRoleName(UserRole role) => switch (role) {
  UserRole.citizen => 'Ciudadano',
  UserRole.officer => 'Serenazgo',
  UserRole.administrator => 'Administrador',
  UserRole.developer => 'Desarrollador',
};

IconData _getRoleIcon(UserRole role) => switch (role) {
  UserRole.citizen => Icons.person_outline,
  UserRole.officer => Icons.local_police_outlined,
  UserRole.administrator => Icons.admin_panel_settings_outlined,
  UserRole.developer => Icons.developer_mode_outlined,
};
