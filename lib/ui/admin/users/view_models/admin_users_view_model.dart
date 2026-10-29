import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/admin/admin_user_summary.dart';
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
  AdminUserRoleFilter? roleFilter;
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int totalElements = 0;
  String? errorMessage;
  String? loadMoreError;
  String? updatingUserId;
  String? updateRolesError;
  String? updateSerenoError;

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
        role: roleFilter?.apiValue,
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
        role: roleFilter?.apiValue,
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

  Future<void> selectRole(AdminUserRoleFilter? role) async {
    if (_disposed || role == roleFilter) return;
    _generation++;
    roleFilter = role;
    isLoadingMore = false;
    _users.clear();
    _nextPage = 0;
    totalElements = 0;
    hasMore = true;
    await loadInitial(forceRefresh: true);
  }

  Future<void> retryLoadMore() async {
    loadMoreError = null;
    await loadMore();
  }

  Future<bool> updateRoles(AdminUserRolesUpdateRequest request) async {
    if (_disposed || updatingUserId != null) return false;
    updatingUserId = request.userId;
    updateRolesError = null;
    _notify();

    try {
      final response = await _apiService.updateRoles(request);
      if (_disposed) return false;
      if (!response.isSuccess) {
        updateRolesError = response.errorMessage;
        return false;
      }

      final index = _users.indexWhere((user) => user.id == request.userId);
      if (index >= 0) {
        if (roleFilter != null &&
            !request.roles.contains(roleFilter!.apiValue)) {
          _users.removeAt(index);
          if (totalElements > 0) totalElements--;
        } else {
          _users[index] = _users[index].copyWith(
            roles: request.roles.toList(growable: false),
          );
        }
      }
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) updateRolesError = failure.message;
      return false;
    } catch (_) {
      if (!_disposed) {
        updateRolesError = 'No se pudieron actualizar los roles del usuario.';
      }
      return false;
    } finally {
      if (!_disposed) {
        updatingUserId = null;
        _notify();
      }
    }
  }

  Future<bool> updateSereno(
    String userId,
    AdminSerenoUpdateRequest request,
  ) async {
    if (_disposed || updatingUserId != null) return false;
    updatingUserId = userId;
    updateSerenoError = null;
    _notify();

    try {
      final response = await _apiService.updateSereno(userId, request);
      if (_disposed) return false;
      if (!response.isSuccess) {
        updateSerenoError = response.errorMessage;
        return false;
      }
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) updateSerenoError = failure.message;
      return false;
    } catch (_) {
      if (!_disposed) {
        updateSerenoError = 'No se pudo actualizar el perfil del sereno.';
      }
      return false;
    } finally {
      if (!_disposed) {
        updatingUserId = null;
        _notify();
      }
    }
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

enum AdminUserRoleFilter {
  citizen('CITIZEN', 'Ciudadano'),
  officer('OFFICER_SERENO', 'Serenazgo'),
  administrator('OFFICER_ADMINISTRADOR', 'Administrador'),
  developer('DEVELOPMENT', 'Desarrollo');

  const AdminUserRoleFilter(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
