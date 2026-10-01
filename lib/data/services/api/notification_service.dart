import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Mensaje recibido en background');
  print('ID: ${message.messageId}');
  print('Data: ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _configureFirebaseListeners();
    await _printToken();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print(
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
        print(
          'Notificación local presionada: '
          '${response.payload}',
        );
      },
    );

    if (Platform.isAndroid) {
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación recibida en foreground');

      print('Título: ${message.notification?.title}');

      print('Body: ${message.notification?.body}');

      print('Data: ${message.data}');

      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta desde background');

      _handleNotificationClick(message);
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      print('App abierta desde una notificación');

      _handleNotificationClick(initialMessage);
    }

    _messaging.onTokenRefresh.listen((String newToken) {
      print('Nuevo FCM token: $newToken');

      // Aquí debes enviarlo nuevamente
      // a tu backend.
    });
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
    print('Datos de la notificación: ${message.data}');

    final type = message.data['type'];

    if (type == 'order') {
      final orderId = message.data['order_id'];

      print('Abrir detalle del pedido: $orderId');
    }
  }

  Future<void> _printToken() async {
    final token = await _messaging.getToken();

    print('==============================');
    print('FCM TOKEN');
    print(token);
    print('==============================');

    // Aquí debes enviar token
    // a tu backend.
  }
}
