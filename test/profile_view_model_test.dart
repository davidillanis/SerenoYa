import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/services/api/profile/profile_api_service.dart';
import 'package:sereno_ya/ui/profile/view_models/profile_view_model.dart';

void main() {
  test('carga y actualiza el perfil sin una capa de repositorio', () async {
    final requestedPaths = <String>[];
    var name = 'Ana';
    var notificationsEnabled = true;
    var rejectUpdate = false;
    final updates = <Map<String, dynamic>>[];
    var address = 'San Jerónimo';
    var latitude = -13.6519;
    var longitude = -73.365;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          if (options.path == '/user-role/update-me') {
            final data = Map<String, dynamic>.from(options.data as Map);
            updates.add(data);
            if (!rejectUpdate) {
              name = data['name'] as String? ?? name;
              address = data['address'] as String? ?? address;
              notificationsEnabled =
                  data['notificationsEnabled'] as bool? ?? notificationsEnabled;
            }
          }
          if (options.path == '/citizens/update') {
            final data = Map<String, dynamic>.from(options.data as Map);
            latitude = (data['homeLatitude'] as num).toDouble();
            longitude = (data['homeLongitude'] as num).toDouble();
          }

          final responseData = switch (options.path) {
            '/user-role/me' => {
              'id': 'user-1',
              'name': name,
              'lastName': 'Quispe',
              'email': 'ana@example.com',
              'dni': '12345678',
              'phone': '987654321',
              'address': address,
              'enabled': true,
              'notificationsEnabled': notificationsEnabled,
              'emailVerified': true,
            },
            '/citizens/me' => {
              'id': 'citizen-1',
              'homeLatitude': latitude,
              'homeLongitude': longitude,
            },
            _ => 'Perfil actualizado',
          };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'isSuccess': !rejectUpdate,
                'message': 'Successful operation',
                'errors': null,
                'data': responseData,
              },
            ),
          );
        },
      ),
    );

    final service = ProfileApiService(dio);
    final viewModel = ProfileViewModel(
      service,
      userId: 'user-1',
      includeCitizenProfile: true,
    );
    addTearDown(viewModel.dispose);
    await _waitUntil(() => !viewModel.isLoading);

    expect(viewModel.userProfile?.displayName, 'Ana Quispe');
    expect(viewModel.citizenProfile?.homeLatitude, -13.6519);

    final requestCountAfterFirstLoad = requestedPaths.length;
    final cachedViewModel = ProfileViewModel(
      service,
      userId: 'user-1',
      includeCitizenProfile: true,
    );
    addTearDown(cachedViewModel.dispose);
    expect(cachedViewModel.isLoading, isFalse);
    expect(cachedViewModel.userProfile?.displayName, 'Ana Quispe');
    expect(requestedPaths.length, requestCountAfterFirstLoad);

    expect(await viewModel.setNotificationsEnabled(false), isTrue);
    expect(updates.last, {'notificationsEnabled': false});
    expect(viewModel.userProfile!.notificationsEnabled, isFalse);
    expect(service.cachedUserProfile!.notificationsEnabled, isFalse);
    await viewModel.load(forceRefresh: true);
    expect(viewModel.userProfile!.notificationsEnabled, isFalse);

    rejectUpdate = true;
    expect(await viewModel.setNotificationsEnabled(true), isFalse);
    expect(viewModel.userProfile!.notificationsEnabled, isFalse);
    expect(viewModel.isSaving, isFalse);
    rejectUpdate = false;

    final updated = await viewModel.save(
      name: 'Ana María',
      lastName: 'Quispe',
      phone: '987654321',
      address: 'Av. Principal',
      homeLatitude: '-13.652',
      homeLongitude: '-73.366',
    );

    expect(updated, isTrue);
    expect(updates.last['notificationsEnabled'], isFalse);
    expect(viewModel.userProfile!.notificationsEnabled, isFalse);
    expect(requestedPaths, contains('/user-role/update-me'));
    expect(requestedPaths, contains('/citizens/update'));
    expect(viewModel.userProfile?.name, 'Ana María');
    expect(viewModel.citizenProfile?.homeLatitude, -13.652);
    expect(viewModel.successMessage, 'Perfil actualizado correctamente.');

    final requestCount = requestedPaths.length;
    final invalid = await viewModel.save(
      name: 'Ana María',
      lastName: 'Quispe',
      phone: '123',
      address: 'Av. Principal',
      homeLatitude: '-13.652',
      homeLongitude: '-73.366',
    );
    expect(invalid, isFalse);
    expect(viewModel.errorMessage, 'Ingresa un celular peruano válido.');
    expect(requestedPaths.length, requestCount);
    expect(await viewModel.setNotificationsEnabled(true), isTrue);
    expect(updates.last, {'notificationsEnabled': true});
    expect(service.cachedUserProfile!.notificationsEnabled, isTrue);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('La operación asíncrona no terminó a tiempo.');
}
