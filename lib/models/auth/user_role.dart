enum UserRole {
  citizen,
  officer,
  administrator,
  developer;

  static UserRole? fromAuthority(String value) {
    final normalized = value.trim().toUpperCase().replaceFirst('ROLE_', '');
    return switch (normalized) {
      'CLIENTE' || 'CITIZEN' => UserRole.citizen,
      'REPARTIDOR' ||
      'DEALER_EDITOR' ||
      'SERENAZGO' ||
      'OFFICER' => UserRole.officer,
      'ADMINISTRADOR' || 'ADMINISTRATOR' => UserRole.administrator,
      'DEVELOPMENT' || 'DEVELOPER' => UserRole.developer,
      _ => null,
    };
  }

  static List<UserRole> parseAuthorities(Object? value) {
    final raw = switch (value) {
      String text => text.split(','),
      List<Object?> values => values.whereType<String>(),
      _ => const <String>[],
    };

    return raw
        .map(fromAuthority)
        .whereType<UserRole>()
        .toSet()
        .toList(growable: false);
  }
}
