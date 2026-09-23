import 'package:flutter/material.dart';

class SessionGateScreen extends StatelessWidget {
  const SessionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
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
    );
  }
}
