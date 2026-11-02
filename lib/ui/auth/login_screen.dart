import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/login_view_model.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_scaffold.dart';
import 'package:sereno_ya/ui/auth/widgets/auth_text_field.dart';

const _previewProductionAuth = bool.fromEnvironment(
  'PREVIEW_PRODUCTION_AUTH',
  defaultValue: false,
);
const _showDeveloperAccessByDefault = kDebugMode && !_previewProductionAuth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.showDeveloperAccess = _showDeveloperAccessByDefault,
  });

  /// Mantiene las credenciales disponibles en desarrollo sin exponerlas en
  /// compilaciones release.
  final bool showDeveloperAccess;

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
      centerContent: !widget.showDeveloperAccess,
      title: 'Ingresa a SerenoYa',
      subtitle: 'Continúa con Google para ingresar o crear tu cuenta.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoogleAccess(viewModel: viewModel),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            if (widget.showDeveloperAccess) ...[
              const SizedBox(height: 28),
              _DeveloperAccess(
                emailController: _emailController,
                passwordController: _passwordController,
                viewModel: viewModel,
                onSubmit: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoogleAccess extends StatelessWidget {
  const _GoogleAccess({required this.viewModel});

  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!viewModel.canLoginWithGoogle) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Text(
          'El acceso con Google no está disponible en este dispositivo.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: colors.onSurface,
            backgroundColor: colors.surface,
            side: BorderSide(color: colors.outline),
          ),
          onPressed: viewModel.isLoading ? null : viewModel.loginWithGoogle,
          icon: viewModel.isGoogleLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Iniciando sesión con Google',
                  ),
                )
              : SvgPicture.asset(
                  'assets/icon/google_g.svg',
                  width: 20,
                  height: 20,
                ),
          label: Text(
            viewModel.isGoogleLoading
                ? 'Conectando con Google'
                : 'Continuar con Google',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Si es tu primera vez, podrás crear tu cuenta con el mismo acceso.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DeveloperAccess extends StatelessWidget {
  const _DeveloperAccess({
    required this.emailController,
    required this.passwordController,
    required this.viewModel,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final LoginViewModel viewModel;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'ACCESO DE DESARROLLO',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Credenciales disponibles solo para pruebas internas.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: emailController,
          label: 'Correo electrónico',
          hintText: 'Ej. tucorreo@ejemplo.com',
          enabled: !viewModel.isLoading,
          autofillHints: const [AutofillHints.username],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: passwordController,
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
          onSubmitted: (_) => onSubmit(),
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
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: viewModel.isLoading ? null : onSubmit,
          child: viewModel.isLoading && !viewModel.isGoogleLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Iniciando sesión',
                  ),
                )
              : const Text('Iniciar con credenciales'),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: viewModel.isLoading
              ? null
              : () => context.push(RouteNames.register),
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text(
            'Crear cuenta de prueba',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
