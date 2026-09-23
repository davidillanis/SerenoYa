import 'package:go_router/go_router.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository_impl.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/api_client.dart';
import 'package:sereno_ya/data/services/api/auth/auth_api_service.dart';
import 'package:sereno_ya/data/services/api/auth/auth_interceptor.dart';
import 'package:sereno_ya/data/services/api/citizen/incident_api_service.dart';
import 'package:sereno_ya/data/services/storage/session_storage_service.dart';
import 'package:sereno_ya/routing/app_router.dart';
import 'package:sereno_ya/routing/auth_router_notifier.dart';

class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.incidentRepository,
  });

  factory AppDependencies.create() {
    final storageService = SessionStorageService();
    final apiClient = ApiClient();
    final authApiService = AuthApiService(apiClient.dio);
    final authRepository = AuthRepositoryImpl(authApiService, storageService);
    
    final incidentApiService = IncidentApiService(apiClient.dio);
    final incidentRepository = IncidentRepository(incidentApiService);

    apiClient.dio.interceptors.add(
      AuthInterceptor(apiClient.dio, storageService.readAccessToken, () async {
        final result = await authRepository.refreshSession();
        return result.data?.accessToken;
      }, authRepository.logout),
    );

    final dependencies = AppDependencies._(
      authRepository: authRepository,
      incidentRepository: incidentRepository,
    );
    dependencies.routerNotifier = AuthRouterNotifier(authRepository);
    dependencies.router = createAppRouter(
      authRepository: authRepository,
      incidentRepository: incidentRepository,
      routerNotifier: dependencies.routerNotifier,
    );
    return dependencies;
  }

  final AuthRepository authRepository;
  final IncidentRepository incidentRepository;

  late final AuthRouterNotifier routerNotifier;
  late final GoRouter router;
}
