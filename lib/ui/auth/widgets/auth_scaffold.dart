import 'package:flutter/material.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBrandHeader = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBrandHeader;

  @override
  Widget build(BuildContext context) {
    if (showBrandHeader) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .42, .8],
              colors: [
                colors.primaryContainer,
                colors.surfaceContainerLow,
                colors.surface,
              ],
            ),
          ),
          child: ResponsiveBody(
            maxWidth: 560,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_police_outlined,
                          size: 72,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SerenoYa',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onPrimaryContainer,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TU SEGURIDAD, NUESTRA PRIORIDAD',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onPrimaryContainer,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.sizeOf(context).width < 400 ? 20 : 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Theme(
                            data: theme.copyWith(
                              inputDecorationTheme: theme.inputDecorationTheme
                                  .copyWith(
                                    fillColor: colors.surfaceContainerLow,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                            ),
                            child: child,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Serenazgo de San Jerónimo',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 400 ? 12 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 400 ? 16 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 52,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
