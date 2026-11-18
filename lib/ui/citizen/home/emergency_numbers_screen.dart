import 'package:flutter/material.dart';
import 'package:sereno_ya/data/services/officer/contact_service.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({
    super.key,
    this.contactService = const ContactService(),
  });

  final ContactService contactService;

  static const numbers = [
    (
      name: 'Serenazgo San Jerónimo',
      number: '990223044',
      displayNumber: '990 223 044',
      location: 'San Jerónimo',
      icon: Icons.security_outlined,
    ),
    (
      name: 'PNP San Jerónimo',
      number: '980122039',
      displayNumber: '980 122 039',
      location: 'San Jerónimo',
      icon: Icons.local_police_outlined,
    ),
    (
      name: 'Defensa Civil',
      number: '920052070',
      displayNumber: '920 052 070',
      location: 'San Jerónimo',
      icon: Icons.health_and_safety_outlined,
    ),
    (
      name: 'Centro de Salud',
      number: '948993737',
      displayNumber: '948 993 737',
      location: 'San Jerónimo',
      icon: Icons.local_hospital_outlined,
    ),
    (
      name: 'Central de Bomberos',
      number: '953624686',
      displayNumber: '953 624 686',
      location: 'Andahuaylas',
      icon: Icons.local_fire_department_outlined,
    ),
  ];

  Future<void> _call(BuildContext context, String number) async {
    final opened = await contactService.call(number);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el marcador telefónico.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Números de emergencia')),
    body: SafeArea(
      child: ResponsiveBody(
        maxWidth: 600,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Contactos locales para emergencias en San Jerónimo. Toca una tarjeta y confirma la llamada en tu teléfono.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final entry in numbers)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(entry.icon, color: context.appColors.primary),
                  title: Text(
                    entry.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${entry.displayNumber} · ${entry.location}',
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.call_outlined),
                  onTap: () => _call(context, entry.number),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
