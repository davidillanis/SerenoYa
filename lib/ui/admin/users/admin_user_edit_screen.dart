import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_user_detail.dart';
import 'package:sereno_ya/data/models/admin/admin_user_update_request.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_user_edit_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AdminUserEditScreen extends StatefulWidget {
  const AdminUserEditScreen({super.key});

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _imageUrl = TextEditingController();

  String? _hydratedUserId;
  bool _enabled = true;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    for (final controller in [_name, _lastName, _phone, _imageUrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _hydrate(AdminUserDetail user) {
    if (_hydratedUserId == user.id) return;
    _hydratedUserId = user.id;
    _name.text = user.name;
    _lastName.text = user.lastName;
    _phone.text = user.phone ?? '';
    _imageUrl.text = user.imageUrl ?? '';
    _enabled = user.enabled;
    _notificationsEnabled = user.notificationsEnabled;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    final viewModel = context.read<AdminUserEditViewModel>();
    final user = viewModel.user;
    if (user == null) return;
    final request = AdminUserUpdateRequest(
      name: _changedText(_name.text, user.name),
      lastName: _changedText(_lastName.text, user.lastName),
      phone: _changedText(_phone.text, user.phone),
      imageUrl: _changedText(_imageUrl.text, user.imageUrl),
      enabled: _enabled == user.enabled ? null : _enabled,
      notificationsEnabled: _notificationsEnabled == user.notificationsEnabled
          ? null
          : _notificationsEnabled,
    );
    if (request.toJson().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }
    final updated = await viewModel.update(request);
    if (!mounted || !updated) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La información se actualizó correctamente.'),
      ),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUserEditViewModel>();
    final user = viewModel.user;
    if (viewModel.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar usuario')),
        body: _LoadError(
          message:
              viewModel.loadError ??
              'No se encontró la información del usuario.',
          onRetry: viewModel.load,
        ),
      );
    }
    _hydrate(user);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(title: const Text('Editar usuario')),
      body: ResponsiveBody(
        maxWidth: 980,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Información de la cuenta',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo se guardan los cambios. Deja un campo vacío para conservar su valor actual.',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                _FormSection(
                  title: 'Identidad y contacto',
                  subtitle: 'Información utilizada para identificar y contactar al usuario.',
                  icon: Icons.badge_outlined,
                  child: _FieldGrid(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nombres'),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _optionalLength(value, 60),
                      ),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _optionalLength(value, 60),
                      ),
                      TextFormField(
                        initialValue: user.email,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          helperText: 'Este dato no puede modificarse aquí.',
                        ),
                      ),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Celular',
                          hintText: '987654321 o +51987654321',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                      TextFormField(
                        controller: _imageUrl,
                        decoration: const InputDecoration(
                          labelText: 'URL de imagen',
                          helperText:
                              'Opcional. Debe comenzar con http:// o https://.',
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        validator: _validateImageUrl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Estado de la cuenta',
                  subtitle:
                      'Controla el acceso y la recepción de notificaciones.',
                  icon: Icons.admin_panel_settings_outlined,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cuenta activa'),
                        subtitle: const Text(
                          'Permite que el usuario acceda al sistema.',
                        ),
                        value: _enabled,
                        onChanged: viewModel.isSubmitting
                            ? null
                            : (value) => setState(() => _enabled = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notificaciones activadas'),
                        subtitle: const Text(
                          'Permite el envío de avisos relacionados con su cuenta.',
                        ),
                        value: _notificationsEnabled,
                        onChanged: viewModel.isSubmitting
                            ? null
                            : (value) =>
                                  setState(() => _notificationsEnabled = value),
                      ),
                    ],
                  ),
                ),
                if (viewModel.submitError != null) ...[
                  const SizedBox(height: 16),
                  _SubmissionError(message: viewModel.submitError!),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: viewModel.isSubmitting
                            ? null
                            : () => context.pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton.icon(
                        onPressed: viewModel.isSubmitting ? null : _submit,
                        icon: viewModel.isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          viewModel.isSubmitting
                              ? 'Guardando…'
                              : 'Guardar cambios',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: context.appColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _SubmissionError extends StatelessWidget {
  const _SubmissionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: context.appColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: context.appColors.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String? _optionalLength(String? value, int max) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return text.length <= max ? null : 'No debe superar los $max caracteres.';
}

String? _validatePhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return RegExp(r'^(?:\+51)?9[0-9]{8}$').hasMatch(text)
      ? null
      : 'Ingresa 9 dígitos comenzando con 9; puedes incluir +51, sin espacios.';
}

String? _validateImageUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty
      ? null
      : 'Ingresa una URL válida.';
}

String? _changedText(String value, String? current) {
  final text = value.trim();
  return text.isEmpty || text == current ? null : text;
}
