import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/config/maps_config.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/data/services/maps/reverse_geocode_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/file/image_api_service.dart';

class _EvidenceDraft {
  _EvidenceDraft(this.file);

  final File file;
  ImageUploadResponse? upload;
}

class ReportIncidentViewModel extends ChangeNotifier {
  ReportIncidentViewModel(
    this._repository,
    this._storageService, {
    CitizenLocationService? locationService,
    ReverseGeocodeService? reverseGeocodeService,
  }) : _locationService = locationService ?? CitizenLocationService(),
       _reverseGeocodeService =
           reverseGeocodeService ?? ReverseGeocodeService() {
    _loadCategories();
  }

  final IncidentRepository _repository;
  final StorageService _storageService;
  final CitizenLocationService _locationService;
  final ReverseGeocodeService _reverseGeocodeService;
  bool _isLocating = false;
  bool get isLocating => _isLocating;

  bool _isResolvingAddress = false;
  bool get isResolvingAddress => _isResolvingAddress;

  /// Resuelve la dirección con Google Geocoding API sin bloquear el reporte.
  /// Devuelve `null` si no hay clave configurada, no hay resultados o falla
  /// la red; el usuario siempre puede escribir la referencia manualmente.
  Future<String?> resolveAddress(LatLng location) async {
    if (_isResolvingAddress) return null;
    if (MapsConfig.apiKey.isEmpty) return null;
    _isResolvingAddress = true;
    _notifyListeners();
    try {
      return await _reverseGeocodeService.formattedAddress(
        latitude: location.latitude,
        longitude: location.longitude,
        apiKey: MapsConfig.apiKey,
      );
    } finally {
      _isResolvingAddress = false;
      _notifyListeners();
    }
  }

  Future<LatLng?> locateCitizen() async {
    if (_isLocating || _isSubmitting) return null;
    _isLocating = true;
    _errorMessage = null;
    _notifyListeners();
    try {
      return await _locationService.currentLocation();
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'No se pudo obtener tu ubicación. Revisa los permisos y vuelve a intentar.';
      return null;
    } finally {
      _isLocating = false;
      _notifyListeners();
    }
  }

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

  ImageUploadResponse? get _firstUpload =>
      _drafts.where((item) => item.upload != null).isEmpty
      ? null
      : _drafts.firstWhere((item) => item.upload != null).upload;

  /// Máximo de evidencias por reporte para no saturar la subida.
  static const int maxEvidences = 5;

  List<File> get selectedImages =>
      List<File>.unmodifiable(_drafts.map((item) => item.file));
  List<String> get imageUrls => _drafts
      .where((item) => item.upload != null)
      .map((item) => item.upload!.publicUrl)
      .toList(growable: false);
  int get evidenceCount => _drafts.length;
  bool get hasEvidence => _drafts.isNotEmpty;

  // Compatibilidad con la vista de una sola imagen.
  String? get imageUrl => _firstUpload?.publicUrl;
  File? get selectedImage => _drafts.isEmpty ? null : _drafts.first.file;
  final List<_EvidenceDraft> _drafts = [];
  bool _disposed = false;

  void setSelectedCategory(IncidentCategory? category) {
    _selectedCategory = category;
    _notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    if (_isSubmitting || _isUploadingImage) return;
    if (_drafts.length >= maxEvidences) {
      _errorMessage = 'Puedes agregar hasta $maxEvidences evidencias';
      _notifyListeners();
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      _drafts.add(_EvidenceDraft(File(pickedFile.path)));
      _errorMessage = null;
      _notifyListeners();
    }
  }

  /// Galería con selección múltiple; agrega hasta [maxEvidences] en total.
  Future<void> pickGalleryImages() async {
    if (_isSubmitting || _isUploadingImage) return;
    final remaining = maxEvidences - _drafts.length;
    if (remaining <= 0) {
      _errorMessage = 'Puedes agregar hasta $maxEvidences evidencias';
      _notifyListeners();
      return;
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (pickedFiles.isEmpty) return;
    for (final picked in pickedFiles.take(remaining)) {
      _drafts.add(_EvidenceDraft(File(picked.path)));
    }
    if (pickedFiles.length > remaining) {
      _errorMessage = 'Puedes agregar hasta $maxEvidences evidencias';
    } else {
      _errorMessage = null;
    }
    _notifyListeners();
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= _drafts.length) return;
    _drafts.removeAt(index);
    _notifyListeners();
  }

  void removeImage() {
    _drafts.clear();
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
    required LatLng location,
  }) async {
    if (_isSubmitting) return false;
    if (_selectedCategory == null) {
      _errorMessage = 'Por favor selecciona una categoría';
      _notifyListeners();
      return false;
    }
    if (_drafts.isEmpty) {
      _errorMessage = 'Agrega al menos una imagen como evidencia';
      _notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      _isUploadingImage = true;
      _notifyListeners();
      for (final draft in _drafts) {
        draft.upload ??= await _storageService.uploadImage(
          file: draft.file,
          folder: 'INCIDENTS',
        );
      }
      _isUploadingImage = false;
      _notifyListeners();

      final request = IncidentCreateRequest(
        description: description,
        referenceAddress: referenceAddress,
        latitude: location.latitude,
        longitude: location.longitude,
        categoryName: _selectedCategory!.name,
        evidences: _drafts
            .map(
              (draft) => IncidentEvidenceCreateRequest(
                fileUrl: draft.upload!.publicUrl,
                fileName: _fileNameFromKey(draft.upload!.fileKey),
                fileType: draft.upload!.contentType,
              ),
            )
            .toList(),
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
