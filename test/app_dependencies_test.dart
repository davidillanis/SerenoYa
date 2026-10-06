import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/app/app_dependencies.dart';
import 'package:sereno_ya/data/services/api/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Crea las dependencias sin consultar APIs nativas', () {
    final dependencies = AppDependencies.create();
    addTearDown(dependencies.deviceTokenService.dispose);
    addTearDown(dependencies.routerNotifier.dispose);
    addTearDown(dependencies.router.dispose);

    expect(dependencies.router, isNotNull);
  });

  test(
    'Omite las notificaciones móviles en plataformas no compatibles',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final dependencies = AppDependencies.create();
      addTearDown(dependencies.deviceTokenService.dispose);
      addTearDown(dependencies.routerNotifier.dispose);
      addTearDown(dependencies.router.dispose);
      addTearDown(NotificationService.instance.dispose);

      // Debe completar sin Firebase ni plugins nativos inicializados.
      await NotificationService.instance.initialize(
        dependencies.deviceTokenService,
      );
    },
  );
}
