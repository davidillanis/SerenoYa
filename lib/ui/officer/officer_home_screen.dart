import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:sereno_ya/ui/officer/officer_detail_screen.dart';
import 'package:sereno_ya/ui/officer/officer_reports_tab.dart';
import 'package:sereno_ya/ui/officer/officer_start_tab.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_detail_view_model.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incident_card.dart';

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
          // El hijo debe ser el ListView de la pestaña activa para que el
          // gesto de deslizar funcione; por eso se conserva el condicional
          // en lugar de un IndexedStack.
          child: _tab == 0
              ? OfficerStartTab(
                  model: model,
                  cardBuilder: (item) => _card(model, item),
                )
              : OfficerReportsTab(
                  model: model,
                  cardBuilder: (item) => _card(model, item),
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: context.appColors.tabIconSelected,
        unselectedItemColor: context.appColors.tabIconDefault,
        onTap: (index) => _onTabSelected(model, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_police_outlined),
            activeIcon: Icon(Icons.local_police),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  void _onTabSelected(OfficerIncidentsViewModel model, int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    model.selectFilter(index == 0 ? OfficerIncidentStatus.pending : null);
    if (index == 1) model.loadMetrics();
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
