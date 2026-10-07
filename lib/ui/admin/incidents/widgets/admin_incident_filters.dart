import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/ui/admin/incidents/view_models/admin_incidents_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

Future<AdminIncidentFilters?> showAdminIncidentFilters(
  BuildContext context, {
  required AdminIncidentFilters initialFilters,
  required List<IncidentCategory> categories,
  String? categoryError,
}) {
  final compact = MediaQuery.sizeOf(context).width < 700;
  final content = _AdminIncidentFilterForm(
    initialFilters: initialFilters,
    categories: categories,
    categoryError: categoryError,
  );

  if (compact) {
    return showModalBottomSheet<AdminIncidentFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => content,
    );
  }
  return showDialog<AdminIncidentFilters>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: content,
      ),
    ),
  );
}

class _AdminIncidentFilterForm extends StatefulWidget {
  const _AdminIncidentFilterForm({
    required this.initialFilters,
    required this.categories,
    this.categoryError,
  });

  final AdminIncidentFilters initialFilters;
  final List<IncidentCategory> categories;
  final String? categoryError;

  @override
  State<_AdminIncidentFilterForm> createState() =>
      _AdminIncidentFilterFormState();
}

class _AdminIncidentFilterFormState extends State<_AdminIncidentFilterForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _citizenController;
  late final TextEditingController _serenoController;
  AdminIncidentStatusFilter? _status;
  String? _categoryId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    _status = initial.status;
    _categoryId = initial.categoryId;
    _fromDate = initial.fromDate;
    _toDate = initial.toDate;
    _citizenController = TextEditingController(
      text: initial.citizenUserId ?? '',
    );
    _serenoController = TextEditingController(text: initial.serenoUserId ?? '');
  }

  @override
  void dispose() {
    _citizenController.dispose();
    _serenoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar incidencias',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownMenu<AdminIncidentStatusFilter?>(
                initialSelection: _status,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Estado'),
                dropdownMenuEntries: [
                  const DropdownMenuEntry(value: null, label: 'Todos'),
                  ...AdminIncidentStatusFilter.values.map(
                    (status) =>
                        DropdownMenuEntry(value: status, label: status.label),
                  ),
                ],
                onSelected: (value) => _status = value,
              ),
              const SizedBox(height: 16),
              DropdownMenu<String?>(
                initialSelection: _categoryId,
                enabled: widget.categories.isNotEmpty,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Categoría'),
                dropdownMenuEntries: [
                  const DropdownMenuEntry(value: null, label: 'Todas'),
                  ...widget.categories.map(
                    (category) => DropdownMenuEntry(
                      value: category.id,
                      label: category.name,
                    ),
                  ),
                ],
                onSelected: (value) => _categoryId = value,
              ),
              if (widget.categoryError != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.categoryError!,
                  style: TextStyle(
                    color: context.appColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Fecha de reporte',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final from = _DateButton(
                    label: 'Desde',
                    value: _fromDate,
                    onPressed: () => _pickDate(isFrom: true),
                  );
                  final to = _DateButton(
                    label: 'Hasta',
                    value: _toDate,
                    onPressed: () => _pickDate(isFrom: false),
                  );
                  if (constraints.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [from, const SizedBox(height: 8), to],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: from),
                      const SizedBox(width: 12),
                      Expanded(child: to),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _citizenController,
                decoration: const InputDecoration(
                  labelText: 'ID de usuario ciudadano',
                  hintText: 'UUID opcional',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validateOptionalUuid,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serenoController,
                decoration: const InputDecoration(
                  labelText: 'ID de usuario sereno',
                  hintText: 'UUID opcional',
                  prefixIcon: Icon(Icons.local_police_outlined),
                ),
                validator: _validateOptionalUuid,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(onPressed: _clear, child: const Text('Limpiar')),
                  FilledButton.icon(
                    onPressed: _apply,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Aplicar filtros'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _fromDate : _toDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = selected;
      } else {
        _toDate = selected;
      }
    });
  }

  void _clear() {
    setState(() {
      _status = null;
      _categoryId = null;
      _fromDate = null;
      _toDate = null;
      _citizenController.clear();
      _serenoController.clear();
    });
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha inicial no puede ser posterior a la fecha final.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      AdminIncidentFilters(
        status: _status,
        categoryId: _categoryId,
        citizenUserId: _emptyToNull(_citizenController.text),
        serenoUserId: _emptyToNull(_serenoController.text),
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          value == null ? label : DateFormat('dd/MM/yyyy').format(value!),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

String? _validateOptionalUuid(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return null;
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuid.hasMatch(normalized) ? null : 'Ingresa un UUID válido';
}

String? _emptyToNull(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
