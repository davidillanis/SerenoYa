import 'package:go_router/go_router.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository_impl.dart';
import 'package:sereno_ya/data/services/api/api_client.dart';
import 'package:sereno_ya/data/services/api/auth/auth_api_service.dart';
import 'package:sereno_ya/data/services/api/auth/auth_interceptor.dart';
import 'package:sereno_ya/data/services/storage/session_storage_service.dart';
import 'package:sereno_ya/routing/app_router.dart';
import 'package:sereno_ya/routing/auth_router_notifier.dart';

class AppDependencies {
  AppDependencies._({required this.authRepository});

  factory AppDependencies.create() {
    final storageService = SessionStorageService();
    final apiClient = ApiClient();
    final apiService = AuthApiService(apiClient.dio);
    final repository = AuthRepositoryImpl(apiService, storageService);

    apiClient.dio.interceptors.add(
      AuthInterceptor(apiClient.dio, storageService.readAccessToken, () async {
        final result = await repository.refreshSession();
        return result.data?.accessToken;
      }, repository.logout),
    );

    final dependencies = AppDependencies._(authRepository: repository);
    dependencies.routerNotifier = AuthRouterNotifier(repository);
    dependencies.router = createAppRouter(
      authRepository: repository,
      routerNotifier: dependencies.routerNotifier,
    );
    return dependencies;
  }

  final AuthRepository authRepository;

  late final AuthRouterNotifier routerNotifier;
  late final GoRouter router;
}
