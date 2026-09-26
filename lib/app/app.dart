import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/app/app_dependencies.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

class SerenoYaApp extends StatefulWidget {
  const SerenoYaApp({
    super.key,
    required this.dependencies,
    required this.themeController,
  });
  final AppDependencies dependencies;
  final ThemeController themeController;

  @override
  State<SerenoYaApp> createState() => _SerenoYaAppState();
}

class _SerenoYaAppState extends State<SerenoYaApp> {
  late final SessionViewModel _sessionViewModel;

  @override
  void initState() {
    super.initState();
    _sessionViewModel = SessionViewModel(widget.dependencies.authRepository);
    _sessionViewModel.initialize();
  }

  @override
  void dispose() {
    _sessionViewModel.dispose();
    widget.themeController.dispose();
    widget.dependencies.routerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(
          value: widget.themeController,
        ),
        Provider<AuthRepository>.value(
          value: widget.dependencies.authRepository,
        ),
        ChangeNotifierProvider<SessionViewModel>.value(
          value: _sessionViewModel,
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, child) => MaterialApp.router(
          title: 'SerenoYa',
          debugShowCheckedModeBanner: false,
          theme: controller.light,
          darkTheme: controller.dark,
          themeMode: controller.themeMode,
          routerConfig: widget.dependencies.router,
        ),
      ),
    );
  }
}
