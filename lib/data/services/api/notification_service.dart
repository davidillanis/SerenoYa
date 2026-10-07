import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';
import 'device_token_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Mensaje recibido en background');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  DeviceTokenService? _deviceTokens;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> initialize(DeviceTokenService deviceTokens) async {
    // Las notificaciones actuales usan plugins y configuración de Android/iOS.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    _deviceTokens = deviceTokens;
    await _requestPermission();
    await _initializeLocalNotifications();
    await _configureFirebaseListeners();
    await synchronizeToken();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'Permiso notificaciones: '
      '${settings.authorizationStatus}',
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'Notificación local presionada: '
          'por el usuario.',
        );
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificaciones importantes',
        description: 'Canal utilizado para notificaciones importantes.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _configureFirebaseListeners() async {
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Notificación recibida en foreground');

        _showForegroundNotification(message);
      }),
    );

    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notificación abierta desde background');

        _handleNotificationClick(message);
      }),
    );

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App abierta desde una notificación');

      _handleNotificationClick(initialMessage);
    }

    _subscriptions.add(
      _messaging.onTokenRefresh.listen((String newToken) {
        unawaited(_deviceTokens?.synchronizeToken(newToken));
      }),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones importantes',
      channelDescription: 'Canal utilizado para notificaciones importantes.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notificación seleccionada.');

    final type = message.data['type'];

    if (type == 'order') {
      debugPrint('Abrir detalle del pedido.');
    }
  }

  Future<void> synchronizeToken() async {
    if (_deviceTokens == null) return;
    try {
      final token = await _messaging.getToken();
      await _deviceTokens?.synchronizeToken(token);
    } on Object {
      debugPrint('No se pudo obtener el token de notificaciones.');
    }
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _deviceTokens = null;
  }
}
