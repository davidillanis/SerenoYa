import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/citizen/incident_history/view_models/incident_history_view_model.dart';
import 'package:sereno_ya/ui/citizen/widgets/incident_summary_card.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

class IncidentHistoryTab extends StatefulWidget {
  const IncidentHistoryTab({super.key});

  @override
  State<IncidentHistoryTab> createState() => _IncidentHistoryTabState();
}

class _IncidentHistoryTabState extends State<IncidentHistoryTab> {
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
    context.read<IncidentHistoryViewModel>().loadMore();
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
    final viewModel = context.watch<IncidentHistoryViewModel>();

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Column(
        children: [
          _HistoryFilterBar(
            selectedFilter: viewModel.selectedFilter,
            enabled: !viewModel.isBusy,
            onSelected: (filter) => _selectFilter(viewModel, filter),
          ),
          Expanded(child: _buildContent(viewModel)),
        ],
      ),
    );
  }

  Widget _buildContent(IncidentHistoryViewModel viewModel) {
    if (viewModel.isLoadingInitial && viewModel.incidents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null && viewModel.incidents.isEmpty) {
      return _refreshableState(
        _ErrorState(
          message: viewModel.errorMessage!,
          onRetry: () => viewModel.loadInitial(forceRefresh: true),
        ),
        viewModel,
      );
    }
    if (viewModel.incidents.isEmpty) {
      return _refreshableState(
        _EmptyState(filter: viewModel.selectedFilter),
        viewModel,
      );
    }

    return Column(
      children: [
        if (viewModel.errorMessage != null)
          _InlineError(
            message: viewModel.errorMessage!,
            onRetry: () => viewModel.loadInitial(forceRefresh: true),
          ),
        Expanded(
          child: RefreshIndicator(
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
                  onOpen: () =>
                      context.push(RouteNames.incidentDetail(incident.id)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _selectFilter(
    IncidentHistoryViewModel viewModel,
    IncidentHistoryFilter filter,
  ) {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    viewModel.selectFilter(filter);
  }

  Widget _refreshableState(Widget child, IncidentHistoryViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.loadInitial(forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final IncidentHistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 72,
              color: context.appColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              filter == IncidentHistoryFilter.all
                  ? 'Aún no tienes incidencias finalizadas'
                  : 'No tienes incidencias ${filter.label.toLowerCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán tus reportes atendidos, cancelados o expirados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.selectedFilter,
    required this.enabled,
    required this.onSelected,
  });

  final IncidentHistoryFilter selectedFilter;
  final bool enabled;
  final ValueChanged<IncidentHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: IncidentHistoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = IncidentHistoryFilter.values[index];
          final selected = filter == selectedFilter;
          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            showCheckmark: false,
            onSelected: enabled ? (_) => onSelected(filter) : null,
            selectedColor: context.appColors.primary,
            side: BorderSide(
              color: selected
                  ? context.appColors.primary
                  : context.appColors.border,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? context.appColors.textInverse
                  : context.appColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        },
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: context.appColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
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
