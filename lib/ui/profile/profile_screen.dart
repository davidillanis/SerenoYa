import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _saving = false;
  String? _saveError;

  Future<void> _changeTheme(ThemeVariant? variant) async {
    if (variant == null || _saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await context.read<ThemeController>().setVariant(variant);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError =
            'No se pudo guardar el tema. Toca la opción para reintentar.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionViewModel>().state.session?.user;
    final controller = context.watch<ThemeController>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final mode = Theme.of(context).brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ResponsiveBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.surfaceVariant,
                  child: Icon(
                    Icons.person_outline,
                    color: colors.text,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Usuario',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Sin correo',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (user?.phone?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(user!.phone!, style: textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Cambiar tema', style: textTheme.titleMedium),
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
                        enabled: !_saving,
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
              _saveError ??
                  (_saving
                      ? 'Guardando…'
                      : 'Los cambios se guardan automáticamente.'),
              style: textTheme.bodySmall?.copyWith(
                color: _saveError == null ? colors.textSecondary : colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
