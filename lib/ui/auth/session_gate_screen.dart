import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:flutter/material.dart';

class SessionGateScreen extends StatelessWidget {
  const SessionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ResponsiveBody(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  child: Image(
                    key: Key('sereno-ya-loading-icon'),
                    image: AssetImage('assets/icon/app_icon.png'),
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                    semanticLabel: 'SerenoYa',
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Verificando sesión...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
