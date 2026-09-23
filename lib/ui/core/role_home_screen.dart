import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>().state.session;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<SessionViewModel>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Hola, ${session?.user.displayName ?? 'usuario'}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                'Tu rol es: ${session?.user.primaryRole?.name ?? 'rol'}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
