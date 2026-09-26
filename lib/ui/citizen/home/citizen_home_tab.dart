import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/citizen_home_screen.dart'; // Para reutilizar ActionCard temporalmente

class CitizenHomeTab extends StatelessWidget {
  const CitizenHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>().state.session;
    final userName = session?.user.email ?? 'Usuario';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: context.appColors.textSecondary),
                    ),
                    Text(
                      'Hola, $userName',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.appColors.text,
                            fontSize: 22,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.appColors.infoLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: context.appColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // GPS Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.appColors.infoLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.appColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GPS Activo:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SOS Button Area
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.go('${RouteNames.citizen}/report'),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.appColors.error,
                        boxShadow: [
                          BoxShadow(
                            color: context.appColors.error.withAlpha(100),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                          BoxShadow(
                            color: context.appColors.error.withAlpha(50),
                            blurRadius: 60,
                            spreadRadius: 40,
                          ),
                        ],
                        border: Border.all(
                          color: context.appColors.textInverse.withAlpha(150),
                          width: 15,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign,
                            color: context.appColors.textInverse,
                            size: 50,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: context.appColors.textInverse,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'PRESIONAR',
                            style: TextStyle(
                              color: context.appColors.textInverse,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '¿Necesitas ayuda inmediata?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.appColors.text,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Acciones Rápidas
            Text(
              'ACCIONES RÁPIDAS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.appColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            // Action Cards
            const ActionCard(
              title: 'Serenazgo San Jerónimo',
              subtitle: '(084) 272-100 • Radio Base',
              label: 'LÍNEA DIRECTA 24/7',
            ),
            const SizedBox(height: 12),
            const ActionCard(
              title: 'Serenazgo San Jerónimo',
              subtitle: '(084) 272-100 • Radio Base',
              label: 'LÍNEA DIRECTA 24/7',
            ),
            const SizedBox(height: 12),
            const ActionCard(
              title: 'Serenazgo San Jerónimo',
              subtitle: '(084) 272-100 • Radio Base',
              label: 'LÍNEA DIRECTA 24/7',
            ),
          ],
        ),
      ),
    );
  }
}
