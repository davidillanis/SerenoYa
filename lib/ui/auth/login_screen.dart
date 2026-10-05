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
    FocusScope.of(context).unfocus();
    await context.read<LoginViewModel>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    return AuthScaffold(
      showBrandHeader: true,
      title: 'Bienvenido a SerenoYa',
      subtitle: 'Ingresa para acceder al módulo asignado a tu cuenta.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              hintText: 'Ej. tucorreo@ejemplo.com',
              enabled: !viewModel.isLoading,
              autofillHints: const [AutofillHints.username],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hintText: 'Ingresa tu contraseña',
              enabled: !viewModel.isLoading,
              autofillHints: const [AutofillHints.password],
              obscureText: viewModel.obscurePassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip: viewModel.obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: viewModel.togglePasswordVisibility,
                icon: Icon(
                  viewModel.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () => context.push(RouteNames.forgotPassword),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: viewModel.isLoading ? null : _submit,
              child: viewModel.isLoading && !viewModel.isGoogleLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Iniciando sesión',
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined),
                        SizedBox(width: 12),
                        Flexible(child: Text('Iniciar sesión')),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
            if (viewModel.canLoginWithGoogle) ...[
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: viewModel.isLoading
                    ? null
                    : viewModel.loginWithGoogle,
                child: viewModel.isGoogleLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Iniciando sesión con Google',
                        ),
                      )
                    : const Text('Continuar con Google'),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              '¿Aún no tienes una cuenta?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: viewModel.isLoading
                  ? null
                  : () => context.push(RouteNames.register),
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text(
                'Crear cuenta de ciudadano',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
