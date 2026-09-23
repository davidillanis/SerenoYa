import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>().state.session;
    return Drawer(
      child: Column(
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
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Rol actual'),
            subtitle: Text(
              session?.user.primaryRole?.name ?? 'Sin rol asignado',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
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
    );
  }
}
