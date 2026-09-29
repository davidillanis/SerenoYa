import 'package:flutter/material.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: presentation.color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: presentation.color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(presentation.icon, size: 14, color: presentation.color),
          const SizedBox(width: 6),
          Text(
            presentation.label,
            style: TextStyle(
              color: presentation.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _StatusPresentation _presentation(BuildContext context) {
    return switch (status) {
      'REQUESTED' => _StatusPresentation(
        context.appColors.warning,
        'Solicitada',
        Icons.access_time,
      ),
      'ACCEPTED' => _StatusPresentation(
        context.appColors.info,
        'Sereno en camino',
        Icons.directions_run,
      ),
      'ON_SITE' => _StatusPresentation(
        context.appColors.success,
        'Sereno en el lugar',
        Icons.where_to_vote,
      ),
      'ATTENDED' => _StatusPresentation(
        context.appColors.success,
        'Atendida',
        Icons.check_circle_outline,
      ),
      'CANCELLED_BY_CITIZEN' => _StatusPresentation(
        context.appColors.error,
        'Cancelada',
        Icons.cancel_outlined,
      ),
      'EXPIRED' => _StatusPresentation(
        context.appColors.textSecondary,
        'Expirada',
        Icons.timer_off_outlined,
      ),
      _ => _StatusPresentation(
        context.appColors.textSecondary,
        status,
        Icons.info_outline,
      ),
    };
  }
}

class _StatusPresentation {
  const _StatusPresentation(this.color, this.label, this.icon);

  final Color color;
  final String label;
  final IconData icon;
}
