import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/data/services/api/notification_service.dart';

import 'package:flutter/foundation.dart';

import 'package:sereno_ya/data/services/auth/google_identity_service.dart';

import 'package:android_id/android_id.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/api/device_token_service.dart';
import 'package:sereno_ya/data/services/local/device_sync_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository_impl.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/api_client.dart';
import 'package:sereno_ya/data/services/api/auth/auth_api_service.dart';
import 'package:sereno_ya/data/services/api/auth/auth_interceptor.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/data/services/api/file/image_api_service.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/data/services/api/profile/profile_api_service.dart';
import 'package:sereno_ya/data/services/api/route_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/data/services/storage/session_storage_service.dart';
import 'package:sereno_ya/routing/app_router.dart';
import 'package:sereno_ya/routing/auth_router_notifier.dart';

class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.incidentRepository,
    required this.routeCompareRepository,
    required this.storageService,
    required this.deviceTokenService,
  });

  factory AppDependencies.create() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final storageService = SessionStorageService();
    final apiClient = ApiClient();
    final authApiService = AuthApiService(apiClient.dio);
    final googleIdentityService = GoogleIdentityServiceImpl();
    final authRepository = AuthRepositoryImpl(
      authApiService,
      storageService,
      googleIdentityService: googleIdentityService,
    );

    final incidentApiService = IncidentsApiService(apiClient.dio);
    final officerApiService = IncidentApiService(apiClient.dio);
    final routeCompareRepository = RouteCompareRepository(
      RouteApiService(apiClient.dio),
    );
    final profileApiService = ProfileApiService(apiClient.dio);
    final localDataSource = IncidentLocalDataSourceImpl();
    final incidentRepository = IncidentRepository(
      apiService: incidentApiService,
      localDataSource: localDataSource,
    );

    final imageApiService = StorageService();

    apiClient.dio.interceptors.add(
      AuthInterceptor(apiClient.dio, storageService.readAccessToken, () async {
        final result = await authRepository.refreshSession();
        return result.data?.accessToken;
      }, authRepository.logout),
    );

    final dependencies = AppDependencies._(
      authRepository: authRepository,
      incidentRepository: incidentRepository,
      routeCompareRepository: routeCompareRepository,
      storageService: imageApiService,
      deviceTokenService: DeviceTokenService(
        authRepository: authRepository,
        apiService: DeviceApiService(apiClient.dio),
        readDeviceId: () async =>
            isAndroid ? await const AndroidId().getId() : null,
        osType: kIsWeb ? 'WEB' : (isAndroid ? 'ANDROID' : 'IOS'),
        syncStorage: SharedPreferencesDeviceSyncStorage(),
      ),
    );
    dependencies.routerNotifier = AuthRouterNotifier(authRepository);
    dependencies.router = createAppRouter(
      onLoginSuccess: NotificationService.instance.synchronizeToken,
      officerRepository: OfficerRepository(officerApiService),
      googleIdentityService: googleIdentityService,
      authRepository: authRepository,
      incidentRepository: incidentRepository,
      storageService: imageApiService,
      profileApiService: profileApiService,
      routerNotifier: dependencies.routerNotifier,
    );
    return dependencies;
  }

  final DeviceTokenService deviceTokenService;
  final AuthRepository authRepository;
  final IncidentRepository incidentRepository;
  final RouteCompareRepository routeCompareRepository;
  final StorageService storageService;

  late final AuthRouterNotifier routerNotifier;
  late final GoRouter router;
}
