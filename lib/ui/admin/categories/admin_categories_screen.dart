import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_category_update_request.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/ui/admin/categories/view_models/admin_categories_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminCategoriesViewModel>();
    return ColoredBox(
      color: context.appColors.background,
      child: ResponsiveBody(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategoriesHeader(viewModel: viewModel),
            if (viewModel.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            if (viewModel.errorMessage != null &&
                viewModel.categories.isNotEmpty)
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
    AdminCategoriesViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null && viewModel.categories.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudieron cargar las categorías',
        message: viewModel.errorMessage!,
        actionLabel: 'Reintentar',
        onAction: () => viewModel.loadInitial(forceRefresh: true),
      );
    }
    if (viewModel.categories.isEmpty) {
      return const _StateMessage(
        icon: Icons.category_outlined,
        title: 'No hay categorías registradas',
        message: 'Crea la primera categoría para clasificar las incidencias.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadInitial(forceRefresh: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
        itemCount: viewModel.categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final category = viewModel.categories[index];
          return _CategoryItem(
            category: category,
            updating: viewModel.updatingCategoryId == category.id,
            onEdit: () => _editCategory(context, viewModel, category),
          );
        },
      ),
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    AdminCategoriesViewModel viewModel,
    IncidentCategory category,
  ) async {
    final request = await showDialog<AdminCategoryUpdateRequest>(
      context: context,
      builder: (_) => _EditCategoryDialog(category: category),
    );
    if (!context.mounted || request == null) return;

    final updated = await viewModel.updateCategory(category.id, request);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'La categoría se actualizó correctamente.'
              : viewModel.updateError ?? 'No se pudo actualizar la categoría.',
        ),
      ),
    );
  }
}

class _CategoriesHeader extends StatelessWidget {
  const _CategoriesHeader({required this.viewModel});

  final AdminCategoriesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final activeCount = viewModel.categories
        .where((category) => category.enabled)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogo de categorías',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(
            '$activeCount activas de ${viewModel.totalElements} registradas',
            style: TextStyle(color: context.appColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.updating,
    required this.onEdit,
  });

  final IncidentCategory category;
  final bool updating;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final statusColor = category.enabled
        ? context.appColors.success
        : context.appColors.textTertiary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.borderVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.category_outlined, color: context.appColors.icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: category.enabled
                            ? context.appColors.successLight
                            : context.appColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category.enabled ? 'Activa' : 'Inactiva',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  category.description,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Editar categoría',
            onPressed: updating ? null : onEdit,
            icon: updating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _EditCategoryDialog extends StatefulWidget {
  const _EditCategoryDialog({required this.category});

  final IncidentCategory category;

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category.name);
    _description = TextEditingController(text: widget.category.description);
    _enabled = widget.category.enabled;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      AdminCategoryUpdateRequest(
        name: _name.text,
        description: _description.text,
        enabled: _enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar categoría'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  validator: (value) =>
                      _required(value, 'Ingresa el nombre de la categoría.'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(250)],
                  validator: (value) => _required(
                    value,
                    'Ingresa la descripción de la categoría.',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Categoría activa'),
                  subtitle: const Text(
                    'Las categorías inactivas no podrán usarse en nuevos reportes.',
                  ),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
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
        FilledButton(onPressed: _submit, child: const Text('Guardar cambios')),
      ],
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String? _required(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;
