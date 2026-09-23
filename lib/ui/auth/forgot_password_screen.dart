import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/forgot_password_view_model.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_scaffold.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await context.read<ForgotPasswordViewModel>().send(
      _email.text,
    );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Revisa tu correo, incluido spam.')),
    );
    final uri = Uri(
      path: RouteNames.resetPassword,
      queryParameters: {'email': _email.text.trim()},
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();
    return AuthScaffold(
      title: 'Recuperar contraseña',
      subtitle: 'Te enviaremos las instrucciones al correo registrado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _email,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
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
                : const Text('Enviar instrucciones'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
