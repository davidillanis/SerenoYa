import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/citizen_home_screen.dart'; // Para reutilizar ActionCard temporalmente
import 'package:sereno_ya/data/services/maps/nearby_police_service.dart';
import 'package:sereno_ya/ui/citizen/home/emergency_numbers_screen.dart';
import 'package:sereno_ya/ui/citizen/home/nearby_police_stations_screen.dart';
import 'package:sereno_ya/ui/citizen/home/safety_tips_screen.dart';

class CitizenHomeTab extends StatefulWidget {
  const CitizenHomeTab({super.key, this.nearbyPoliceService});

  final NearbyPoliceService? nearbyPoliceService;

  @override
  State<CitizenHomeTab> createState() => _CitizenHomeTabState();
}

class _CitizenHomeTabState extends State<CitizenHomeTab> {
  void _openPage(Widget page) =>
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.appColors.textSecondary),
                      ),
                      Text(
                        'Hola, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.text,
                              fontSize: 22,
                            ),
                      ),
                    ],
                  ),
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

            // Location Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.appColors.infoLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: context.appColors.info,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Usaremos tu ubicación',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
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

            ActionCard(
              title: 'Comisarías cercanas',
              subtitle: 'Ver direcciones y rutas en Maps',
              label: 'DIRECTORIO LOCAL',
              icon: Icons.local_police_outlined,
              onTap: () => _openPage(
                NearbyPoliceStationsScreen(
                  nearbyPoliceService: widget.nearbyPoliceService,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ActionCard(
              title: 'Números de emergencia',
              subtitle: 'Contactos locales de San Jerónimo',
              label: 'LLAMADAS',
              icon: Icons.phone_outlined,
              onTap: () => _openPage(const EmergencyNumbersScreen()),
            ),
            const SizedBox(height: 12),
            ActionCard(
              title: 'Consejos de seguridad',
              subtitle: 'Recomendaciones para cuidarte',
              label: 'PREVENCIÓN',
              icon: Icons.shield_outlined,
              onTap: () => _openPage(const SafetyTipsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
