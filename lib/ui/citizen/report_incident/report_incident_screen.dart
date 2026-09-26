import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/citizen/report_incident/view_models/report_incident_view_model.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController(
    text: 'Av. Jose Maria Arguedas',
  ); // Valor por defecto visual

  @override
  void dispose() {
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, ReportIncidentViewModel viewModel) async {
    // Si no ha ingresado descripción, le ponemos un valor por defecto o mostramos error.
    // Para simplificar la demo visual y que coincida con la imagen (donde no hay campo de descripción visible explícito),
    // usaremos un texto si está vacío.
    final description = _descriptionController.text.trim().isEmpty
        ? 'Reporte desde la app ciudadana'
        : _descriptionController.text.trim();

    if (viewModel.selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un tipo de incidente')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await viewModel.submitIncident(
      description: description,
      referenceAddress: _referenceController.text.trim(),
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incidente reportado exitosamente'),
          backgroundColor: context.appColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildCategoryIcon(String name) {
    String emoji = '⚠️';
    if (name.toLowerCase().contains('robo') ||
        name.toLowerCase().contains('asalto')) {
      emoji = '🚨';
    } else if (name.toLowerCase().contains('ruido')) {
      emoji = '🔊';
    } else if (name.toLowerCase().contains('accidente') ||
        name.toLowerCase().contains('choque')) {
      emoji = '🚗';
    } else if (name.toLowerCase().contains('incendio') ||
        name.toLowerCase().contains('fuego')) {
      emoji = '🔥';
    }

    return Text(emoji, style: const TextStyle(fontSize: 24));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.textInverse,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo Reporte De Incidente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'SOS San Jerónimo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ResponsiveBody(
        child: Consumer<ReportIncidentViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ¿Qué está sucediendo? - Puede actuar como el input de descripción
                    Container(
                      decoration: BoxDecoration(
                        color: context.appColors.infoLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.text,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '¿Qué está sucediendo?',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.text,
                          ),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TIPO DE INCIDENTE
                    Text(
                      'TIPO DE INCIDENTE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid de categorías
                    if (viewModel.isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (viewModel.errorMessage != null &&
                        viewModel.categories.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: context.appColors.error),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisExtent:
                              100 + MediaQuery.textScalerOf(context).scale(56),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: viewModel.categories.length,
                        itemBuilder: (context, index) {
                          final category = viewModel.categories[index];
                          final isSelected =
                              viewModel.selectedCategory?.id == category.id;

                          return GestureDetector(
                            onTap: () =>
                                viewModel.setSelectedCategory(category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.appColors.primary
                                    : context.appColors.card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.appColors.textSecondary
                                        .withAlpha(20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildCategoryIcon(category.name),
                                      const SizedBox(height: 8),
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isSelected
                                              ? context.appColors.textInverse
                                              : context.appColors.text,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        category.description,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? context.appColors.textInverse
                                                    .withValues(alpha: 0.7)
                                              : context.appColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: context.appColors.info,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: context.appColors.textInverse,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Evidencia multimedia
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attachment,
                                color: context.appColors.info,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Agregar evidencia multimedia',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.appColors.text,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appColors.infoLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: context.appColors.info,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tomar foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.appColors.info,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appColors.infoLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.mic_none_outlined,
                                        color: context.appColors.info,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Grabar audio',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.appColors.info,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Mock de evidencia subida
                          Container(
                            padding: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: context.appColors.infoLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Container(
                                    width: 80,
                                    height: 60,
                                    color: context.appColors.textTertiary,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          color: context.appColors.textInverse,
                                          size: 30,
                                        ),
                                        Positioned(
                                          child: Icon(
                                            Icons.check_circle_outline,
                                            color: context.appColors.textInverse,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'evidencia_01.jpg',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '1.8 MB · Imagen lista',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              context.appColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.close,
                                  size: 20,
                                  color: context.appColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Ubicación
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: context.appColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ubicación detectada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.text,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.infoLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: context.appColors.info,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GPS ACTIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Text field para la dirección (camuflado como texto)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          color: context.appColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _referenceController,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: context.appColors.text,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botones de acción inferior
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appColors.infoLight.withAlpha(150),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: viewModel.isSubmitting
                                  ? null
                                  : () => _submit(context, viewModel),
                              icon: viewModel.isSubmitting
                                  ? const SizedBox()
                                  : Icon(
                                      Icons.report_problem,
                                      color: context.appColors.textInverse,
                                    ),
                              label: viewModel.isSubmitting
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: context.appColors.textInverse,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'ENVIAR ALERTA INMEDIATA',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.textInverse,
                                        letterSpacing: 1,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                backgroundColor: context.appColors.error,
                                foregroundColor: context.appColors.textInverse,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 56),
                                padding: const EdgeInsets.all(16),
                                backgroundColor: context.appColors.infoLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar reporte',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: context.appColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
