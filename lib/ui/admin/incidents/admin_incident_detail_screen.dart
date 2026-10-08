import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/models/incident_status_history.dart';
import 'package:sereno_ya/data/models/incident_assignment_attempt.dart';
import 'package:sereno_ya/ui/citizen/incident_detail/view_models/incident_detail_view_model.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/widgets/incident_status_badge.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AdminIncidentDetailScreen extends StatelessWidget {
  const AdminIncidentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IncidentDetailViewModel>();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Detalle de incidencia'),
        actions: [
          IconButton(
            tooltip: 'Actualizar incidencia',
            onPressed: viewModel.isLoading
                ? null
                : () => viewModel.load(forceRefresh: true),
            icon: viewModel.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 1180,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, IncidentDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.incident == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null && viewModel.incident == null) {
      return _ErrorState(
        message: viewModel.errorMessage!,
        onRetry: () => viewModel.load(forceRefresh: true),
      );
    }
    final incident = viewModel.incident;
    if (incident == null) {
      return const Center(child: Text('No se encontró la incidencia'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 24 : 16),
          child: wide
              ? _WideDetail(incident: incident)
              : _CompactDetail(incident: incident),
        );
      },
    );
  }
}

class _WideDetail extends StatelessWidget {
  const _WideDetail({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IncidentHeading(incident: incident),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _EvidencePanel(incident: incident)),
            const SizedBox(width: 24),
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _ReportInformation(incident: incident),
                  const SizedBox(height: 16),
                  _AssignmentPanel(incident: incident),
                  const SizedBox(height: 16),
                  _AssignmentAttemptsPanel(incident: incident),
                  const SizedBox(height: 16),
                  _TimelinePanel(incident: incident),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactDetail extends StatelessWidget {
  const _CompactDetail({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IncidentHeading(incident: incident),
        const SizedBox(height: 20),
        _EvidencePanel(incident: incident),
        const SizedBox(height: 16),
        _ReportInformation(incident: incident),
        const SizedBox(height: 16),
        _AssignmentPanel(incident: incident),
        const SizedBox(height: 16),
        _AssignmentAttemptsPanel(incident: incident),
        const SizedBox(height: 16),
        _TimelinePanel(incident: incident),
      ],
    );
  }
}

class _IncidentHeading extends StatelessWidget {
  const _IncidentHeading({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incident.category?.name ?? 'Incidencia reportada',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Text(
              'Registro ${_shortId(incident.id)}',
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ],
        ),
        IncidentStatusBadge(status: incident.status),
      ],
    );
  }
}

class _EvidencePanel extends StatelessWidget {
  const _EvidencePanel({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final evidence = incident.evidence;
    return _SectionCard(
      title: 'Evidencia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: context.appColors.surfaceVariant,
                child: evidence?.fileUrl.isNotEmpty == true
                    ? Image.network(
                        evidence!.fileUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, _, _) => const _EvidenceUnavailable(),
                      )
                    : const _EvidenceUnavailable(),
              ),
            ),
          ),
          if (evidence != null && evidence.fileName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              evidence.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportInformation extends StatelessWidget {
  const _ReportInformation({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Información del reporte',
      child: Column(
        children: [
          _DetailField(
            icon: Icons.subject_outlined,
            label: 'Descripción',
            value: incident.description.isEmpty
                ? 'Sin descripción registrada'
                : incident.description,
          ),
          const SizedBox(height: 18),
          _DetailField(
            icon: Icons.location_on_outlined,
            label: 'Ubicación',
            value: incident.referenceAddress?.trim().isNotEmpty == true
                ? incident.referenceAddress!.trim()
                : 'Ubicación enviada por GPS',
          ),
          const SizedBox(height: 18),
          _DetailField(
            icon: Icons.my_location_outlined,
            label: 'Coordenadas',
            value:
                '${incident.latitude.toStringAsFixed(6)}, '
                '${incident.longitude.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 18),
          _DetailField(
            icon: Icons.confirmation_number_outlined,
            label: 'Código',
            value: incident.id,
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    if (incident.adminDetailsIncluded) {
      return _AdministrativeTimeline(history: incident.statusHistory);
    }

    final entries = <(String, DateTime?)>[
      ('Reporte creado', incident.createdAt),
      ('Incidencia aceptada', incident.acceptedAt),
      ('Sereno en el lugar', incident.arrivedAt),
      ('Incidencia atendida', incident.attendedAt),
      ('Incidencia cancelada', incident.cancelledAt),
    ].where((entry) => entry.$2 != null).toList(growable: false);

    return _SectionCard(
      title: 'Cronología',
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _TimelineEntry(label: entries[index].$1, date: entries[index].$2!),
            if (index != entries.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AdministrativeTimeline extends StatelessWidget {
  const _AdministrativeTimeline({required this.history});

  final List<IncidentStatusHistory> history;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Historial de estados',
      child: history.isEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history_toggle_off_outlined,
                  color: context.appColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay cambios de estado registrados para esta incidencia.',
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                for (var index = 0; index < history.length; index++) ...[
                  _StatusHistoryEntry(entry: history[index]),
                  if (index != history.length - 1)
                    Divider(height: 32, color: context.appColors.borderVariant),
                ],
              ],
            ),
    );
  }
}

class _StatusHistoryEntry extends StatelessWidget {
  const _StatusHistoryEntry({required this.entry});

  final IncidentStatusHistory entry;

  @override
  Widget build(BuildContext context) {
    final observation = entry.observation.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.change_circle_outlined,
            size: 20,
            color: context.appColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusTransitionLabel(entry),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                observation.isEmpty
                    ? 'Sin observación registrada'
                    : observation,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.changedAt == null
                    ? 'Fecha no disponible'
                    : DateFormat('dd/MM/yyyy HH:mm').format(entry.changedAt!),
                style: TextStyle(
                  color: context.appColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignmentPanel extends StatelessWidget {
  const _AssignmentPanel({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final assignment = incident.assignment;
    if (assignment == null) {
      return _SectionCard(
        title: 'Sereno asignado',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.person_search_outlined,
              color: context.appColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aún no se asignó un sereno',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La asignación aparecerá cuando un oficial acepte la incidencia.',
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      title: 'Sereno asignado',
      child: Column(
        children: [
          _DetailField(
            icon: Icons.badge_outlined,
            label: 'Código de sereno',
            value: assignment.serenoCode.isEmpty
                ? 'Código no disponible'
                : assignment.serenoCode,
          ),
          const SizedBox(height: 18),
          _DetailField(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Estado de la asignación',
            value: _assignmentStatusLabel(assignment.status),
          ),
          const SizedBox(height: 18),
          _DetailField(
            icon: Icons.shield_outlined,
            label: 'Disponibilidad actual',
            value: _serenoStatusLabel(assignment.serenoServiceStatus),
          ),
          if (assignment.assignedAt != null) ...[
            const SizedBox(height: 18),
            _DetailField(
              icon: Icons.schedule_outlined,
              label: 'Fecha de asignación',
              value: DateFormat('dd/MM/yyyy HH:mm')
                  .format(assignment.assignedAt!),
            ),
          ],
          if (assignment.etaMinutes != null) ...[
            const SizedBox(height: 18),
            _DetailField(
              icon: Icons.timer_outlined,
              label: 'Tiempo estimado informado',
              value: '${assignment.etaMinutes} min',
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentAttemptsPanel extends StatelessWidget {
  const _AssignmentAttemptsPanel({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final attempts = incident.assignmentAttempts;
    return _SectionCard(
      title: 'Intentos de asignación',
      child: attempts.isEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.route_outlined,
                  color: context.appColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay intentos de asignación registrados para esta incidencia.',
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                for (var index = 0; index < attempts.length; index++) ...[
                  _AssignmentAttemptEntry(attempt: attempts[index]),
                  if (index != attempts.length - 1)
                    Divider(height: 32, color: context.appColors.borderVariant),
                ],
              ],
            ),
    );
  }
}

class _AssignmentAttemptEntry extends StatelessWidget {
  const _AssignmentAttemptEntry({required this.attempt});

  final IncidentAssignmentAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final rejectionReason = attempt.rejectionReason?.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.route_outlined,
            size: 20,
            color: _attemptStatusColor(context, attempt.status),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Intento ${attempt.attemptNumber} · '
                    '${attempt.serenoCode.isEmpty ? 'Sereno sin código' : attempt.serenoCode}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  _AttemptStatusBadge(status: attempt.status),
                ],
              ),
              const SizedBox(height: 8),
              _AttemptDate(label: 'Enviado', value: attempt.sentAt),
              if (attempt.respondedAt != null) ...[
                const SizedBox(height: 4),
                _AttemptDate(label: 'Respondido', value: attempt.respondedAt),
              ],
              if ((attempt.status == 'PENDING' ||
                      attempt.status == 'EXPIRED') &&
                  attempt.expiresAt != null) ...[
                const SizedBox(height: 4),
                _AttemptDate(label: 'Vencimiento', value: attempt.expiresAt),
              ],
              if (attempt.distanceMeters != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Distancia registrada: ${_formatDistance(attempt.distanceMeters!)}',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (rejectionReason?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  'Motivo: $rejectionReason',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    height: 1.4,
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

class _AttemptDate extends StatelessWidget {
  const _AttemptDate({required this.label, required this.value});

  final String label;
  final DateTime? value;

  @override
  Widget build(BuildContext context) {
    final date = value;
    return Text(
      '$label: ${date == null ? 'Fecha no disponible' : DateFormat('dd/MM/yyyy HH:mm').format(date)}',
      style: TextStyle(
        color: context.appColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AttemptStatusBadge extends StatelessWidget {
  const _AttemptStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _attemptStatusColor(context, status);
    final background = switch (status) {
      'ACCEPTED' => context.appColors.successLight,
      'REJECTED' => context.appColors.errorLight,
      'EXPIRED' => context.appColors.surfaceVariant,
      _ => context.appColors.infoLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _attemptStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.appColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.appColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: TextStyle(
                  color: context.appColors.text,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline,
            size: 18,
            color: context.appColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          DateFormat('dd/MM/yyyy HH:mm').format(date),
          style: TextStyle(color: context.appColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

class _EvidenceUnavailable extends StatelessWidget {
  const _EvidenceUnavailable();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: context.appColors.textTertiary,
        ),
        const SizedBox(height: 8),
        Text(
          'Evidencia no disponible',
          style: TextStyle(color: context.appColors.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: context.appColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortId(String id) => id.length <= 12 ? id : '${id.substring(0, 8)}…';

String _assignmentStatusLabel(String status) => switch (status) {
  'ACTIVE' => 'Activa',
  'COMPLETED' => 'Completada',
  'CANCELLED' => 'Cancelada',
  _ => 'Sin información',
};

String _serenoStatusLabel(String status) => switch (status) {
  'AVAILABLE' => 'Disponible',
  'BUSY' => 'Atendiendo una incidencia',
  'OFF_DUTY' => 'Fuera de servicio',
  _ => 'Sin información',
};

String _statusTransitionLabel(IncidentStatusHistory entry) {
  if (entry.previousStatus == entry.newStatus) {
    return entry.newStatus == 'REQUESTED'
        ? 'Incidencia registrada'
        : _incidentStatusLabel(entry.newStatus);
  }
  return '${_incidentStatusLabel(entry.previousStatus)} → '
      '${_incidentStatusLabel(entry.newStatus)}';
}

String _incidentStatusLabel(String status) => switch (status) {
  'REQUESTED' => 'Solicitada',
  'ACCEPTED' => 'Aceptada',
  'ON_SITE' => 'En el lugar',
  'ATTENDED' => 'Atendida',
  'CANCELLED_BY_CITIZEN' => 'Cancelada por el ciudadano',
  'EXPIRED' => 'Expirada',
  _ => status.isEmpty ? 'Sin información' : status,
};

String _attemptStatusLabel(String status) => switch (status) {
  'PENDING' => 'Pendiente',
  'ACCEPTED' => 'Aceptado',
  'REJECTED' => 'Rechazado',
  'EXPIRED' => 'Expirado',
  _ => 'Sin información',
};

Color _attemptStatusColor(BuildContext context, String status) =>
    switch (status) {
      'ACCEPTED' => context.appColors.success,
      'REJECTED' => context.appColors.error,
      'EXPIRED' => context.appColors.textTertiary,
      _ => context.appColors.info,
    };

String _formatDistance(double distanceMeters) {
  if (distanceMeters >= 1000) {
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
  return '${distanceMeters.toStringAsFixed(0)} m';
}
