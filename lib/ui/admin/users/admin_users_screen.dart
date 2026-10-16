import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_user_roles_update_request.dart';
import 'package:sereno_ya/data/models/admin/admin_user_summary.dart';
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
    context.read<AdminUsersViewModel>().loadMore();
  }

  Future<void> _openRoleEditor(AdminUserSummary user) async {
    final request = await showDialog<AdminUserRolesUpdateRequest>(
      context: context,
      builder: (_) => _EditRolesDialog(user: user),
    );
    if (!mounted || request == null) return;

    final viewModel = context.read<AdminUsersViewModel>();
    final updated = await viewModel.updateRoles(request);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'Los roles se actualizaron correctamente.'
              : viewModel.updateRolesError ??
                    'No se pudieron actualizar los roles.',
        ),
      ),
    );
  }

  Future<void> _openUserEditor(AdminUserSummary user) async {
    final updated = await context.push<bool>(RouteNames.adminUserEdit(user.id));
    if (!mounted || updated != true) return;
    await context.read<AdminUsersViewModel>().loadInitial(forceRefresh: true);
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
    final viewModel = context.watch<AdminUsersViewModel>();
    return ColoredBox(
      color: context.appColors.background,
      child: ResponsiveBody(
        maxWidth: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UsersHeader(viewModel: viewModel),
            if (viewModel.isLoadingInitial)
              const LinearProgressIndicator(minHeight: 2),
            if (viewModel.errorMessage != null && viewModel.users.isNotEmpty)
              _InlineError(
                message: viewModel.errorMessage!,
                onRetry: () => viewModel.loadInitial(forceRefresh: true),
              ),
            Expanded(child: _buildContent(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AdminUsersViewModel viewModel) {
    if (viewModel.isLoadingInitial && viewModel.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
    if (viewModel.users.isEmpty) {
      return _StateMessage(
        icon: Icons.group_off_outlined,
        title: 'No hay usuarios para mostrar',
        message: viewModel.roleFilter == null
            ? 'Los usuarios registrados aparecerán aquí.'
            : 'No se encontraron usuarios con el rol seleccionado.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final footerVisible =
            viewModel.isLoadingMore || viewModel.loadMoreError != null;
        return RefreshIndicator(
          onRefresh: () => viewModel.loadInitial(forceRefresh: true),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              0,
              compact ? 16 : 24,
              96,
            ),
            itemCount:
                viewModel.users.length +
                (compact ? 0 : 1) +
                (footerVisible ? 1 : 0),
            separatorBuilder: (_, _) => SizedBox(height: compact ? 12 : 0),
            itemBuilder: (context, index) {
              if (!compact && index == 0) return const _UserTableHeader();
              final userIndex = compact ? index : index - 1;
              if (userIndex == viewModel.users.length) {
                return _PaginationFooter(
                  loading: viewModel.isLoadingMore,
                  message: viewModel.loadMoreError,
                  onRetry: viewModel.retryLoadMore,
                );
              }
              return _UserItem(
                user: viewModel.users[userIndex],
                compact: compact,
                updating:
                    viewModel.updatingUserId == viewModel.users[userIndex].id,
                onEditUser: () => _openUserEditor(viewModel.users[userIndex]),
                onEditRoles: () => _openRoleEditor(viewModel.users[userIndex]),
              );
            },
          ),
        );
      },
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({required this.viewModel});

  final AdminUsersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Directorio de usuarios',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${viewModel.users.length} visibles de ${viewModel.totalElements}',
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            ],
          );
          final filter = SizedBox(
            width: compact ? double.infinity : 240,
            child: DropdownButtonFormField<AdminUserRoleFilter?>(
              initialValue: viewModel.roleFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por rol',
                prefixIcon: Icon(Icons.filter_alt_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final role in AdminUserRoleFilter.values)
                  DropdownMenuItem(value: role, child: Text(role.label)),
              ],
              onChanged: viewModel.isLoadingInitial
                  ? null
                  : viewModel.selectRole,
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 16), filter],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: summary),
              filter,
            ],
          );
        },
      ),
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
        color: context.appColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('USUARIO', style: style)),
          Expanded(flex: 3, child: Text('ROLES', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(flex: 2, child: Text('AVISOS', style: style)),
          SizedBox(width: 96, child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }
}

class _UserItem extends StatelessWidget {
  const _UserItem({
    required this.user,
    required this.compact,
    required this.updating,
    required this.onEditUser,
    required this.onEditRoles,
  });

  final AdminUserSummary user;
  final bool compact;
  final bool updating;
  final VoidCallback onEditUser;
  final VoidCallback onEditRoles;

  bool get _hasProtectedRole =>
      user.roles.any(const {'OFFICER_ADMINISTRADOR', 'DEVELOPMENT'}.contains);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.borderVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UserAvatar(imageUrl: user.imageUrl),
                const SizedBox(width: 12),
                Expanded(child: _UserIdentity(user: user)),
                _AccountStatus(enabled: user.enabled),
                const SizedBox(width: 4),
                _UserActions(
                  updating: updating,
                  protected: _hasProtectedRole,
                  onEditUser: onEditUser,
                  onEditRoles: onEditRoles,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in user.roles) _RoleBadge(role: role),
                _NotificationStatus(enabled: user.notificationsEnabled),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Row(
              children: [
                _UserAvatar(imageUrl: user.imageUrl),
                const SizedBox(width: 12),
                Expanded(child: _UserIdentity(user: user)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final role in user.roles) _RoleBadge(role: role)],
            ),
          ),
          Expanded(flex: 2, child: _AccountStatus(enabled: user.enabled)),
          Expanded(
            flex: 2,
            child: _NotificationStatus(enabled: user.notificationsEnabled),
          ),
          SizedBox(
            width: 96,
            child: _UserActions(
              updating: updating,
              protected: _hasProtectedRole,
              onEditUser: onEditUser,
              onEditRoles: onEditRoles,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.updating,
    required this.protected,
    required this.onEditUser,
    required this.onEditRoles,
  });

  final bool updating;
  final bool protected;
  final VoidCallback onEditUser;
  final VoidCallback onEditRoles;

  @override
  Widget build(BuildContext context) {
    if (updating) {
      return const Center(
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final tooltip = protected
        ? 'Solo desarrollo puede modificar este usuario'
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: tooltip ?? 'Editar información',
          onPressed: protected ? null : onEditUser,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: tooltip ?? 'Editar roles',
          onPressed: protected ? null : onEditRoles,
          icon: const Icon(Icons.manage_accounts_outlined),
        ),
      ],
    );
  }
}

class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.user});

  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.phone ?? 'Sin teléfono registrado',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        SelectableText(
          user.id,
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.appColors.textTertiary),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => ColoredBox(
      color: context.appColors.surfaceVariant,
      child: Icon(Icons.person_outline, color: context.appColors.icon),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: 42,
        child: imageUrl == null
            ? fallback()
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback(),
              ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.appColors.infoLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _roleLabel(role),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.appColors.info,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AccountStatus extends StatelessWidget {
  const _AccountStatus({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? context.appColors.success : context.appColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          size: 17,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          enabled ? 'Activo' : 'Inactivo',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _NotificationStatus extends StatelessWidget {
  const _NotificationStatus({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          enabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          size: 18,
          color: context.appColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          enabled ? 'Activados' : 'Desactivados',
          style: TextStyle(color: context.appColors.textSecondary),
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(message ?? 'Reintentar'),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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

class _EditRolesDialog extends StatefulWidget {
  const _EditRolesDialog({required this.user});

  final AdminUserSummary user;

  @override
  State<_EditRolesDialog> createState() => _EditRolesDialogState();
}

class _EditRolesDialogState extends State<_EditRolesDialog> {
  static const _citizenRole = 'CITIZEN';
  static const _officerRole = 'OFFICER_SERENO';

  final _formKey = GlobalKey<FormState>();
  late final Set<String> _selectedRoles;

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

  void _submit() {
    if (_selectedRoles.isEmpty || _formKey.currentState?.validate() != true) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(
      AdminUserRolesUpdateRequest(
        userId: widget.user.id,
        roles: _selectedRoles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar roles'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selecciona las funciones que tendrá este usuario.',
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Serenazgo'),
                  subtitle: const Text('Puede atender incidencias asignadas.'),
                  value: _selectedRoles.contains(_officerRole),
                  onChanged: (value) => _toggle(_officerRole, value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ciudadano'),
                  subtitle: const Text('Puede registrar y seguir incidencias.'),
                  value: _selectedRoles.contains(_citizenRole),
                  onChanged: (value) => _toggle(_citizenRole, value ?? false),
                ),
                if (_selectedRoles.isEmpty)
                  Text(
                    'Selecciona al menos un rol.',
                    style: TextStyle(color: context.appColors.error),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

String _roleLabel(String role) => switch (role) {
  'CITIZEN' => 'Ciudadano',
  'OFFICER_SERENO' => 'Serenazgo',
  'OFFICER_ADMINISTRADOR' => 'Administrador',
  'DEVELOPMENT' => 'Desarrollo',
  _ => role,
};
