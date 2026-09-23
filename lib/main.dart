import 'package:flutter/material.dart';
import 'package:sereno_ya/app/app.dart';
import 'package:sereno_ya/app/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  runApp(SerenoYaApp(dependencies: dependencies));
}
