import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/ui/citizen/widgets/incident_summary_card.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  static const _loadMoreThreshold = 320.0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _loadMoreThreshold) {
      return;
    }
    context.read<OfficerIncidentsViewModel>().loadMore();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OfficerIncidentsViewModel>();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Incidencias disponibles'),
        actions: [
          IconButton(
            tooltip: viewModel.isBusy
                ? 'Actualizando incidencias'
                : 'Actualizar incidencias',
            onPressed: viewModel.isBusy
                ? null
                : () => viewModel.loadInitial(forceRefresh: true),
            icon: viewModel.isLoadingInitial
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ResponsiveBody(maxWidth: 720, child: _buildBody(viewModel)),
    );
  }

  Widget _buildBody(OfficerIncidentsViewModel viewModel) {
    if (viewModel.isLoadingInitial && viewModel.incidents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null && viewModel.incidents.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar las incidencias',
        message: viewModel.errorMessage!,
        actionLabel: 'Reintentar',
        onAction: () => viewModel.loadInitial(forceRefresh: true),
      );
    }
    if (viewModel.incidents.isEmpty) {
      return const _StateMessage(
        icon: Icons.verified_outlined,
        title: 'No hay incidencias pendientes',
        message: 'Las nuevas alertas aparecerán aquí cuando actualices.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadInitial(forceRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount:
            viewModel.incidents.length +
            (viewModel.isLoadingMore || viewModel.loadMoreError != null
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == viewModel.incidents.length) {
            return _PaginationFooter(
              isLoading: viewModel.isLoadingMore,
              errorMessage: viewModel.loadMoreError,
              onRetry: viewModel.retryLoadMore,
            );
          }
          final incident = viewModel.incidents[index];
          return IncidentSummaryCard(
            incident: incident,
            isAccepting: viewModel.isAccepting(incident.id),
            onAccept: () => _acceptIncident(viewModel, incident),
          );
        },
      ),
    );
  }

  Future<void> _acceptIncident(
    OfficerIncidentsViewModel viewModel,
    Incident incident,
  ) async {
    final etaMinutes = await _requestEtaMinutes();
    if (etaMinutes == null || !mounted) return;

    final error = await viewModel.acceptIncident(incident.id, etaMinutes);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Incidencia aceptada. Tiempo estimado: $etaMinutes min.',
        ),
        backgroundColor: error == null
            ? context.appColors.success
            : context.appColors.error,
      ),
    );
  }

  Future<int?> _requestEtaMinutes() async {
    return showDialog<int>(
      context: context,
      builder: (_) => const _EtaMinutesDialog(),
    );
  }
}

class _EtaMinutesDialog extends StatefulWidget {
  const _EtaMinutesDialog();

  @override
  State<_EtaMinutesDialog> createState() => _EtaMinutesDialogState();
}

class _EtaMinutesDialogState extends State<_EtaMinutesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController(text: '10');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(int.parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aceptar incidencia'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Tiempo estimado de llegada',
            suffixText: 'min',
          ),
          validator: (value) {
            final minutes = int.tryParse(value ?? '');
            if (minutes == null || minutes < 1 || minutes > 180) {
              return 'Ingresa un valor entre 1 y 180 minutos';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Aceptar')),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: isLoading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(errorMessage ?? 'Reintentar'),
              ),
      ),
    );
  }
}
