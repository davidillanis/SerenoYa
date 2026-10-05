# Push Notifications en Flutter con Firebase

## 1. Instalar paquetes

Ejecuta en la raíz del proyecto:

```bash
flutter pub add firebase_core
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications
```

---

## 2. Configurar Firebase

Ejecuta:

```bash
flutterfire configure
```

Si aparece:

```text
firebase_options.dart already exists, do you want to override it?
```

Responde:

```text
y
```

Debe existir:

```text
lib/firebase_options.dart
```

---

## 3. AndroidManifest.xml

Abre:

```text
android/app/src/main/AndroidManifest.xml
```

Agrega antes de `<application>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Ejemplo:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="sereno_ya"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- configuración actual -->

    </application>

</manifest>
```

---

## 4. Crear NotificationService

Crea:

```text
lib/services/notification_service.dart
```

Pega:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Notificación background: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _configureListeners();
    await _getToken();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Permiso: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
    );

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones importantes',
      description: 'Canal principal de notificaciones',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _configureListeners() async {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        final notification = message.notification;

        if (notification == null) return;

        const androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones importantes',
          channelDescription: 'Canal principal de notificaciones',
          importance: Importance.high,
          priority: Priority.high,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        );

        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          details,
        );
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        print('Notificación presionada');
        print(message.data);
      },
    );

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      print('App abierta desde notificación');
      print(initialMessage.data);
    }

    _messaging.onTokenRefresh.listen(
      (token) {
        print('Nuevo FCM TOKEN: $token');
      },
    );
  }

  Future<void> _getToken() async {
    final token = await _messaging.getToken();

    print('==============================');
    print('FCM TOKEN');
    print(token);
    print('==============================');
  }
}
```

---

## 5. Configurar main.dart

En:

```text
lib/main.dart
```

Usa:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Push Notifications'),
        ),
        body: const Center(
          child: Text('Firebase listo'),
        ),
      ),
    );
  }
}
```

---

## 6. Ejecutar

```bash
flutter clean
flutter pub get
flutter run
```

Acepta el permiso de notificaciones.

En consola debes ver:

```text
FCM TOKEN
xxxxxxxxxxxxxxxxxxxxxxxx
```

Copia ese token.

---

## 7. Probar desde Firebase

En Firebase Console:

```text
Firebase Console
→ Messaging
→ Create campaign
→ Notifications
→ Send test message
```

Usa:

```text
Título:
Prueba

Mensaje:
Mi primera push notification
```

Pega el `FCM TOKEN`.

Minimiza la app y envía la prueba.

---

## Resultado esperado

Debe funcionar en:

```text
App abierta
→ flutter_local_notifications muestra la notificación

App en background
→ Android/iOS muestra la notificación

App cerrada
→ la notificación puede abrir la aplicación
```

## Checklist

```text
[ ] firebase_core
[ ] firebase_messaging
[ ] flutter_local_notifications
[ ] flutterfire configure
[ ] firebase_options.dart
[ ] POST_NOTIFICATIONS
[ ] Firebase.initializeApp()
[ ] NotificationService
[ ] obtener FCM TOKEN
[ ] enviar prueba desde Firebase
```