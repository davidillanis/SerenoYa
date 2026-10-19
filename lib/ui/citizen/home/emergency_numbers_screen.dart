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
      name: 'Policía Nacional',
      number: '105',
      icon: Icons.local_police_outlined,
    ),
    (
      name: 'Bomberos',
      number: '116',
      icon: Icons.local_fire_department_outlined,
    ),
    (name: 'SAMU', number: '106', icon: Icons.medical_services_outlined),
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
              'Selecciona el servicio que necesitas. Confirma la llamada en tu teléfono.',
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
                  title: Text(entry.name),
                  subtitle: Text(entry.number),
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
