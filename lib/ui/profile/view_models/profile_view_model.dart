import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/profile/citizen_profile.dart';
import 'package:sereno_ya/data/models/profile/profile_update_request.dart';
import 'package:sereno_ya/data/models/profile/user_profile.dart';
import 'package:sereno_ya/data/services/api/profile/profile_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(
    this._service, {
    required String userId,
    required this.includeCitizenProfile,
  }) {
    _service.useCacheForUser(userId);
    _userProfile = _service.cachedUserProfile;
    _citizenProfile = includeCitizenProfile
        ? _service.cachedCitizenProfile
        : null;
    load();
  }

  final ProfileApiService _service;
  final bool includeCitizenProfile;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  CitizenProfile? _citizenProfile;
  CitizenProfile? get citizenProfile => _citizenProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;
  bool _disposed = false;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading || _isSaving || _disposed) return;
    final hasCompleteCache =
        _userProfile != null &&
        (!includeCitizenProfile || _citizenProfile != null);
    if (!forceRefresh && hasCompleteCache) return;

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _notifyListeners();

    try {
      final responses = await Future.wait<Object>([
        _service.getUserProfile(),
        if (includeCitizenProfile) _service.getCitizenProfile(),
      ]);
      final userResponse = responses.first as ApiResponseDto<UserProfile>;
      if (!userResponse.isSuccess || userResponse.data == null) {
        throw AuthFailure(AuthFailureCode.server, userResponse.errorMessage);
      }

      CitizenProfile? citizen;
      if (includeCitizenProfile) {
        final citizenResponse = responses[1] as ApiResponseDto<CitizenProfile>;
        if (!citizenResponse.isSuccess || citizenResponse.data == null) {
          throw AuthFailure(
            AuthFailureCode.server,
            citizenResponse.errorMessage,
          );
        }
        citizen = citizenResponse.data;
      }

      _userProfile = userResponse.data;
      _citizenProfile = citizen;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
    } on Object {
      _errorMessage = 'No se pudo cargar el perfil.';
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  void clearMessages() {
    if (_errorMessage == null && _successMessage == null) return;
    _errorMessage = null;
    _successMessage = null;
    _notifyListeners();
  }

  Future<bool> save({
    required String name,
    required String lastName,
    required String phone,
    required String address,
    String? homeLatitude,
    String? homeLongitude,
  }) async {
    final currentUser = _userProfile;
    if (currentUser == null || _isSaving || _isLoading || _disposed) {
      return false;
    }

    final normalizedName = name.trim();
    final normalizedLastName = lastName.trim();
    final normalizedPhone = phone.trim();
    final normalizedAddress = address.trim();
    final validationError = _validateUserFields(
      name: normalizedName,
      lastName: normalizedLastName,
      phone: normalizedPhone,
      address: normalizedAddress,
    );
    if (validationError != null) {
      _errorMessage = validationError;
      _successMessage = null;
      _notifyListeners();
      return false;
    }

    double? latitude;
    double? longitude;
    if (includeCitizenProfile) {
      final coordinateResult = _parseCoordinates(homeLatitude, homeLongitude);
      if (coordinateResult.error != null) {
        _errorMessage = coordinateResult.error;
        _successMessage = null;
        _notifyListeners();
        return false;
      }
      latitude = coordinateResult.latitude;
      longitude = coordinateResult.longitude;
    }

    final userChanged =
        normalizedName != currentUser.name ||
        normalizedLastName != currentUser.lastName ||
        normalizedPhone != currentUser.phone ||
        normalizedAddress != currentUser.address;
    final currentCitizen = _citizenProfile;
    final citizenChanged =
        includeCitizenProfile &&
        latitude != null &&
        longitude != null &&
        (latitude != currentCitizen?.homeLatitude ||
            longitude != currentCitizen?.homeLongitude);

    if (!userChanged && !citizenChanged) {
      _errorMessage = null;
      _successMessage = 'No hay cambios para guardar.';
      _notifyListeners();
      return true;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    _notifyListeners();

    try {
      if (userChanged) {
        await _updateUser(
          UserProfileUpdateRequest(
            name: normalizedName,
            lastName: normalizedLastName,
            phone: normalizedPhone,
            address: normalizedAddress,
            notificationsEnabled: currentUser.notificationsEnabled,
          ),
        );
        _userProfile = currentUser.copyWith(
          name: normalizedName,
          lastName: normalizedLastName,
          phone: normalizedPhone,
          address: normalizedAddress,
        );
        _service.cacheUserProfile(_userProfile!);
      }
      if (citizenChanged) {
        await _updateCitizen(
          CitizenProfileUpdateRequest(
            homeLatitude: latitude,
            homeLongitude: longitude,
          ),
        );
        _citizenProfile = currentCitizen!.copyWith(
          homeLatitude: latitude,
          homeLongitude: longitude,
        );
        _service.cacheCitizenProfile(_citizenProfile!);
      }

      _successMessage = 'Perfil actualizado correctamente.';
      _notifyListeners();
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } on Object {
      _errorMessage = 'No se pudo actualizar el perfil.';
      return false;
    } finally {
      _isSaving = false;
      _notifyListeners();
    }
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    final currentUser = _userProfile;
    if (currentUser == null || _isSaving || _isLoading || _disposed) {
      return false;
    }
    if (currentUser.notificationsEnabled == enabled) return true;
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    _notifyListeners();
    try {
      await _updateUser(
        UserProfileUpdateRequest(notificationsEnabled: enabled),
      );
      _userProfile = currentUser.copyWith(notificationsEnabled: enabled);
      if (!_disposed) _service.cacheUserProfile(_userProfile!);
      _successMessage = enabled
          ? 'Notificaciones activadas.'
          : 'Notificaciones desactivadas.';
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } on Object {
      _errorMessage = 'No se pudo guardar la preferencia de notificaciones.';
      return false;
    } finally {
      _isSaving = false;
      _notifyListeners();
    }
  }

  Future<void> _updateUser(UserProfileUpdateRequest request) async {
    final response = await _service.updateUserProfile(request);
    if (!response.isSuccess) {
      throw AuthFailure(AuthFailureCode.validation, response.errorMessage);
    }
  }

  Future<void> _updateCitizen(CitizenProfileUpdateRequest request) async {
    final response = await _service.updateCitizenProfile(request);
    if (!response.isSuccess) {
      throw AuthFailure(AuthFailureCode.validation, response.errorMessage);
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

  String? _validateUserFields({
    required String name,
    required String lastName,
    required String phone,
    required String address,
  }) {
    if (name.isEmpty || lastName.isEmpty) {
      return 'Ingresa tus nombres y apellidos.';
    }
    if (name.length > 60 || lastName.length > 60) {
      return 'Los nombres y apellidos no deben superar 60 caracteres.';
    }
    if (!RegExp(r'^(?:\+51)?9\d{8}$').hasMatch(phone)) {
      return 'Ingresa un celular peruano válido.';
    }
    if (address.isEmpty || address.length > 250) {
      return 'Ingresa una dirección de hasta 250 caracteres.';
    }
    return null;
  }

  ({double? latitude, double? longitude, String? error}) _parseCoordinates(
    String? latitudeText,
    String? longitudeText,
  ) {
    final rawLatitude = latitudeText?.trim() ?? '';
    final rawLongitude = longitudeText?.trim() ?? '';
    if (rawLatitude.isEmpty && rawLongitude.isEmpty) {
      return (latitude: null, longitude: null, error: null);
    }
    if (rawLatitude.isEmpty || rawLongitude.isEmpty) {
      return (
        latitude: null,
        longitude: null,
        error: 'La latitud y la longitud deben ingresarse juntas.',
      );
    }

    final latitude = double.tryParse(rawLatitude.replaceAll(',', '.'));
    final longitude = double.tryParse(rawLongitude.replaceAll(',', '.'));
    if (latitude == null || latitude < -90 || latitude > 90) {
      return (
        latitude: null,
        longitude: null,
        error: 'La latitud debe estar entre -90 y 90.',
      );
    }
    if (longitude == null || longitude < -180 || longitude > 180) {
      return (
        latitude: null,
        longitude: null,
        error: 'La longitud debe estar entre -180 y 180.',
      );
    }
    return (latitude: latitude, longitude: longitude, error: null);
  }
}
