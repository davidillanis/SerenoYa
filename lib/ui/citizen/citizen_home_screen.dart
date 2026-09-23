import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>().state.session;
    final userName = session?.user.firstName ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS San Jerónimo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      Text(
                        'Hola, $userName',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D253C),
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_user_outlined, color: Colors.blue.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // GPS Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GPS Activo:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                          color: Colors.red.shade700,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withAlpha(100),
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: Colors.red.withAlpha(50),
                              blurRadius: 60,
                              spreadRadius: 40,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withAlpha(150),
                            width: 15,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign, color: Colors.white, size: 50),
                            SizedBox(height: 8),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'PRESIONAR',
                              style: TextStyle(
                                color: Colors.white,
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
                            color: const Color(0xFF0D253C),
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
                      color: Colors.grey.shade700,
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
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.label,
  });

  final String title;
  final String subtitle;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_in_talk, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D253C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
