import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:sereno_ya/ui/officer/officer_detail_screen.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_detail_view_model.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incident_card.dart';

// Patrol workspace: pending interventions lead; reports place server totals
// above filters. Existing Material typography, semantic palette, 16px insets.
class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});
  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _tab = 0;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<OfficerIncidentsViewModel>();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Serenazgo' : 'Reportes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: model.isBusy ? null : () => _refresh(model),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ResponsiveBody(
        maxWidth: 720,
        child: RefreshIndicator(
          onRefresh: () => _refresh(model),
          child: ListView(
            key: ValueKey(_tab),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (_tab == 0) ...[
                Text(
                  'Tu atención hace la diferencia',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'San Jerónimo · Atención ciudadana',
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aceptados en esta sesión',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Las asignaciones anteriores no están disponibles en el servicio actual.',
                ),
                const SizedBox(height: 16),
                if (model.accepted.isEmpty)
                  const Text('Aún no has aceptado incidentes en esta sesión.'),
                for (final item in model.accepted) _card(model, item),
                const SizedBox(height: 24),
                Text(
                  'Incidentes pendientes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  'Resumen de atención',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Totales generales de Serenazgo'),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in operationalStatuses)
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${model.totals[status] ?? '—'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: context.appColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(status.label),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (model.metricsError != null)
                  TextButton.icon(
                    onPressed: model.loadMetrics,
                    icon: const Icon(Icons.refresh),
                    label: Text(model.metricsError!),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: model.filter == null,
                      onSelected: (_) => model.selectFilter(null),
                    ),
                    for (final status in operationalStatuses)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: model.filter == status,
                        onSelected: (_) => model.selectFilter(status),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (model.errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(model.errorMessage!),
                        TextButton(
                          onPressed: () =>
                              model.loadInitial(forceRefresh: true),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (model.isBusy)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!model.isBusy &&
                  model.errorMessage == null &&
                  model.incidents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 48,
                        color: context.appColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      const Text('No hay incidentes para mostrar.'),
                      const Text('Desliza hacia abajo para actualizar.'),
                    ],
                  ),
                ),
              for (final item in model.incidents) _card(model, item),
              if (model.hasMore)
                TextButton(
                  onPressed: model.isBusy ? null : model.loadMore,
                  child: const Text('Cargar más reportes'),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: context.appColors.tabIconSelected,
        unselectedItemColor: context.appColors.tabIconDefault,
        onTap: (index) {
          if (_tab == index) return;
          setState(() => _tab = index);
          model.selectFilter(index == 0 ? OfficerIncidentStatus.pending : null);
          if (index == 1) model.loadMetrics();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_police_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  Widget _card(OfficerIncidentsViewModel model, OfficerIncident item) =>
      OfficerIncidentCard(
        item: item,
        onOpen: () => _open(model, item),
        busy: model.isAccepting(item.id),
        onAccept: () => _accept(model, item),
      );
  Future<void> _refresh(OfficerIncidentsViewModel model) async {
    await model.loadInitial(forceRefresh: true);
    if (_tab == 1) await model.loadMetrics();
  }

  Future<void> _accept(
    OfficerIncidentsViewModel model,
    OfficerIncident item,
  ) async {
    final minutes = await requestArrivalTime(context);
    if (minutes == null || !mounted) return;
    final error = await model.acceptIncident(item.id, minutes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Incidente aceptado. Respuesta enviada al ciudadano.',
        ),
      ),
    );
  }

  Future<void> _open(
    OfficerIncidentsViewModel model,
    OfficerIncident item,
  ) async {
    final detail = OfficerDetailViewModel(model.repository, item.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: detail,
          child: const OfficerDetailScreen(),
        ),
      ),
    );
    final updated = detail.item;
    final acceptedHere = detail.acceptedHere;
    detail.dispose();
    if (mounted) {
      await model.synchronize(
        updated,
        acceptedHere: acceptedHere,
        acceptedId: item.id,
      );
    }
  }
}
