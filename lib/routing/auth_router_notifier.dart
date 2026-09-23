import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';

class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(AuthRepository repository) {
    _subscription = repository.states.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
