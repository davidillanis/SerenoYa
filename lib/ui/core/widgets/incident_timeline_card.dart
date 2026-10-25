import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

class IncidentTimelineCard extends StatelessWidget {
  const IncidentTimelineCard({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final isActive = const {
      'REQUESTED',
      'ACCEPTED',
      'ON_SITE',
    }.contains(incident.status);
    final entries = <(String, DateTime?, IconData)>[
      ('Reporte creado', incident.createdAt, Icons.receipt_long_outlined),
      if (isActive || incident.acceptedAt != null)
        (
          'Aceptado por el sereno',
          incident.acceptedAt,
          Icons.verified_outlined,
        ),
      if (isActive || incident.arrivedAt != null)
        ('Sereno en camino', incident.arrivedAt, Icons.directions_car_outlined),
      if (isActive || incident.attendedAt != null)
        (
          'Sereno llegó al lugar',
          incident.attendedAt,
          Icons.location_on_outlined,
        ),
      if (incident.status == 'EXPIRED')
        ('Incidencia expirada', incident.expiredAt, Icons.timer_off_outlined),
      if (incident.cancelledAt != null ||
          incident.status.startsWith('CANCELLED'))
        ('Incidencia cancelada', incident.cancelledAt, Icons.cancel_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Seguimiento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < entries.length; index++) ...[
            _TimelineEntry(
              label: entries[index].$1,
              date: entries[index].$2,
              icon: entries[index].$3,
              pending: isActive && index > 0 && entries[index].$2 == null,
            ),
            if (index != entries.length - 1) const SizedBox(height: 20),
          ],
          if (incident.status == 'REQUESTED' && incident.expiredAt != null) ...[
            const SizedBox(height: 20),
            _TimelineEntry(
              label: 'Plazo para aceptar el reporte',
              date: incident.expiredAt,
              icon: Icons.schedule_outlined,
              caption: 'El reporte expira si ningún sereno lo acepta.',
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.label,
    required this.date,
    required this.icon,
    this.pending = false,
    this.caption,
  });

  final String label;
  final DateTime? date;
  final IconData icon;
  final bool pending;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: pending
              ? context.appColors.textTertiary
              : context.appColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: pending
                      ? context.appColors.textSecondary
                      : context.appColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date != null
                    ? DateFormat('dd/MM/yyyy · HH:mm').format(date!)
                    : pending
                    ? 'Pendiente'
                    : 'Fecha no disponible',
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 4),
                Text(
                  caption!,
                  style: TextStyle(
                    color: context.appColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
