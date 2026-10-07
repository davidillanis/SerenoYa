import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/widgets/incident_status_badge.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

class AdminIncidentItem extends StatelessWidget {
  const AdminIncidentItem({
    super.key,
    required this.incident,
    required this.compact,
    required this.onOpen,
  });

  final Incident incident;
  final bool compact;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return compact
        ? _MobileIncidentCard(incident, onOpen)
        : _DesktopIncidentRow(incident, onOpen);
  }
}

class AdminIncidentTableHeader extends StatelessWidget {
  const AdminIncidentTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: context.appColors.textTertiary,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('ESTADO', style: style)),
          Expanded(flex: 3, child: Text('INCIDENCIA', style: style)),
          Expanded(flex: 3, child: Text('UBICACIÓN', style: style)),
          Expanded(flex: 2, child: Text('REPORTADA', style: style)),
          Expanded(flex: 2, child: Text('CÓDIGO', style: style)),
        ],
      ),
    );
  }
}

class _DesktopIncidentRow extends StatelessWidget {
  const _DesktopIncidentRow(this.incident, this.onOpen);

  final Incident incident;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.card,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.appColors.borderVariant),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IncidentStatusBadge(status: incident.status),
                ),
              ),
              Expanded(
                flex: 3,
                child: _PrimaryCell(
                  title: incident.category?.name ?? 'Sin categoría',
                  subtitle: incident.description.isEmpty
                      ? 'Sin descripción'
                      : incident.description,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _location(incident),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _date(incident.createdAt),
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 2,
                child: SelectableText(
                  _shortId(incident.id),
                  style: TextStyle(
                    color: context.appColors.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileIncidentCard extends StatelessWidget {
  const _MobileIncidentCard(this.incident, this.onOpen);

  final Incident incident;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appColors.borderVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IncidentStatusBadge(status: incident.status),
                  Text(
                    _date(incident.createdAt),
                    style: TextStyle(
                      color: context.appColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryCell(
                title: incident.category?.name ?? 'Sin categoría',
                subtitle: incident.description.isEmpty
                    ? 'Sin descripción'
                    : incident.description,
              ),
              const SizedBox(height: 14),
              _MetaLine(
                icon: Icons.location_on_outlined,
                value: _location(incident),
              ),
              const SizedBox(height: 8),
              _MetaLine(icon: Icons.tag, value: incident.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCell extends StatelessWidget {
  const _PrimaryCell({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: context.appColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

String _location(Incident incident) =>
    incident.referenceAddress?.trim().isNotEmpty == true
    ? incident.referenceAddress!.trim()
    : '${incident.latitude.toStringAsFixed(5)}, ${incident.longitude.toStringAsFixed(5)}';

String _date(DateTime? date) =>
    date == null ? 'Sin fecha' : DateFormat('dd/MM/yyyy HH:mm').format(date);

String _shortId(String id) => id.length <= 12 ? id : '${id.substring(0, 8)}…';
