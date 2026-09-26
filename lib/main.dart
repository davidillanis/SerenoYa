import 'package:shared_preferences/shared_preferences.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:sereno_ya/app/app.dart';
import 'package:sereno_ya/app/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController(
    preferences: await SharedPreferences.getInstance(),
  );
  final dependencies = AppDependencies.create();
  runApp(
    SerenoYaApp(dependencies: dependencies, themeController: themeController),
  );
}
