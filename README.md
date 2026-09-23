# SerenoYa

Aplicación Flutter para reportar incidentes ciudadanos y coordinar su atención
por el Serenazgo de San Jerónimo.

## Ejecución

```powershell
flutter pub get
flutter run
```

La aplicación consume por defecto la API usada por RappiGo:

```text
https://oopsissora.com/api/v1
```

La URL puede sustituirse por ambiente sin modificar el código:

```powershell
flutter run --dart-define=API_BASE_URL=https://example.com/api/v1
```

## Verificación

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

La planificación del módulo está en
[`docs/authentication_implementation_plan.md`](docs/authentication_implementation_plan.md).
