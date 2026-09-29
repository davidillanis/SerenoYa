import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/profile/citizen_profile.dart';
import 'package:sereno_ya/data/models/profile/user_profile.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:sereno_ya/ui/profile/view_models/profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingTheme = false;
  String? _themeError;

  Future<void> _changeTheme(ThemeVariant? variant) async {
    if (variant == null || _savingTheme) return;
    setState(() {
      _savingTheme = true;
      _themeError = null;
    });
    try {
      await context.read<ThemeController>().setVariant(variant);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _themeError =
            'No se pudo guardar el tema. Toca la opción para reintentar.';
      });
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  Future<void> _openEditor(ProfileViewModel viewModel) async {
    final user = viewModel.userProfile;
    if (user == null) return;
    viewModel.clearMessages();
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.appColors.modal,
      builder: (_) => ChangeNotifierProvider<ProfileViewModel>.value(
        value: viewModel,
        child: _ProfileEditSheet(
          user: user,
          citizen: viewModel.citizenProfile,
          includeCitizenProfile: viewModel.includeCitizenProfile,
        ),
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.successMessage ?? 'Perfil actualizado correctamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = context.watch<SessionViewModel>().state.session?.user;
    final viewModel = context.watch<ProfileViewModel>();
    final controller = context.watch<ThemeController>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final mode = Theme.of(context).brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            onPressed: viewModel.isLoading
                ? null
                : () => viewModel.load(forceRefresh: true),
            tooltip: 'Actualizar perfil',
            icon: viewModel.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _ProfileHeader(
              profile: viewModel.userProfile,
              fallback: sessionUser,
            ),
            if (viewModel.isLoading && viewModel.userProfile == null) ...[
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
            ] else if (viewModel.errorMessage != null &&
                viewModel.userProfile == null) ...[
              const SizedBox(height: 24),
              _ErrorCard(
                message: viewModel.errorMessage!,
                onRetry: () => viewModel.load(forceRefresh: true),
              ),
            ] else if (viewModel.userProfile != null) ...[
              const SizedBox(height: 24),
              _ProfileInformation(
                user: viewModel.userProfile!,
                citizen: viewModel.citizenProfile,
              ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorCard(
                  message: viewModel.errorMessage!,
                  onRetry: () => viewModel.load(forceRefresh: true),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () => _openEditor(viewModel),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Cambiar tema',
              style: textTheme.titleMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige los colores de la aplicación. El modo claro u oscuro se adapta a tu dispositivo.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: RadioGroup<ThemeVariant>(
                groupValue: controller.variant,
                onChanged: _changeTheme,
                child: Column(
                  children: [
                    for (final variant in ThemeVariant.values)
                      RadioListTile<ThemeVariant>(
                        value: variant,
                        enabled: !_savingTheme,
                        title: Text(switch (variant) {
                          ThemeVariant.normal => 'Normal (verde)',
                          ThemeVariant.pink => 'Pink (rosa)',
                        }),
                        secondary: Icon(
                          Icons.circle,
                          color: getTheme(mode, variant).colors.primary,
                          semanticLabel: switch (variant) {
                            ThemeVariant.normal => 'Verde',
                            ThemeVariant.pink => 'Rosa',
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _themeError ??
                  (_savingTheme
                      ? 'Guardando…'
                      : 'Los cambios se guardan automáticamente.'),
              style: textTheme.bodySmall?.copyWith(
                color: _themeError == null
                    ? colors.textSecondary
                    : colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.fallback});

  final UserProfile? profile;
  final AuthenticatedUser? fallback;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = profile?.imageUrl ?? fallback?.imageUrl;
    final displayName =
        profile?.displayName ?? fallback?.displayName ?? 'Usuario';
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : fallback?.email ?? 'Sin correo';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: colors.surfaceVariant,
          foregroundImage: imageUrl?.isNotEmpty == true
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl?.isNotEmpty == true
              ? null
              : Icon(Icons.person_outline, color: colors.text, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: colors.text, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              if (profile?.emailVerified == true) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.verified, size: 15, color: colors.success),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Correo verificado',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInformation extends StatelessWidget {
  const _ProfileInformation({required this.user, required this.citizen});

  final UserProfile user;
  final CitizenProfile? citizen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InformationCard(
          title: 'Datos personales',
          children: [
            _InformationRow(
              icon: Icons.badge_outlined,
              label: 'DNI',
              value: user.dni,
            ),
            _InformationRow(
              icon: Icons.phone_outlined,
              label: 'Celular',
              value: user.phone,
            ),
            _InformationRow(
              icon: Icons.home_outlined,
              label: 'Dirección',
              value: user.address,
            ),
            _InformationRow(
              icon: Icons.cake_outlined,
              label: 'Fecha de nacimiento',
              value: user.birthDate == null
                  ? 'No registrada'
                  : DateFormat('dd/MM/yyyy').format(user.birthDate!),
            ),
          ],
        ),
        if (citizen != null) ...[
          const SizedBox(height: 16),
          _InformationCard(
            title: 'Ubicación habitual',
            children: [
              _InformationRow(
                icon: Icons.my_location_outlined,
                label: 'Coordenadas',
                value:
                    citizen!.homeLatitude == null ||
                        citizen!.homeLongitude == null
                    ? 'No registradas'
                    : '${citizen!.homeLatitude!.toStringAsFixed(6)}, '
                          '${citizen!.homeLongitude!.toStringAsFixed(6)}',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.appColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.appColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.appColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'No registrado' : value,
                style: TextStyle(
                  color: context.appColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.errorLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appColors.error),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({
    required this.user,
    required this.citizen,
    required this.includeCitizenProfile,
  });

  final UserProfile user;
  final CitizenProfile? citizen;
  final bool includeCitizenProfile;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _lastName = TextEditingController(text: widget.user.lastName);
    _phone = TextEditingController(text: widget.user.phone);
    _address = TextEditingController(text: widget.user.address);
    _latitude = TextEditingController(
      text: widget.citizen?.homeLatitude?.toString() ?? '',
    );
    _longitude = TextEditingController(
      text: widget.citizen?.homeLongitude?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final viewModel = context.read<ProfileViewModel>();
    final success = await viewModel.save(
      name: _name.text,
      lastName: _lastName.text,
      phone: _phone.text,
      address: _address.text,
      homeLatitude: _latitude.text,
      homeLongitude: _longitude.text,
    );
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Editar perfil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.appColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nombres'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Apellidos'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Celular'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              textInputAction: widget.includeCitizenProfile
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            if (widget.includeCitizenProfile) ...[
              const SizedBox(height: 24),
              Text(
                'Ubicación habitual',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitud'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _longitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitud'),
                    ),
                  ),
                ],
              ),
            ],
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                viewModel.errorMessage!,
                style: TextStyle(color: context.appColors.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: viewModel.isSaving ? null : _save,
              icon: viewModel.isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                viewModel.isSaving ? 'Guardando…' : 'Guardar cambios',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
