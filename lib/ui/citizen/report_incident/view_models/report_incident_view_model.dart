import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';

class ReportIncidentViewModel extends ChangeNotifier {
  ReportIncidentViewModel(this._repository) {
    _loadCategories();
  }

  final IncidentRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<IncidentCategory> _categories = [];
  List<IncidentCategory> get categories => _categories;

  IncidentCategory? _selectedCategory;
  IncidentCategory? get selectedCategory => _selectedCategory;

  void setSelectedCategory(IncidentCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    _setLoading(true);
    final result = await _repository.getCategories();
    if (result.isSuccess && result.data != null) {
      _categories = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.failure?.message ?? 'Error al cargar categorías';
    }
    _setLoading(false);
  }

  Future<bool> submitIncident({
    required String description,
    required String referenceAddress,
  }) async {
    if (_selectedCategory == null) {
      _errorMessage = 'Por favor selecciona una categoría';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    // Usando coordenadas mockeadas para el ejemplo (centro de Lima)
    final request = IncidentCreateRequest(
      description: description,
      referenceAddress: referenceAddress,
      latitude: -12.046374,
      longitude: -77.042793,
      categoryId: _selectedCategory!.id,
    );

    final result = await _repository.createIncident(request);
    
    _isSubmitting = false;
    if (result.isSuccess) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.failure?.message ?? 'Error al reportar el incidente';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
