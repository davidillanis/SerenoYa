import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  final _dni = TextEditingController();
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _imageUrl = TextEditingController();

  String? _hydratedUserId;
  DateTime? _selectedBirthDate;
  bool _enabled = true;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _lastName,
      _dni,
      _phone,
      _birthDate,
      _address,
      _imageUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _hydrate(AdminUserDetail user) {
    if (_hydratedUserId == user.id) return;
    _hydratedUserId = user.id;
    _name.text = user.name;
    _lastName.text = user.lastName;
    _dni.text = user.dni;
    _phone.text = user.phone ?? '';
    _selectedBirthDate = user.birthDate;
    _birthDate.text = user.birthDate == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(user.birthDate!);
    _address.text = user.address;
    _imageUrl.text = user.imageUrl ?? '';
    _enabled = user.enabled;
    _notificationsEnabled = user.notificationsEnabled;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1)),
      helpText: 'Fecha de nacimiento',
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectedBirthDate = selected;
      _birthDate.text = DateFormat('dd/MM/yyyy').format(selected);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    final updated = await context.read<AdminUserEditViewModel>().update(
      AdminUserUpdateRequest(
        name: _name.text,
        lastName: _lastName.text,
        dni: _dni.text,
        phone: _phone.text,
        birthDate: _selectedBirthDate,
        address: _address.text,
        imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text,
        enabled: _enabled,
        notificationsEnabled: _notificationsEnabled,
      ),
    );
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
                  'Actualiza los datos permitidos. Los roles se administran por separado.',
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
                        controller: _dni,
                        decoration: const InputDecoration(labelText: 'DNI'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        validator: _validateDni,
                      ),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixText: '+51 ',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        validator: _validatePhone,
                      ),
                      TextFormField(
                        controller: _birthDate,
                        readOnly: true,
                        onTap: viewModel.isSubmitting ? null : _pickBirthDate,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _optionalLength(value, 250),
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

String? _validateDni(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return RegExp(r'^\d{8}$').hasMatch(text)
      ? null
      : 'Ingresa un DNI de 8 dígitos.';
}

String? _validatePhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return RegExp(r'^9\d{8}$').hasMatch(text)
      ? null
      : 'Debe comenzar con 9 y tener 9 dígitos.';
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
