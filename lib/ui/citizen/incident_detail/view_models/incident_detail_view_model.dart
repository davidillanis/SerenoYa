import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/officer/contact_service.dart';

class IncidentDetailViewModel extends ChangeNotifier {
  IncidentDetailViewModel(
    this._repository,
    this._incidentId, {
    String? cacheOwnerId,
    this.requireAdminDetails = false,
    this.contactService = const ContactService(),
  }) {
    if (cacheOwnerId != null) {
      _repository.useCacheForUser(cacheOwnerId);
    }
    _incident = _repository.getCachedIncidentById(
      _incidentId,
      requireAdminDetails: requireAdminDetails,
    );
    if (_incident == null) {
      load();
    }
  }

  final IncidentRepository _repository;
  final String _incidentId;
  final ContactService contactService;
  final bool requireAdminDetails;

  static const _contactableStatuses = {'ACCEPTED', 'ON_SITE'};

  Incident? _incident;
  Incident? get incident => _incident;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isCallingContact = false;
  bool get isCallingContact => _isCallingContact;

  String? _contactErrorMessage;
  String? get contactErrorMessage => _contactErrorMessage;

  bool get canContactSereno => _contactableStatuses.contains(_incident?.status);

  bool _disposed = false;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    final result = await _repository.getIncidentById(
      _incidentId,
      forceRefresh: forceRefresh,
      requireAdminDetails: requireAdminDetails,
    );
    if (result.isSuccess && result.data != null) {
      _incident = result.data;
    } else {
      _errorMessage =
          result.failure?.message ?? 'No se pudo cargar la incidencia';
    }

    _isLoading = false;
    _notifyListeners();
  }

  Future<bool> callSereno() async {
    if (_isCallingContact || !canContactSereno) return false;

    _isCallingContact = true;
    _contactErrorMessage = null;
    _notifyListeners();

    try {
      final result = await _repository.getContactPhone(_incidentId);
      final phone = result.data;
      if (!result.isSuccess || phone == null) {
        _contactErrorMessage =
            result.failure?.message ??
            'No se pudo obtener el teléfono del sereno.';
        return false;
      }

      final opened = await contactService.call(phone);
      if (!opened) {
        _contactErrorMessage = 'No se pudo abrir el marcador telefónico.';
      }
      return opened;
    } finally {
      _isCallingContact = false;
      _notifyListeners();
    }
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
