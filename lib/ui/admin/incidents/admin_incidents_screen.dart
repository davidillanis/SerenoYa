import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/admin/incidents/view_models/admin_incidents_view_model.dart';
import 'package:sereno_ya/ui/admin/incidents/widgets/admin_incident_item.dart';
import 'package:sereno_ya/ui/admin/incidents/widgets/admin_incident_filters.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:sereno_ya/routing/route_names.dart';

class AdminIncidentsScreen extends StatefulWidget {
  const AdminIncidentsScreen({super.key});

  @override
  State<AdminIncidentsScreen> createState() => _AdminIncidentsScreenState();
}

class _AdminIncidentsScreenState extends State<AdminIncidentsScreen> {
  static const _loadMoreThreshold = 360.0;
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
    context.read<AdminIncidentsViewModel>().loadMore();
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
    final viewModel = context.watch<AdminIncidentsViewModel>();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            tooltip: 'Actualizar incidencias',
            onPressed: viewModel.isLoadingInitial
                ? null
                : () => viewModel.loadInitial(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ResponsiveBody(
        maxWidth: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(
              totalElements: viewModel.totalElements,
              visibleElements: viewModel.incidents.length,
            ),
            _FilterToolbar(
              viewModel: viewModel,
              onOpenFilters: () => _openFilters(viewModel),
            ),
            if (viewModel.isLoadingInitial)
              const LinearProgressIndicator(minHeight: 2),
            if (viewModel.errorMessage != null &&
                viewModel.incidents.isNotEmpty)
              _InlineError(
                message: viewModel.errorMessage!,
                onRetry: () => viewModel.loadInitial(forceRefresh: true),
              ),
            Expanded(child: _buildContent(context, viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminIncidentsViewModel viewModel,
  ) {
    if (viewModel.isLoadingInitial && viewModel.incidents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null && viewModel.incidents.isEmpty) {
      return _RefreshableState(
        onRefresh: () => viewModel.loadInitial(forceRefresh: true),
        child: _ErrorState(
          message: viewModel.errorMessage!,
          onRetry: () => viewModel.loadInitial(forceRefresh: true),
        ),
      );
    }
    if (viewModel.incidents.isEmpty) {
      return _RefreshableState(
        onRefresh: () => viewModel.loadInitial(forceRefresh: true),
        child: const _EmptyState(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 840;
        return RefreshIndicator(
          onRefresh: () => viewModel.loadInitial(forceRefresh: true),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              0,
              compact ? 16 : 24,
              24,
            ),
            itemCount:
                viewModel.incidents.length +
                (compact ? 0 : 1) +
                (viewModel.isLoadingMore || viewModel.loadMoreError != null
                    ? 1
                    : 0),
            separatorBuilder: (_, index) => SizedBox(height: compact ? 12 : 0),
            itemBuilder: (context, index) {
              if (!compact && index == 0) {
                return const AdminIncidentTableHeader();
              }
              final incidentIndex = compact ? index : index - 1;
              if (incidentIndex == viewModel.incidents.length) {
                return _PaginationFooter(
                  isLoading: viewModel.isLoadingMore,
                  message: viewModel.loadMoreError,
                  onRetry: viewModel.retryLoadMore,
                );
              }
              return AdminIncidentItem(
                incident: viewModel.incidents[incidentIndex],
                compact: compact,
                onOpen: () => context.push(
                  RouteNames.adminIncidentDetail(
                    viewModel.incidents[incidentIndex].id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openFilters(AdminIncidentsViewModel viewModel) async {
    final selected = await showAdminIncidentFilters(
      context,
      initialFilters: viewModel.filters,
      categories: viewModel.categories,
      categoryError: viewModel.filterOptionsError,
    );
    if (selected == null || !mounted) return;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    await viewModel.applyFilters(selected);
  }
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({required this.viewModel, required this.onOpenFilters});

  final AdminIncidentsViewModel viewModel;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final filters = viewModel.filters;
    final summaries = <String>[
      if (filters.status != null) filters.status!.label,
      if (filters.categoryId != null)
        viewModel.categoryName(filters.categoryId)!,
      if (filters.fromDate != null || filters.toDate != null) 'Rango de fechas',
      if (filters.citizenUserId != null) 'Ciudadano',
      if (filters.serenoUserId != null) 'Sereno',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: viewModel.isBusy ? null : onOpenFilters,
            icon: const Icon(Icons.tune, size: 18),
            label: Text(
              filters.isEmpty ? 'Filtrar' : 'Filtros (${filters.activeCount})',
            ),
          ),
          for (final summary in summaries)
            Chip(
              label: Text(summary),
              side: BorderSide(color: context.appColors.borderVariant),
              backgroundColor: context.appColors.surface,
            ),
          if (!filters.isEmpty)
            TextButton(
              onPressed: viewModel.isBusy ? null : viewModel.clearFilters,
              child: const Text('Limpiar'),
            ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.totalElements,
    required this.visibleElements,
  });

  final int totalElements;
  final int visibleElements;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incidencias registradas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Consulta el registro general reportado en el sistema.',
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.appColors.borderVariant),
            ),
            child: Text(
              totalElements == 0
                  ? '$visibleElements visibles'
                  : '$visibleElements de $totalElements',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshableState extends StatelessWidget {
  const _RefreshableState({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: context.appColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay incidencias registradas',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Los reportes ciudadanos aparecerán en este registro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: context.appColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.errorLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: context.appColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: isLoading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(message ?? 'Reintentar'),
              ),
      ),
    );
  }
}
