# Instrucciones para agentes

## Alcance y contexto

Estas instrucciones se aplican a todo el repositorio. Las instrucciones explícitas
del usuario tienen prioridad. Revisa instrucciones adicionales en el directorio
que vayas a modificar.

SerenoYa es una aplicación Flutter para reportar incidentes ciudadanos y coordinar
su atención por el Serenazgo de San Jerónimo. Mantén los textos de la interfaz y
las explicaciones al usuario en español, y los identificadores de código en inglés.

## Forma de trabajar

- Inspecciona el código y `git status` antes de editar. Conserva los cambios del
  usuario y evita modificaciones ajenas a la tarea.
- Adapta los archivos y componentes existentes; evita implementaciones duplicadas.
- Sigue las convenciones del módulo. No agregues dependencias si las existentes
  resuelven la necesidad.
- Mantén los cambios acotados y no reformatees archivos ajenos a la tarea.
- No incluyas credenciales, tokens, datos personales ni secretos en código o logs.

## Arquitectura

- `lib/main.dart`: inicialización de Flutter, preferencias y arranque.
- `lib/app/`: composición de dependencias, proveedores y `MaterialApp.router`.
- `lib/routing/`: rutas con GoRouter, redirecciones y acceso según sesión y rol.
- `lib/ui/`: pantallas, widgets y view models organizados por funcionalidad.
- `lib/ui/core/`: componentes reutilizables y sistema de temas.
- `lib/data/repositories/`: acceso a datos y coordinación de servicios.
- `lib/data/services/`: API con Dio, almacenamiento y fuentes locales.
- `lib/data/models/` y `lib/models/`: DTO y modelos existentes; respeta la
  separación del módulo antes de introducir nuevos tipos.

Usa Provider y ChangeNotifier siguiendo los patrones actuales. Mantén las llamadas
de red y el almacenamiento fuera de los widgets. Respeta el ciclo de vida de
controladores y listeners; comprueba `context.mounted` cuando uses un contexto
después de una operación asíncrona.

La URL de la API se configura con `API_BASE_URL` mediante `--dart-define`.
No cambies endpoints de producción para realizar pruebas.

## Sistema de temas

Usa los cuatro archivos existentes en `lib/ui/core/theme/`:

- `theme.dart`: paletas de referencia, registro `themeVariants`, selección con
  `getTheme` y construcción de `ThemeData` mediante `buildAppTheme`.
- `mapped_palette.dart`: `ThemeVariant` y `MappedPalette`, implementada como
  `ThemeExtension` con `copyWith` y `lerp`.
- `colors.dart`: mapeo de la paleta y extensión `context.appColors`.
- `theme_controller.dart`: variante activa, notificaciones y persistencia.

Reglas que deben conservarse:

- Las variantes actuales son `normal` (verde) y `pink`, ambas con light y dark.
- Conserva exactamente los colores de referencia React Native presentes en las
  paletas. No regeneres sus valores con `ColorScheme.fromSeed`.
- El modo sigue al sistema mediante `ThemeMode.system`; la variante se guarda en
  shared_preferences con la clave exacta `@user_theme_variant` y su nombre estable.
- Restaura la variante antes de mostrar la aplicación. Un valor desconocido debe
  resolver a `normal`.
- Cambia la variante mediante `ThemeController.setVariant`; no introduzcas estado
  global mutable ni persistas índices del enum.
- Usa `context.appColors` para colores personalizados y el tema Material para
  componentes estándar. Evita colores fijos en pantallas.
- Mapea `tertiary` desde su valor real y `tabIcon` a `tabIconDefault`.
- Mantén `theme`, `darkTheme` y `themeMode` conectados al controlador en
  `MaterialApp.router`, con reconstrucción al cambiar la variante.
- Al agregar una variante, incorpora su valor en `ThemeVariant`, sus dos paletas
  y su entrada en `themeVariants`. Actualiza las pruebas correspondientes.
- Al agregar propiedades a `MappedPalette`, actualiza el mapeo, `copyWith` y `lerp`.

## Interfaz

Reutiliza `ResponsiveBody` y los componentes de autenticación cuando corresponda.
Conserva el comportamiento adaptable, las áreas seguras, el desplazamiento con el
teclado y los estados de carga, vacío y error. Comprueba claro y oscuro cuando un
cambio afecte colores o componentes visuales.

## Validación

Ejecuta los comandos desde la raíz del proyecto:

```sh
flutter pub get
dart format <archivos_modificados.dart>
flutter analyze
flutter test
```

Ejecuta `flutter pub get` cuando falten dependencias o cambie `pubspec.yaml`.
Para cambios de temas, usa también la prueba específica:

```sh
flutter test test/theme_test.dart
```

Agrega pruebas para cambios de comportamiento: persistencia, mapeos, lógica y
actualización de widgets. Para cambios exclusivamente documentales, revisa el
contenido y `git diff --check`; no es necesario ejecutar Flutter.

Si una comprobación falla, determina si está relacionada con el cambio. Informa
los fallos pendientes sin ocultarlos ni modificar pruebas para forzar su éxito.
Al entregar, resume qué cambió, cómo se verificó y cualquier limitación relevante.
