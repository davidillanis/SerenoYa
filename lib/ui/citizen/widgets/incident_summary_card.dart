import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/widgets/incident_status_badge.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

class IncidentSummaryCard extends StatelessWidget {
  const IncidentSummaryCard({
    super.key,
    required this.incident,
    this.onOpen,
    this.onCancel,
    this.onAccept,
    this.isAccepting = false,
  });

  final Incident incident;
  final VoidCallback? onOpen;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    final canCancel =
        onCancel != null &&
        (incident.status == 'REQUESTED' || incident.status == 'ACCEPTED');
    final canAccept = onAccept != null && incident.status == 'REQUESTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IncidentStatusBadge(status: incident.status),
                  Text(
                    incident.createdAt != null
                        ? DateFormat('dd/MM HH:mm').format(incident.createdAt!)
                        : '',
                    style: TextStyle(
                      color: context.appColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.report_problem,
                      color: context.appColors.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.category?.name ?? 'Incidencia',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incident.description.isNotEmpty
                              ? incident.description
                              : 'Sin descripción',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: context.appColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.referenceAddress?.isNotEmpty == true
                          ? incident.referenceAddress!
                          : 'Ubicación enviada por GPS',
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (canCancel || canAccept) ...[
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: canAccept
                      ? FilledButton.icon(
                          onPressed: isAccepting ? null : onAccept,
                          icon: isAccepting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_police_outlined,
                                  size: 18,
                                ),
                          label: Text(isAccepting ? 'Aceptando' : 'Aceptar'),
                        )
                      : TextButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancelar'),
                          style: TextButton.styleFrom(
                            foregroundColor: context.appColors.error,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
