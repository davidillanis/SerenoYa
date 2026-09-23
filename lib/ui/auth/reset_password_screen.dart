import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/reset_password_view_model.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_scaffold.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await context.read<ResetPasswordViewModel>().reset(
      email: _email.text,
      token: _token.text,
      password: _password.text,
      passwordConfirmation: _confirmation.text,
    );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada correctamente.')),
    );
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResetPasswordViewModel>();
    return AuthScaffold(
      title: 'Nueva contraseña',
      subtitle: 'Ingresa el código recibido y define una contraseña nueva.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _email,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AuthTextField(controller: _token, label: 'Código o token'),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _password,
            label: 'Nueva contraseña',
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
            Text(
              viewModel.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: viewModel.isLoading ? null : _submit,
            child: viewModel.isLoading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Text('Actualizar contraseña'),
          ),
        ],
      ),
    );
  }
}
