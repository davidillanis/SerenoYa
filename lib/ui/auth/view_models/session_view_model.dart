import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._repository) {
    _subscription = _repository.states.listen((state) {
      _state = state;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;

  late AuthState _state = _repository.state;
  AuthState get state => _state;

  Future<void> initialize() => _repository.initialize();
  Future<void> logout() => _repository.logout();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
