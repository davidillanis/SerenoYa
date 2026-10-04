import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:sereno_ya/app/app.dart';
import 'package:sereno_ya/app/app_dependencies.dart';
import 'package:sereno_ya/data/services/api/notification_service.dart';
import 'package:sereno_ya/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final themeController = ThemeController(
    preferences: await SharedPreferences.getInstance(),
  );
  final dependencies = AppDependencies.create();
  await NotificationService.instance.initialize(
    dependencies.deviceTokenService,
  );
  runApp(
    SerenoYaApp(dependencies: dependencies, themeController: themeController),
  );
}
