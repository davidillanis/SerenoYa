import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/login_view_model.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_scaffold.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<LoginViewModel>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    return AuthScaffold(
      title: 'Bienvenido a SerenoYa',
      subtitle: 'Ingresa para acceder al módulo asignado a tu cuenta.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Contraseña',
              obscureText: viewModel.obscurePassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: viewModel.togglePasswordVisibility,
                icon: Icon(
                  viewModel.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: viewModel.isLoading ? null : _submit,
              child: viewModel.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Iniciar sesión'),
            ),
            TextButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => context.push(RouteNames.forgotPassword),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
            const Divider(height: 28),
            OutlinedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => context.push(RouteNames.register),
              child: const Text('Crear cuenta de ciudadano'),
            ),
          ],
        ),
      ),
    );
  }
}
