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

  ImageUploadResponse? _uploadedImage;
  String? get imageUrl => _uploadedImage?.publicUrl;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;
  bool _disposed = false;

  void setSelectedCategory(IncidentCategory? category) {
    _selectedCategory = category;
    _notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    if (_isSubmitting || _isUploadingImage) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      _uploadedImage = null;
      _errorMessage = null;
      _notifyListeners();
    }
  }

  void removeImage() {
    _selectedImage = null;
    _uploadedImage = null;
    _notifyListeners();
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
    if (_isSubmitting) return false;
    if (_selectedCategory == null) {
      _errorMessage = 'Por favor selecciona una categoría';
      _notifyListeners();
      return false;
    }
    if (_selectedImage == null && _uploadedImage == null) {
      _errorMessage = 'Agrega una imagen como evidencia';
      _notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      if (_uploadedImage == null) {
        _isUploadingImage = true;
        _notifyListeners();
        _uploadedImage = await _storageService.uploadImage(
          file: _selectedImage!,
          folder: 'INCIDENTS',
        );
        _isUploadingImage = false;
        _notifyListeners();
      }

      // Coordenadas temporales hasta implementar la ubicación del dispositivo.
      final request = IncidentCreateRequest(
        description: description,
        referenceAddress: referenceAddress,
        latitude: -12.046374,
        longitude: -77.042793,
        categoryId: _selectedCategory!.id,
        evidence: IncidentEvidenceCreateRequest(
          fileUrl: _uploadedImage!.publicUrl,
          fileName: _fileNameFromKey(_uploadedImage!.fileKey),
          fileType: _uploadedImage!.contentType,
        ),
      );

      final result = await _repository.createIncident(request);
      if (result.isSuccess) return true;

      _errorMessage =
          result.failure?.message ?? 'Error al reportar el incidente';
      return false;
    } catch (error) {
      _errorMessage = 'Error al subir imagen: $error';
      return false;
    } finally {
      _isUploadingImage = false;
      _isSubmitting = false;
      _notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifyListeners();
  }

  String _fileNameFromKey(String fileKey) {
    final normalized = fileKey.replaceAll('\\', '/');
    final segments = normalized.split('/');
    final fileName = segments.isEmpty ? '' : segments.last.trim();
    return fileName.isEmpty ? 'incident-image' : fileName;
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
