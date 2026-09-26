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
                Icon(Icons.shield_outlined, size: 64),
                SizedBox(height: 20),
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
