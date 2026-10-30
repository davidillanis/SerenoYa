import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_user_summary.dart';
import 'package:sereno_ya/data/models/admin/admin_user_detail.dart';
import 'package:sereno_ya/data/models/admin/admin_user_roles_update_request.dart';
import 'package:sereno_ya/data/models/admin/admin_sereno_update_request.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_users_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _loadMoreThreshold = 360.0;
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<AdminUsersViewModel>().search,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _loadMoreThreshold) {
      return;
    }
    final viewModel = context.read<AdminUsersViewModel>();
    if (_searchController.text.trim() == viewModel.search) {
      viewModel.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _applySearch(value);
    });
  }

  void _applySearch(String value) {
    _searchDebounce?.cancel();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    context.read<AdminUsersViewModel>().setSearch(value);
  }

  void _clearSearch() {
    setState(_searchController.clear);
    _applySearch('');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUserManagement(AdminUserSummary user) async {
    if (_activeUserId != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _activeUserId = user.id);
    final viewModel = context.read<AdminUsersViewModel>();
    try {
      final detail = viewModel.loadUserDetail(user.id);
      final selection = await showDialog<_UserSelection>(
        context: context,
        builder: (_) => _UserManagementDialog(
          user: user,
          initialLoad: detail,
          viewModel: viewModel,
        ),
      );
      if (!mounted || selection == null) return;
      switch (selection.action) {
        case _UserAction.information:
          await _openUserEditor(user);
        case _UserAction.roles:
          await _openRoleEditor(user, selection.detail!);
        case _UserAction.sereno:
          await _openSerenoEditor(user, selection.detail!);
      }
    } finally {
      if (mounted) setState(() => _activeUserId = null);
    }
  }

  Future<void> _openRoleEditor(
    AdminUserSummary user,
    AdminUserDetail detail,
  ) async {
    final viewModel = context.read<AdminUsersViewModel>();
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _EditRolesDialog(user: detail, summary: user, viewModel: viewModel),
    );
    if (!mounted || updated != true) return;
    _showMessage('Los roles se actualizaron correctamente.');
  }

  Future<void> _openSerenoEditor(
    AdminUserSummary user,
    AdminUserDetail detail,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditSerenoDialog(
        user: user,
        userId: detail.id,
        viewModel: context.read<AdminUsersViewModel>(),
      ),
    );
    if (!mounted || updated != true) return;
    _showMessage('El perfil del sereno se actualizó correctamente.');
  }

  Future<void> _openUserEditor(AdminUserSummary user) async {
    final updated = await context.push<bool>(RouteNames.adminUserEdit(user.id));
    if (!mounted || updated != true) return;
    await context.read<AdminUsersViewModel>().loadInitial(forceRefresh: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUsersViewModel>();
    return ColoredBox(
      color: context.appColors.background,
      child: ResponsiveBody(
        maxWidth: 1200,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 960 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;
            final padding = compact ? 16.0 : 24.0;
            final searching = _searchController.text.trim() != viewModel.search;
            return RefreshIndicator(
              onRefresh: () => viewModel.loadInitial(forceRefresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(padding, 24, padding, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Directorio de usuarios',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consulta las cuentas y gestiona sus datos y roles.',
                            style: TextStyle(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onSubmitted: (value) {
                              _applySearch(value);
                              FocusScope.of(context).unfocus();
                            },
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              labelText: 'Buscar usuarios',
                              hintText: 'Escribe un dato del usuario',
                              prefixIcon: const Icon(Icons.search),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.appColors.borderVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpiar búsqueda',
                                      onPressed: _clearSearch,
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              searching || viewModel.isLoadingInitial
                                  ? 'Consultando usuarios…'
                                  : viewModel.errorMessage != null
                                  ? 'No se pudo actualizar el directorio'
                                  : viewModel.search.isEmpty
                                  ? '${viewModel.totalElements} ${viewModel.totalElements == 1 ? 'usuario registrado' : 'usuarios registrados'}'
                                  : '${viewModel.totalElements} ${viewModel.totalElements == 1 ? 'resultado' : 'resultados'} para «${viewModel.search}»',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: context.appColors.textSecondary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (viewModel.isLoadingInitial && viewModel.users.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (viewModel.errorMessage != null &&
                      viewModel.users.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _InlineError(
                        message: viewModel.errorMessage!,
                        onRetry: () =>
                            viewModel.loadInitial(forceRefresh: true),
                      ),
                    ),
                  if (searching || viewModel.users.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyContent(
                        viewModel,
                        searching: searching,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      sliver: SliverList.separated(
                        itemCount: viewModel.users.length + (compact ? 0 : 1),
                        separatorBuilder: (_, _) =>
                            SizedBox(height: compact ? 12 : 0),
                        itemBuilder: (context, index) {
                          if (!compact && index == 0) {
                            return const _UserTableHeader();
                          }
                          final user =
                              viewModel.users[compact ? index : index - 1];
                          return _UserItem(
                            user: user,
                            compact: compact,
                            busy:
                                _activeUserId == user.id &&
                                viewModel.updatingUserId != null,
                            onManage:
                                _activeUserId != null ||
                                    viewModel.updatingUserId != null
                                ? null
                                : () => _openUserManagement(user),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _PaginationFooter(viewModel: viewModel),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyContent(
    AdminUsersViewModel viewModel, {
    required bool searching,
  }) {
    if (viewModel.isLoadingInitial || searching) {
      return const _LoadingMessage(message: 'Buscando usuarios…');
    }
    if (viewModel.errorMessage != null && viewModel.users.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudieron cargar los usuarios',
        message: viewModel.errorMessage!,
        actionLabel: 'Reintentar',
        onAction: () => viewModel.loadInitial(forceRefresh: true),
      );
    }
    final hasSearch = viewModel.search.isNotEmpty;
    return _StateMessage(
      icon: hasSearch ? Icons.search_off_outlined : Icons.people_outline,
      title: hasSearch ? 'Sin coincidencias' : 'Aún no hay usuarios',
      message: hasSearch
          ? 'Prueba con otro dato o vuelve al directorio completo.'
          : 'Las cuentas nuevas aparecerán aquí. Usa «Registrar usuario» para crear la primera.',
      actionLabel: hasSearch ? 'Ver todos los usuarios' : null,
      onAction: hasSearch ? _clearSearch : null,
    );
  }
}

class _UserTableHeader extends StatelessWidget {
  const _UserTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: context.appColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.text.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Usuario / correo', style: style)),
          Expanded(flex: 2, child: Text('DNI', style: style)),
          Expanded(flex: 2, child: Text('Teléfono', style: style)),
          SizedBox(width: 112, child: Text('Estado', style: style)),
          const SizedBox(width: 144),
        ],
      ),
    );
  }
}

class _UserItem extends StatelessWidget {
  const _UserItem({
    required this.user,
    required this.compact,
    required this.busy,
    required this.onManage,
  });

  final AdminUserSummary user;
  final bool compact;
  final bool busy;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final actions = TextButton.icon(
      onPressed: onManage,
      style: TextButton.styleFrom(
        foregroundColor: context.appColors.textSecondary,
      ),
      iconAlignment: IconAlignment.end,
      icon: busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, size: 20),
      label: Text(compact ? 'Gestionar usuario' : 'Gestionar'),
    );
    if (compact) {
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
            _UserIdentity(user: user),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    constraints.maxWidth < 240 ||
                        MediaQuery.textScalerOf(context).scale(14) > 18
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _UserData(label: 'DNI', value: user.dni),
                    ),
                    SizedBox(
                      width: width,
                      child: _UserData(
                        label: 'Teléfono',
                        value: user.phone ?? '',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  _AccountStatus(enabled: user.enabled),
                  actions,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(
          bottom: BorderSide(color: context.appColors.borderVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _UserIdentity(user: user, compact: true),
            ),
          ),
          Expanded(flex: 2, child: _UserData(value: user.dni)),
          Expanded(flex: 2, child: _UserData(value: user.phone ?? '')),
          SizedBox(
            width: 112,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _AccountStatus(enabled: user.enabled),
            ),
          ),
          SizedBox(width: 144, child: actions),
        ],
      ),
    );
  }
}

class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.user, this.compact = false});

  final AdminUserSummary user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final parts = [
      user.name.trim(),
      user.lastName.trim(),
    ].where((part) => part.isNotEmpty);
    final name = parts.join(' ');
    final initials = parts
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: initials.isEmpty
                ? Icon(Icons.person_outline, color: context.appColors.icon)
                : Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Sin nombre registrado' : name,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: user.email,
                child: Text(
                  user.email.isEmpty ? 'Sin correo registrado' : user.email,
                  maxLines: compact ? 1 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.appColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserData extends StatelessWidget {
  const _UserData({required this.value, this.label});

  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null) ...[
        Text(
          label!,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: 4),
      ],
      SelectableText(
        value.isEmpty ? 'No registrado' : value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: value.isEmpty
              ? context.appColors.textTertiary
              : context.appColors.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

class _AccountStatus extends StatelessWidget {
  const _AccountStatus({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? context.appColors.success : context.appColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.pause_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            enabled ? 'Activo' : 'Inactivo',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.appColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.viewModel});

  final AdminUsersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Mostrando ${viewModel.users.length} de ${viewModel.totalElements}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (viewModel.isLoadingMore)
            const _LoadingMessage(message: 'Cargando más usuarios…')
          else if (viewModel.loadMoreError != null) ...[
            const SizedBox(height: 12),
            Text(viewModel.loadMoreError!, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: viewModel.retryLoadMore,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar carga'),
            ),
          ] else if (viewModel.hasMore) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: viewModel.isLoadingInitial ? null : viewModel.loadMore,
              icon: const Icon(Icons.expand_more),
              label: const Text('Cargar más usuarios'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appColors.textSecondary),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.appColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

enum _UserAction { information, roles, sereno }

typedef _UserSelection = ({_UserAction action, AdminUserDetail? detail});

class _UserManagementDialog extends StatefulWidget {
  const _UserManagementDialog({
    required this.user,
    required this.initialLoad,
    required this.viewModel,
  });

  final AdminUserSummary user;
  final Future<AdminUserDetail?> initialLoad;
  final AdminUsersViewModel viewModel;

  @override
  State<_UserManagementDialog> createState() => _UserManagementDialogState();
}

class _UserManagementDialogState extends State<_UserManagementDialog> {
  late Future<AdminUserDetail?> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.initialLoad;
  }

  void _select(_UserAction action, [AdminUserDetail? detail]) {
    Navigator.of(context).pop<_UserSelection>((action: action, detail: detail));
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestionar usuario',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar ficha',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _UserIdentity(user: widget.user),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _UserData(label: 'DNI', value: widget.user.dni),
                _UserData(label: 'Teléfono', value: widget.user.phone ?? ''),
                _AccountStatus(enabled: widget.user.enabled),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _ManagementAction(
              icon: Icons.edit_outlined,
              title: 'Editar información',
              description: 'Datos personales y configuración de la cuenta.',
              onTap: () => _select(_UserAction.information),
            ),
            FutureBuilder<AdminUserDetail?>(
              future: _detail,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _LoadingMessage(
                    message: 'Consultando roles y opciones…',
                  );
                }
                final detail = snapshot.data;
                if (detail == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FormError(
                        message:
                            widget.viewModel.actionError ??
                            'No se pudieron consultar los roles.',
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _detail = widget.viewModel.loadUserDetail(
                            widget.user.id,
                          );
                        }),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  );
                }
                final protected = detail.roles.any(
                  const {'OFFICER_ADMINISTRADOR', 'DEVELOPMENT'}.contains,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Roles actuales',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: context.appColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final role in detail.roles)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.text.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _roleLabel(role),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        if (detail.roles.isEmpty)
                          const Text('Sin roles asignados'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ManagementAction(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Editar roles',
                      description: protected
                          ? 'Los roles de esta cuenta se gestionan desde Desarrollo.'
                          : 'Asignar funciones de Ciudadano o Serenazgo.',
                      onTap: protected
                          ? null
                          : () => _select(_UserAction.roles, detail),
                    ),
                    if (detail.roles.contains('OFFICER_SERENO'))
                      _ManagementAction(
                        icon: Icons.badge_outlined,
                        title: 'Editar sereno',
                        description: 'Código de sereno y estado de servicio.',
                        onTap: () => _select(_UserAction.sereno, detail),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ManagementAction extends StatelessWidget {
  const _ManagementAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(description),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right, size: 20),
    enabled: onTap != null,
    onTap: onTap,
  );
}

String _roleLabel(String role) => switch (role) {
  'CITIZEN' => 'Ciudadano',
  'OFFICER_SERENO' => 'Serenazgo',
  'OFFICER_ADMINISTRADOR' => 'Administrador',
  'DEVELOPMENT' => 'Desarrollo',
  _ => role,
};

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(message, style: TextStyle(color: context.appColors.error)),
    ),
  );
}

class _EditSerenoDialog extends StatefulWidget {
  const _EditSerenoDialog({
    required this.user,
    required this.userId,
    required this.viewModel,
  });

  final AdminUserSummary user;
  final String userId;
  final AdminUsersViewModel viewModel;

  @override
  State<_EditSerenoDialog> createState() => _EditSerenoDialogState();
}

class _EditSerenoDialogState extends State<_EditSerenoDialog> {
  final _codeController = TextEditingController();
  AdminSerenoStatus? _status;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final code = _codeController.text.trim();
    if (code.isEmpty && _status == null) {
      setState(() => _error = 'Ingresa un código o selecciona un estado.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final updated = await widget.viewModel.updateSereno(
      widget.userId,
      AdminSerenoUpdateRequest(
        codeSereno: code.isEmpty ? null : code,
        serviceStatus: _status,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _error = updated ? null : widget.viewModel.actionError;
    });
    if (updated) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSaving,
    child: AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Editar sereno'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: _isSaving,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UserIdentity(user: widget.user),
                const SizedBox(height: 16),
                Text(
                  'Modifica solo los datos que necesitas cambiar.',
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  enabled: !_isSaving,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Código de sereno',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AdminSerenoStatus?>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado de servicio',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin cambios'),
                    ),
                    for (final status in AdminSerenoStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _status = value),
                ),
                if (_error != null) _FormError(message: _error!),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Guardando…' : 'Guardar cambios'),
        ),
      ],
    ),
  );
}

class _EditRolesDialog extends StatefulWidget {
  const _EditRolesDialog({
    required this.user,
    required this.summary,
    required this.viewModel,
  });

  final AdminUserDetail user;
  final AdminUserSummary summary;
  final AdminUsersViewModel viewModel;

  @override
  State<_EditRolesDialog> createState() => _EditRolesDialogState();
}

class _EditRolesDialogState extends State<_EditRolesDialog> {
  static const _citizenRole = 'CITIZEN';
  static const _officerRole = 'OFFICER_SERENO';

  final _formKey = GlobalKey<FormState>();
  late final Set<String> _selectedRoles;
  final _serenoCode = TextEditingController();
  final _citizenLatitude = TextEditingController();
  final _citizenLongitude = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRoles = widget.user.roles
        .where(const {_citizenRole, _officerRole}.contains)
        .toSet();
  }

  void _toggle(String role, bool selected) {
    setState(() {
      selected ? _selectedRoles.add(role) : _selectedRoles.remove(role);
    });
  }

  @override
  void dispose() {
    _serenoCode.dispose();
    _citizenLatitude.dispose();
    _citizenLongitude.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_selectedRoles.isEmpty || _formKey.currentState?.validate() != true) {
      setState(() {});
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final updated = await widget.viewModel.updateRoles(
      AdminUserRolesUpdateRequest(
        userId: widget.user.id,
        roles: Set.of(_selectedRoles),
        serenoCode: _selectedRoles.contains(_officerRole)
            ? _serenoCode.text.trim()
            : null,
        citizenLatitude: _selectedRoles.contains(_citizenRole)
            ? double.parse(_citizenLatitude.text.trim())
            : null,
        citizenLongitude: _selectedRoles.contains(_citizenRole)
            ? double.parse(_citizenLongitude.text.trim())
            : null,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _error = updated ? null : widget.viewModel.actionError;
    });
    if (updated) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSaving,
    child: AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Editar roles'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: _isSaving,
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UserIdentity(user: widget.summary),
                  const SizedBox(height: 16),
                  Text(
                    'Selecciona las funciones e ingresa los datos de cada perfil activo. Los datos enviados reemplazarán los actuales.',
                    style: TextStyle(color: context.appColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Serenazgo'),
                    subtitle: const Text(
                      'Puede atender incidencias asignadas.',
                    ),
                    value: _selectedRoles.contains(_officerRole),
                    onChanged: _isSaving
                        ? null
                        : (value) => _toggle(_officerRole, value ?? false),
                  ),
                  if (_selectedRoles.contains(_officerRole))
                    TextFormField(
                      controller: _serenoCode,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Código de sereno',
                      ),
                      maxLength: 30,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Ingresa el código de sereno.'
                          : null,
                    ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ciudadano'),
                    subtitle: const Text(
                      'Puede registrar y seguir incidencias.',
                    ),
                    value: _selectedRoles.contains(_citizenRole),
                    onChanged: _isSaving
                        ? null
                        : (value) => _toggle(_citizenRole, value ?? false),
                  ),
                  if (_selectedRoles.contains(_citizenRole)) ...[
                    _RoleCoordinateField(
                      controller: _citizenLatitude,
                      enabled: !_isSaving,
                      label: 'Latitud del domicilio',
                      min: -90,
                      max: 90,
                    ),
                    _RoleCoordinateField(
                      controller: _citizenLongitude,
                      enabled: !_isSaving,
                      label: 'Longitud del domicilio',
                      min: -180,
                      max: 180,
                    ),
                  ],
                  if (_selectedRoles.isEmpty)
                    Text(
                      'Selecciona al menos un rol.',
                      style: TextStyle(color: context.appColors.error),
                    ),
                  if (_error != null) _FormError(message: _error!),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Guardando…' : 'Guardar cambios'),
        ),
      ],
    ),
  );
}

class _RoleCoordinateField extends StatelessWidget {
  const _RoleCoordinateField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label, hintText: '-13.6512'),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}([.]\d{0,6})?')),
      ],
      validator: (value) {
        final coordinate = double.tryParse(value?.trim() ?? '');
        if (coordinate == null) return 'Ingresa una coordenada válida.';
        if (coordinate < min || coordinate > max) {
          return 'Debe estar entre $min y $max.';
        }
        return null;
      },
    ),
  );
}
