import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/routing/route_names.dart';

abstract final class RoleRouteResolver {
  static String routeFor(UserRole? role) => switch (role) {
    UserRole.citizen => RouteNames.citizen,
    UserRole.officer => RouteNames.officer,
    UserRole.administrator => RouteNames.admin,
    UserRole.developer => RouteNames.dev,
    null => RouteNames.unauthorized,
  };

  static bool canAccess(String location, UserRole role) {
    final allowedPrefix = routeFor(role);
    return location == allowedPrefix || location.startsWith('$allowedPrefix/');
  }
}
