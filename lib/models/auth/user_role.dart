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
      'OFFICER_SERENO' ||
      'OFFICER' => UserRole.officer,
      'ADMINISTRADOR' || 'ADMINISTRATOR' || 'ADMIN' || 'OFFICER_ADMINISTRADOR' => UserRole.administrator,
      'DEVELOPMENT' || 'DEVELOPER' => UserRole.developer,
      _ => () {
          if (normalized.contains('ADMIN')) return UserRole.administrator;
          if (normalized.contains('SERENO')) return UserRole.officer;
          if (normalized.contains('OFICIAL')) return UserRole.officer;
          if (normalized.contains('OFFICER')) return UserRole.officer;
          return null;
        }(),
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
