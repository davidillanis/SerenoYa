import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/register_view_model.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_scaffold.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _phone,
      _email,
      _password,
      _confirmation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await context.read<RegisterViewModel>().register(
      firstName: _firstName.text,
      lastName: _lastName.text,
      phone: _phone.text,
      email: _email.text,
      password: _password.text,
      passwordConfirmation: _confirmation.text,
    );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta creada. Revisa tu correo.')),
    );
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();
    return AuthScaffold(
      title: 'Crear cuenta ciudadana',
      subtitle: 'Registra tus datos para reportar y seguir incidentes.',
      child: Column(
        children: [
          AuthTextField(controller: _firstName, label: 'Nombres (opcional)'),
          const SizedBox(height: 12),
          AuthTextField(controller: _lastName, label: 'Apellidos (opcional)'),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _phone,
            label: 'Celular',
            hintText: '987654321 o +51987654321',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _email,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _password,
            label: 'Contraseña',
            hintText: 'Mínimo 8 caracteres',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _confirmation,
            label: 'Confirmar contraseña',
            obscureText: true,
            onSubmitted: (_) => _submit(),
          ),
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                viewModel.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: viewModel.isLoading ? null : _submit,
              child: viewModel.isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Crear cuenta'),
            ),
          ),
          TextButton(
            onPressed: viewModel.isLoading ? null : () => context.pop(),
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      ),
    );
  }
}
