import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/admin/admin_user_summary.dart';
import 'package:sereno_ya/data/models/admin/admin_user_detail.dart';
import 'package:sereno_ya/data/models/admin/admin_sereno_update_request.dart';
import 'package:sereno_ya/data/models/admin/admin_user_roles_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AdminUsersViewModel extends ChangeNotifier {
  AdminUsersViewModel(this._apiService) {
    loadInitial();
  }

  static const pageSize = 15;

  final AdminUserApiService _apiService;
  final List<AdminUserSummary> _users = [];

  List<AdminUserSummary> get users => List.unmodifiable(_users);
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int totalElements = 0;
  String? errorMessage;
  String? loadMoreError;
  String search = '';
  String? updatingUserId;
  String? actionError;

  int _nextPage = 0;
  int _generation = 0;
  bool _disposed = false;

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (_disposed || isLoadingInitial || isLoadingMore) return;
    if (_users.isNotEmpty && !forceRefresh) return;

    final generation = ++_generation;
    isLoadingInitial = true;
    errorMessage = null;
    loadMoreError = null;
    _notify();

    try {
      final response = await _apiService.listUsers(
        size: pageSize,
        search: search,
      );
      if (_disposed || generation != _generation) return;

      if (response.isSuccess && response.data != null) {
        final page = response.data!;
        _users
          ..clear()
          ..addAll(page.content);
        _nextPage = page.page + 1;
        totalElements = page.totalElements;
        hasMore = _nextPage < page.totalPages;
      } else {
        errorMessage = response.errorMessage;
      }
    } on AuthFailure catch (failure) {
      if (!_disposed && generation == _generation) {
        errorMessage = failure.message;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        errorMessage = 'No se pudieron cargar los usuarios.';
      }
    }

    if (_disposed || generation != _generation) return;
    isLoadingInitial = false;
    _notify();
  }

  Future<void> loadMore() async {
    if (_disposed ||
        isLoadingInitial ||
        isLoadingMore ||
        !hasMore ||
        loadMoreError != null) {
      return;
    }

    final generation = _generation;
    isLoadingMore = true;
    _notify();

    try {
      final response = await _apiService.listUsers(
        page: _nextPage,
        size: pageSize,
        search: search,
      );
      if (_disposed || generation != _generation) return;

      if (response.isSuccess && response.data != null) {
        final page = response.data!;
        final knownIds = _users.map((user) => user.id).toSet();
        _users.addAll(page.content.where((user) => knownIds.add(user.id)));
        _nextPage = page.page + 1;
        totalElements = page.totalElements;
        hasMore = _nextPage < page.totalPages;
        loadMoreError = null;
      } else {
        loadMoreError = response.errorMessage;
      }
    } on AuthFailure catch (failure) {
      if (!_disposed && generation == _generation) {
        loadMoreError = failure.message;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        loadMoreError = 'No se pudieron cargar más usuarios.';
      }
    }

    if (_disposed || generation != _generation) return;
    isLoadingMore = false;
    _notify();
  }

  Future<void> retryLoadMore() async {
    loadMoreError = null;
    await loadMore();
  }

  Future<void> setSearch(String value) async {
    final nextSearch = value.trim();
    if (_disposed || nextSearch == search) return;
    _generation++;
    search = nextSearch;
    isLoadingInitial = false;
    isLoadingMore = false;
    _users.clear();
    _nextPage = 0;
    totalElements = 0;
    hasMore = true;
    await loadInitial(forceRefresh: true);
  }

  Future<AdminUserDetail?> loadUserDetail(String issoraId) async {
    if (_disposed || updatingUserId != null) return null;
    updatingUserId = issoraId;
    actionError = null;
    _notify();
    try {
      final response = await _apiService.getUser(issoraId);
      if (_disposed) return null;
      if (response.isSuccess && response.data != null) {
        final detail = response.data!;
        if (detail.issoraId == issoraId && detail.id.isNotEmpty) {
          return detail;
        }
        actionError = 'La API devolvió identificadores de usuario inválidos.';
      } else {
        actionError = response.errorMessage;
      }
    } on AuthFailure catch (failure) {
      if (!_disposed) actionError = failure.message;
    } catch (_) {
      if (!_disposed) actionError = 'No se pudo cargar el usuario.';
    } finally {
      if (!_disposed) {
        updatingUserId = null;
        _notify();
      }
    }
    return null;
  }

  Future<bool> updateRoles(AdminUserRolesUpdateRequest request) async {
    if (_disposed || updatingUserId != null) return false;
    updatingUserId = request.userId;
    actionError = null;
    _notify();
    try {
      final response = await _apiService.updateRoles(request);
      if (_disposed) return false;
      if (response.isSuccess) return true;
      actionError = response.errorMessage;
    } on AuthFailure catch (failure) {
      if (!_disposed) actionError = failure.message;
    } catch (_) {
      if (!_disposed) actionError = 'No se pudieron actualizar los roles.';
    } finally {
      if (!_disposed) {
        updatingUserId = null;
        _notify();
      }
    }
    return false;
  }

  Future<bool> updateSereno(
    String userId,
    AdminSerenoUpdateRequest request,
  ) async {
    if (_disposed || updatingUserId != null) return false;
    updatingUserId = userId;
    actionError = null;
    _notify();
    try {
      final response = await _apiService.updateSereno(userId, request);
      if (_disposed) return false;
      if (response.isSuccess) return true;
      actionError = response.errorMessage;
    } on AuthFailure catch (failure) {
      if (!_disposed) actionError = failure.message;
    } catch (_) {
      if (!_disposed) actionError = 'No se pudo actualizar el sereno.';
    } finally {
      if (!_disposed) {
        updatingUserId = null;
        _notify();
      }
    }
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
