import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/profile/user_profile.dart';
import 'package:sereno_ya/data/services/api/profile/profile_api_service.dart';
import 'package:sereno_ya/ui/profile/view_models/profile_view_model.dart';

void main() {
  test(
    'omite campos vacíos y conserva los valores del perfil y caché',
    () async {
      final updates = <Map<String, dynamic>>[];
      final service = _cachedService(updates);
      final viewModel = ProfileViewModel(
        service,
        userId: 'user-1',
        includeCitizenProfile: false,
      );
      addTearDown(viewModel.dispose);

      expect(
        await viewModel.save(name: ' ', lastName: '', phone: '', imageUrl: ''),
        isTrue,
      );
      expect(updates, isEmpty);
      expect(viewModel.successMessage, 'No hay cambios para guardar.');

      expect(
        await viewModel.save(
          name: '',
          lastName: '',
          phone: ' +51987654321 ',
          imageUrl: '',
        ),
        isTrue,
      );
      expect(updates.single, {'phone': '+51987654321'});
      expect(viewModel.userProfile!.name, 'Ana');
      expect(viewModel.userProfile!.lastName, 'Quispe');
      expect(
        viewModel.userProfile!.imageUrl,
        'https://example.com/anterior.jpg',
      );
      expect(service.cachedUserProfile!.phone, '+51987654321');
      expect(service.cachedUserProfile!.enabled, isTrue);
      expect(service.cachedUserProfile!.notificationsEnabled, isFalse);

      expect(
        await viewModel.save(
          name: '',
          lastName: '',
          phone: '',
          imageUrl: ' https://example.com/nueva.jpg ',
        ),
        isTrue,
      );
      expect(updates.last, {'imageUrl': 'https://example.com/nueva.jpg'});
      expect(
        service.cachedUserProfile!.imageUrl,
        'https://example.com/nueva.jpg',
      );
      expect(service.cachedUserProfile!.phone, '+51987654321');
    },
  );

  test('valida solo los datos nuevos antes de enviarlos', () async {
    final updates = <Map<String, dynamic>>[];
    final service = _cachedService(updates);
    final viewModel = ProfileViewModel(
      service,
      userId: 'user-1',
      includeCitizenProfile: false,
    );
    addTearDown(viewModel.dispose);
    for (final values in [
      {'name': 'a' * 61},
      {'lastName': 'a' * 61},
      {'phone': '887654321'},
      {'phone': '+51 987654321'},
      {'imageUrl': 'ftp://example.com/image.jpg'},
      {'imageUrl': 'https://'},
    ]) {
      expect(
        await viewModel.save(
          name: values['name'] ?? '',
          lastName: values['lastName'] ?? '',
          phone: values['phone'] ?? '',
          imageUrl: values['imageUrl'],
        ),
        isFalse,
      );
      expect(viewModel.errorMessage, isNotEmpty);
      expect(updates, isEmpty);
      expect(service.cachedUserProfile!.name, 'Ana');
    }
    expect(
      await viewModel.save(name: 'a' * 60, lastName: 'b' * 60, phone: ''),
      isTrue,
    );
    expect(updates.single, {'name': 'a' * 60, 'lastName': 'b' * 60});
  });

  test(
    'exige solo celular y confirma el dato guardado antes del reporte',
    () async {
      var persistUpdate = true;
      var phone = '';
      var rejectUpdate = false;
      final updates = <Map<String, dynamic>>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/user-role/update-me') {
              final data = Map<String, dynamic>.from(options.data as Map);
              updates.add(data);
              if (!rejectUpdate && persistUpdate) {
                phone = data['phone'] as String? ?? phone;
              }
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'isSuccess': !rejectUpdate,
                  'data': options.path == '/user-role/me'
                      ? {
                          'id': 'user-1',
                          'name': 'Ana',
                          'lastName': 'Quispe',
                          'email': 'ana@example.com',
                          'phone': phone,
                          'address': '',
                          'enabled': true,
                          'emailVerified': true,
                        }
                      : 'Actualizado',
                },
              ),
            );
          },
        ),
      );
      final viewModel = ProfileViewModel(
        ProfileApiService(dio),
        userId: 'user-1',
        includeCitizenProfile: false,
      );
      addTearDown(viewModel.dispose);
      await _waitUntil(() => !viewModel.isLoading);
      expect(viewModel.hasReportContact, isFalse);
      expect(await viewModel.completeReportContact(phone: '123'), isFalse);
      expect(updates, isEmpty);
      rejectUpdate = true;
      expect(
        await viewModel.completeReportContact(phone: '987654321'),
        isFalse,
      );
      expect(viewModel.hasReportContact, isFalse);
      rejectUpdate = false;
      persistUpdate = false;
      expect(
        await viewModel.completeReportContact(phone: '987654321'),
        isFalse,
      );
      expect(viewModel.hasReportContact, isFalse);
      expect(
        viewModel.errorMessage,
        'No se pudo confirmar el celular guardado.',
      );
      persistUpdate = true;
      expect(await viewModel.completeReportContact(phone: '987654321'), isTrue);
      expect(updates.last, {'phone': '987654321'});
      expect(viewModel.hasReportContact, isTrue);
      final updateCount = updates.length;
      expect(await viewModel.completeReportContact(phone: '987654321'), isTrue);
      expect(updates, hasLength(updateCount));
    },
  );

  test('carga y actualiza el perfil sin una capa de repositorio', () async {
    final requestedPaths = <String>[];
    var name = 'Ana';
    var notificationsEnabled = true;
    var rejectUpdate = false;
    final updates = <Map<String, dynamic>>[];
    const address = 'San Jerónimo';
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
      homeLatitude: '-13.652',
      homeLongitude: '-73.366',
    );

    expect(updated, isTrue);
    expect(updates.last.containsKey('notificationsEnabled'), isFalse);
    expect(viewModel.userProfile!.notificationsEnabled, isFalse);
    expect(requestedPaths, contains('/user-role/update-me'));
    expect(requestedPaths, contains('/citizens/update'));
    expect(viewModel.userProfile?.name, 'Ana María');
    expect(updates.last, {'name': 'Ana María'});
    expect(viewModel.userProfile?.address, 'San Jerónimo');
    expect(viewModel.citizenProfile?.homeLatitude, -13.652);
    expect(viewModel.successMessage, 'Perfil actualizado correctamente.');

    final requestCount = requestedPaths.length;
    final invalid = await viewModel.save(
      name: 'Ana María',
      lastName: 'Quispe',
      phone: '123',
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

ProfileApiService _cachedService(List<Map<String, dynamic>> updates) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        updates.add(Map<String, dynamic>.from(options.data as Map));
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {'isSuccess': true, 'data': 'Actualizado'},
          ),
        );
      },
    ),
  );
  final service = ProfileApiService(dio);
  service.useCacheForUser('user-1');
  service.cacheUserProfile(
    UserProfile.fromJson({
      'id': 'user-1',
      'name': 'Ana',
      'lastName': 'Quispe',
      'email': 'ana@example.com',
      'phone': '987654321',
      'enabled': true,
      'notificationsEnabled': false,
      'imageUrl': 'https://example.com/anterior.jpg',
    }),
  );
  return service;
}
