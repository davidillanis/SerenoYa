import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gpp_bad_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso no autorizado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'La cuenta no tiene un rol válido para los módulos de SerenoYa.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () => context.read<SessionViewModel>().logout(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
