import 'package:sereno_ya/models/auth/user_role.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.phone,
    this.imageUrl,
    this.citizenId,
    this.officerId,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? imageUrl;
  final int? citizenId;
  final int? officerId;
  final List<UserRole> roles;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? email : fullName;
  }

  UserRole? get primaryRole => roles.length == 1 ? roles.single : null;
}
