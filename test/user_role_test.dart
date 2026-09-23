import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/models/auth/user_role.dart';

void main() {
  group('UserRole.parseAuthorities', () {
    test('maps RappiGo authorities to SerenoYa roles', () {
      expect(UserRole.parseAuthorities('ROLE_CLIENTE'), [UserRole.citizen]);
      expect(UserRole.parseAuthorities('ROLE_REPARTIDOR'), [UserRole.officer]);
      expect(UserRole.parseAuthorities('ROLE_ADMINISTRADOR'), [
        UserRole.administrator,
      ]);
      expect(UserRole.parseAuthorities('ROLE_DEVELOPMENT'), [
        UserRole.developer,
      ]);
    });

    test('deduplicates equivalent officer authorities', () {
      expect(UserRole.parseAuthorities('ROLE_REPARTIDOR,ROLE_DEALER_EDITOR'), [
        UserRole.officer,
      ]);
    });

    test('ignores unknown roles', () {
      expect(UserRole.parseAuthorities('ROLE_RESTAURANTE'), isEmpty);
    });
  });
}
