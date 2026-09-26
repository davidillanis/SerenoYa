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

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? imageUrl;
  final String? citizenId;
  final String? officerId;
  final List<UserRole> roles;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? email : fullName;
  }

  UserRole? get primaryRole {
    if (roles.isEmpty) return null;
    if (roles.contains(UserRole.developer)) return UserRole.developer;
    if (roles.contains(UserRole.administrator)) return UserRole.administrator;
    if (roles.contains(UserRole.officer)) return UserRole.officer;
    return UserRole.citizen;
  }
}
