import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/citizen_home_screen.dart'; // Para reutilizar ActionCard temporalmente
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/data/services/maps/nearby_police_service.dart';
import 'package:sereno_ya/ui/citizen/home/emergency_numbers_screen.dart';
import 'package:sereno_ya/ui/citizen/home/safety_tips_screen.dart';

class CitizenHomeTab extends StatefulWidget {
  const CitizenHomeTab({super.key, this.nearbyPoliceService});

  final NearbyPoliceService? nearbyPoliceService;

  @override
  State<CitizenHomeTab> createState() => _CitizenHomeTabState();
}

class _CitizenHomeTabState extends State<CitizenHomeTab> {
  bool _openingMaps = false;

  Future<void> _openNearby() async {
    if (_openingMaps) return;
    setState(() => _openingMaps = true);
    String? error;
    try {
      final opened = await (widget.nearbyPoliceService ?? NearbyPoliceService())
          .openNearby();
      if (!opened) {
        error = 'No se pudo abrir Google Maps. Revisa si tienes una aplicación de mapas disponible.';
      }
    } on LocationFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'No se pudo buscar comisarías cercanas. Vuelve a intentar.';
    }
    if (!mounted) return;
    setState(() => _openingMaps = false);
    if (error != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

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

            ActionCard(
              title: 'Comisarías cercanas',
              subtitle: _openingMaps
                  ? 'Buscando tu ubicación…'
                  : 'Buscar en Google Maps',
              label: 'CERCA DE TI',
              icon: Icons.local_police_outlined,
              onTap: _openingMaps ? null : _openNearby,
            ),
            const SizedBox(height: 12),
            ActionCard(
              title: 'Números de emergencia',
              subtitle: 'Policía · Bomberos · SAMU',
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
