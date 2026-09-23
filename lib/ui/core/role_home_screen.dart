import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onFabPressed,
    this.fabIcon,
    this.fabLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onFabPressed;
  final IconData? fabIcon;
  final String? fabLabel;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>().state.session;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(204),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido(a),\n${session?.user.displayName ?? 'usuario'}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: onFabPressed != null && fabIcon != null
          ? FloatingActionButton.extended(
              onPressed: onFabPressed,
              icon: Icon(fabIcon),
              label: Text(fabLabel ?? ''),
            )
          : null,
    );
  }
}
