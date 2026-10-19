import 'package:flutter/material.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  static const tips = [
    (
      title: 'En la calle',
      icon: Icons.directions_walk_outlined,
      detail: 'Prefiere lugares iluminados y concurridos. Mantén tus pertenencias a la vista y evita distraerte con el teléfono al caminar.',
    ),
    (
      title: 'Ante una situación de riesgo',
      icon: Icons.shield_outlined,
      detail: 'Aléjate si puedes hacerlo con seguridad. No enfrentes a la persona involucrada; busca un lugar seguro y pide ayuda.',
    ),
    (
      title: 'Al reportar un incidente',
      icon: Icons.report_outlined,
      detail: 'Indica la ubicación y una referencia visible. Describe lo ocurrido sin ponerte en peligro para obtener fotos o videos.',
    ),
    (
      title: 'En casa',
      icon: Icons.home_outlined,
      detail: 'Comprueba puertas y ventanas antes de salir. Evita compartir públicamente tus horarios o que tu vivienda quedará vacía.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consejos de seguridad')),
    body: SafeArea(
      child: ResponsiveBody(
        maxWidth: 600,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Recomendaciones generales para cuidarte y reportar sin exponerte.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final tip in tips)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(tip.icon, color: context.appColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(tip.detail),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
