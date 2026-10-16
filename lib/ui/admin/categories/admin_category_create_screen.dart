import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_category_create_request.dart';
import 'package:sereno_ya/ui/admin/categories/view_models/admin_category_create_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AdminCategoryCreateScreen extends StatefulWidget {
  const AdminCategoryCreateScreen({super.key});

  @override
  State<AdminCategoryCreateScreen> createState() =>
      _AdminCategoryCreateScreenState();
}

class _AdminCategoryCreateScreenState extends State<AdminCategoryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;

    final category = await context
        .read<AdminCategoryCreateViewModel>()
        .createCategory(
          AdminCategoryCreateRequest(
            name: _name.text,
            description: _description.text,
          ),
        );
    if (!mounted || category == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('La categoría ${category.name} fue creada.')),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminCategoryCreateViewModel>();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(title: const Text('Nueva categoría')),
      body: ResponsiveBody(
        maxWidth: 760,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crear categoría de incidencia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Define cómo se identificará este tipo de reporte para ciudadanos y serenazgo.',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appColors.borderVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Ej. Accidente de tránsito',
                          prefixIcon: Icon(Icons.category_outlined),
                          counterText: '',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                        validator: (value) => _required(
                          value,
                          'Ingresa el nombre de la categoría.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _description,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Explica brevemente qué situaciones pertenecen a esta categoría.',
                          alignLabelWithHint: true,
                        ),
                        minLines: 4,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(250),
                        ],
                        validator: (value) => _required(
                          value,
                          'Ingresa una descripción para la categoría.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: context.appColors.info),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'El servidor generará el identificador UUID y la categoría quedará activa automáticamente.',
                        ),
                      ),
                    ],
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorMessage(message: viewModel.errorMessage!),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: viewModel.isSubmitting ? null : _submit,
                    icon: viewModel.isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      viewModel.isSubmitting ? 'Creando...' : 'Crear categoría',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.appColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String? _required(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;
