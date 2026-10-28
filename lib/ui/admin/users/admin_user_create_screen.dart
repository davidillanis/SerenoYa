import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_user_create_request.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_user_create_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AdminUserCreateScreen extends StatefulWidget {
  const AdminUserCreateScreen({super.key});

  @override
  State<AdminUserCreateScreen> createState() => _AdminUserCreateScreenState();
}

class _AdminUserCreateScreenState extends State<AdminUserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  AdminAssignableRole _selectedRole = AdminAssignableRole.officer;
  bool _obscurePassword = true;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _phone,
      _email,
      _password,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;

    final requiresLocation = _selectedRole.requiresLocation;
    final request = AdminUserCreateRequest(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _selectedRole,
      latitude: requiresLocation ? double.parse(_latitude.text.trim()) : null,
      longitude: requiresLocation ? double.parse(_longitude.text.trim()) : null,
    );
    final created = await context.read<AdminUserCreateViewModel>().createUser(
      request,
    );
    if (!mounted || created == null) return;

    final name = created.displayName.isNotEmpty
        ? created.displayName
        : request.firstName.isNotEmpty
        ? request.firstName
        : request.email;
    final code = created.serenoCode;
    final detail = code == null || code.isEmpty ? '' : ' Código: $code.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name fue registrado como ${_selectedRole.label.toLowerCase()}.$detail',
        ),
      ),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUserCreateViewModel>();
    final currentRoles =
        context.watch<SessionViewModel>().state.session?.user.roles ??
        const <UserRole>[];
    final assignableRoles = currentRoles.contains(UserRole.developer)
        ? AdminAssignableRole.values
        : const [AdminAssignableRole.officer, AdminAssignableRole.citizen];
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(title: const Text('Registrar usuario')),
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
                  'Nueva cuenta de usuario',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra la identidad, las credenciales y el rol que tendrá en el sistema.',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                _FormSection(
                  title: 'Información personal',
                  subtitle: 'Nombre y celular del nuevo usuario.',
                  icon: Icons.badge_outlined,
                  child: _FieldGrid(
                    children: [
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          labelText: 'Nombres (opcional)',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: _validateName,
                      ),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos (opcional)',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: _validateName,
                      ),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Celular',
                          hintText: '987654321 o +51987654321',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          return RegExp(r'^(?:\+51)?9[0-9]{8}$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Ingresa 9 dígitos comenzando con 9; puedes incluir +51, sin espacios.';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Acceso al sistema',
                  subtitle: 'Credenciales personales para acceder al sistema.',
                  icon: Icons.lock_outline,
                  child: _FieldGrid(
                    children: [
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: _validateEmail,
                      ),
                      TextFormField(
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: 'Contraseña temporal',
                          helperText: 'Mínimo 8 caracteres.',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) => (value?.length ?? 0) >= 8
                            ? null
                            : 'La contraseña debe tener al menos 8 caracteres.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Rol y perfil',
                  subtitle: _selectedRole.sectionDescription,
                  icon: Icons.admin_panel_settings_outlined,
                  child: _FieldGrid(
                    children: [
                      DropdownButtonFormField<AdminAssignableRole>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Rol asignado',
                        ),
                        items: [
                          for (final role in assignableRoles)
                            DropdownMenuItem(
                              value: role,
                              child: Text(role.label),
                            ),
                        ],
                        onChanged: viewModel.isSubmitting
                            ? null
                            : (role) {
                                if (role == null) return;
                                setState(() => _selectedRole = role);
                              },
                      ),
                      if (_selectedRole == AdminAssignableRole.officer)
                        const _GeneratedCodeField(),
                      if (_selectedRole.requiresLocation)
                        TextFormField(
                          controller: _latitude,
                          decoration: InputDecoration(
                            labelText:
                                _selectedRole == AdminAssignableRole.officer
                                ? 'Latitud operativa inicial'
                                : 'Latitud del domicilio',
                            hintText: '-13.6512',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: [_decimalFormatter],
                          validator: (value) => _validateCoordinate(
                            value,
                            min: -90,
                            max: 90,
                            name: 'latitud',
                          ),
                        ),
                      if (_selectedRole.requiresLocation)
                        TextFormField(
                          controller: _longitude,
                          decoration: InputDecoration(
                            labelText:
                                _selectedRole == AdminAssignableRole.officer
                                ? 'Longitud operativa inicial'
                                : 'Longitud del domicilio',
                            hintText: '-71.6778',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: [_decimalFormatter],
                          validator: (value) => _validateCoordinate(
                            value,
                            min: -180,
                            max: 180,
                            name: 'longitud',
                          ),
                        ),
                    ],
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _SubmissionError(message: viewModel.errorMessage!),
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
                            : const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(
                          viewModel.isSubmitting
                              ? 'Registrando…'
                              : 'Registrar usuario',
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

class _GeneratedCodeField extends StatelessWidget {
  const _GeneratedCodeField();

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Código de sereno'),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 20,
            color: context.appColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Se generará automáticamente al registrar'),
          ),
        ],
      ),
    );
  }
}

extension on AdminAssignableRole {
  String get label => switch (this) {
    AdminAssignableRole.citizen => 'Ciudadano',
    AdminAssignableRole.officer => 'Serenazgo',
    AdminAssignableRole.administrator => 'Administrador',
    AdminAssignableRole.developer => 'Desarrollo',
  };

  String get sectionDescription => switch (this) {
    AdminAssignableRole.citizen =>
      'La ubicación se guardará como domicilio inicial del ciudadano.',
    AdminAssignableRole.officer => 'El código se generará en el servidor. Registra la ubicación operativa inicial.',
    AdminAssignableRole.administrator =>
      'La cuenta tendrá acceso al panel de administración.',
    AdminAssignableRole.developer =>
      'La cuenta tendrá acceso técnico completo al sistema.',
  };
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

final _decimalFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^-?\d{0,3}([.]\d{0,6})?'),
);

String? _validateName(String? value) => (value?.trim().length ?? 0) > 60
    ? 'No debe superar los 60 caracteres.'
    : null;

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.length > 60) {
    return 'El correo electrónico no debe superar los 60 caracteres.';
  }
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Ingresa un correo válido.';
}

String? _validateCoordinate(
  String? value, {
  required double min,
  required double max,
  required String name,
}) {
  final coordinate = double.tryParse(value?.trim() ?? '');
  if (coordinate == null) return 'Ingresa una $name válida.';
  if (coordinate < min || coordinate > max) {
    return 'La $name debe estar entre $min y $max.';
  }
  return null;
}
