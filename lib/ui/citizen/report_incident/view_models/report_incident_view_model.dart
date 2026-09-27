import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/file/image_api_service.dart';

class ReportIncidentViewModel extends ChangeNotifier {
  ReportIncidentViewModel(this._repository, this._storageService) {
    _loadCategories();
  }

  final IncidentRepository _repository;
  final StorageService _storageService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isUploadingImage = false;
  bool get isUploadingImage => _isUploadingImage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<IncidentCategory> _categories = [];
  List<IncidentCategory> get categories => _categories;

  IncidentCategory? _selectedCategory;
  IncidentCategory? get selectedCategory => _selectedCategory;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  void setSelectedCategory(IncidentCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      _imageUrl = null;
      notifyListeners();
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _storageService.uploadImage(file: _selectedImage!);
      _imageUrl = response.publicUrl;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al subir imagen: ${e.toString()}';
      _selectedImage = null;
      _imageUrl = null;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  void removeImage() {
    _selectedImage = null;
    _imageUrl = null;
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
      imageUrl: _imageUrl,
    );

    final result = await _repository.createIncident(request);

    _isSubmitting = false;
    if (result.isSuccess) {
      notifyListeners();
      return true;
    } else {
      _errorMessage =
          result.failure?.message ?? 'Error al reportar el incidente';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
