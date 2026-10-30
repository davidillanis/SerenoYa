import 'package:sereno_ya/ui/core/widgets/incident_timeline_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/ui/citizen/incident_detail/view_models/incident_detail_view_model.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/widgets/incident_status_badge.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IncidentDetailViewModel>();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Detalle de incidencia'),
        actions: [
          IconButton(
            onPressed: viewModel.isLoading
                ? null
                : () => viewModel.load(forceRefresh: true),
            tooltip: 'Actualizar incidencia',
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
        maxWidth: 720,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EvidenceHero(incident: incident),
        const SizedBox(height: 24),
        Text(
          incident.category?.name ?? 'Incidencia reportada',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.appColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          incident.description.isEmpty
              ? 'Sin descripción registrada.'
              : incident.description,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: context.appColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (viewModel.canContactSereno) ...[
          _SerenoContactCard(
            isLoading: viewModel.isCallingContact,
            onCall: () => _callSereno(context, viewModel),
          ),
          const SizedBox(height: 16),
        ],
        _InformationCard(
          children: [
            _InformationRow(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: incident.referenceAddress?.isNotEmpty == true
                  ? incident.referenceAddress!
                  : 'Ubicación enviada por GPS',
            ),
            const SizedBox(height: 16),
            _InformationRow(
              icon: Icons.my_location_outlined,
              label: 'Coordenadas',
              value:
                  '${incident.latitude.toStringAsFixed(6)}, '
                  '${incident.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 16),
            _InformationRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Código',
              value: incident.id,
            ),
          ],
        ),
        const SizedBox(height: 16),
        IncidentTimelineCard(incident: incident),
      ],
    );
  }

  Future<void> _callSereno(
    BuildContext context,
    IncidentDetailViewModel viewModel,
  ) async {
    final opened = await viewModel.callSereno();
    if (!context.mounted || opened) return;

    final message = viewModel.contactErrorMessage;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SerenoContactCard extends StatelessWidget {
  const _SerenoContactCard({required this.isLoading, required this.onCall});

  final bool isLoading;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: context.appColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sereno asignado',
                  style: textTheme.titleMedium?.copyWith(
                    color: context.appColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comunícate directamente si necesitas coordinar la atención.',
            style: textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onCall,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.call_outlined),
              label: Text(
                isLoading ? 'Obteniendo contacto...' : 'Llamar al sereno',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceHero extends StatelessWidget {
  const _EvidenceHero({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final evidence = incident.evidence;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: context.appColors.surfaceVariant,
              child: evidence?.fileUrl.isNotEmpty == true
                  ? Image.network(
                      evidence!.fileUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, _, _) => const _EvidenceUnavailable(),
                    )
                  : const _EvidenceUnavailable(),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Material(
                color: context.appColors.card,
                borderRadius: BorderRadius.circular(20),
                child: IncidentStatusBadge(status: incident.status),
              ),
            ),
          ],
        ),
      ),
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

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
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
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(
                  color: context.appColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
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
