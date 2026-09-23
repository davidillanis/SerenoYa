# Plan de migración a Flutter MVVM

## SerenoYa

**Estado:** pendiente de implementación  
**Arquitectura objetivo:** MVVM recomendado por Flutter  
**Flujo:** View -> ViewModel -> Repository -> Service  
**API:** RappiGo  
**Fecha:** 21 de septiembre de 2026

## 1. Objetivo

Migrar el módulo de autenticación actual de SerenoYa desde una estructura MVVM
con capa de dominio y casos de uso hacia una implementación MVVM directa,
consistente con la arquitectura recomendada por Flutter.

La migración eliminará la capa `domain` y las clases `UseCase`, sin modificar el
comportamiento funcional, los endpoints de RappiGo, la seguridad de la sesión ni
la navegación por roles.

## 2. Arquitectura definitiva

```text
View
  -> ViewModel
    -> Repository
      -> Service
```

Responsabilidades:

- **View:** representa la interfaz y envía eventos al ViewModel.
- **ViewModel:** administra el estado visual, valida entradas y ejecuta acciones.
- **Repository:** es la fuente de verdad y coordina los datos de la aplicación.
- **Service:** encapsula APIs REST, almacenamiento y servicios de plataforma.

Se aplicarán Repository Pattern, inyección por constructor y separación de
responsabilidades. Estos patrones forman parte de una implementación MVVM
mantenible y no requieren una capa de Clean Architecture.

Referencia: [Flutter app architecture](https://docs.flutter.dev/app-architecture/guide).

## 3. Comparación

### Estructura actual

```text
View
  -> ViewModel
    -> UseCase
      -> AuthRepository
        -> AuthRepositoryImpl
          -> Service
```

### Estructura objetivo

```text
View
  -> ViewModel
    -> AuthRepository
      -> AuthApiService
      -> SessionStorageService
```

## 4. Estructura de carpetas objetivo

```text
lib/
|-- main.dart
|
|-- app/
|   |-- app.dart
|   `-- app_dependencies.dart
|
|-- config/
|   `-- api_config.dart
|
|-- models/
|   |-- auth_failure.dart
|   |-- auth_session.dart
|   |-- auth_state.dart
|   |-- authenticated_user.dart
|   |-- result.dart
|   `-- user_role.dart
|
|-- data/
|   |-- models/
|   |   `-- auth/
|   |       |-- api_response_dto.dart
|   |       |-- auth_response_dto.dart
|   |       `-- jwt_claims.dart
|   |
|   |-- repositories/
|   |   |-- auth_repository.dart
|   |   `-- auth_repository_impl.dart
|   |
|   `-- services/
|       |-- api/
|       |   |-- api_client.dart
|       |   |-- auth_api_service.dart
|       |   `-- auth_interceptor.dart
|       `-- storage/
|           `-- session_storage_service.dart
|
|-- routing/
|   |-- app_router.dart
|   |-- auth_router_notifier.dart
|   |-- role_route_resolver.dart
|   `-- route_names.dart
|
`-- ui/
    |-- auth/
    |   |-- login_screen.dart
    |   |-- register_screen.dart
    |   |-- forgot_password_screen.dart
    |   |-- reset_password_screen.dart
    |   |-- session_gate_screen.dart
    |   |-- view_models/
    |   |   |-- login_view_model.dart
    |   |   |-- register_view_model.dart
    |   |   |-- forgot_password_view_model.dart
    |   |   |-- reset_password_view_model.dart
    |   |   `-- session_view_model.dart
    |   `-- widgets/
    `-- core/
        |-- role_home_screen.dart
        `-- unauthorized_screen.dart
```

## 5. Reglas arquitectónicas

1. Las Views solo pueden acceder a su ViewModel y a componentes visuales.
2. Los ViewModels pueden acceder al contrato `AuthRepository`.
3. Los ViewModels no pueden acceder a Dio ni a Secure Storage.
4. El repositorio coordina API, almacenamiento y estado de sesión.
5. Los Services no pueden conocer Views, ViewModels ni routing.
6. Los DTO pertenecen exclusivamente a `data/models`.
7. Los modelos consumidos por UI pertenecen a `lib/models`.
8. El repositorio es la única fuente de verdad de la sesión.
9. Las excepciones de Dio se transforman antes de llegar al ViewModel.
10. La autorización definitiva siempre corresponde al backend.

## 6. Transformación de archivos

| Elemento actual | Acción |
|---|---|
| `domain/models/` | Mover a `lib/models/` |
| `domain/repositories/auth_repository.dart` | Mover a `data/repositories/` |
| `domain/use_cases/auth/` | Eliminar completamente |
| `data/repositories/auth_repository_impl.dart` | Mantener |
| `data/services/` | Mantener |
| `data/models/auth/` | Mantener |
| ViewModels | Inyectar directamente `AuthRepository` |
| Views | Mantener sin acceso directo al repositorio |
| `AppDependencies` | Dejar de construir casos de uso |
| Routing | Continuar observando `AuthRepository.state` |

## 7. Dependencias de los ViewModels

### LoginViewModel

```text
LoginViewModel
  -> AuthRepository.login()
  -> AuthRepository.loginWithGoogleIdToken()
```

### RegisterViewModel

```text
RegisterViewModel
  -> AuthRepository.registerCitizen()
```

### ForgotPasswordViewModel

```text
ForgotPasswordViewModel
  -> AuthRepository.forgotPassword()
```

### ResetPasswordViewModel

```text
ResetPasswordViewModel
  -> AuthRepository.resetPassword()
```

### SessionViewModel

```text
SessionViewModel
  -> AuthRepository.initialize()
  -> AuthRepository.logout()
  <- AuthRepository.states
```

## 8. Endpoints que se conservarán

La migración no cambiará la API de RappiGo utilizada actualmente:

| Método | Endpoint |
|---|---|
| `POST` | `/auth/login` |
| `POST` | `/auth/google-login` |
| `GET` | `/auth/validateToken/{token}` |
| `POST` | `/auth/refresh` |
| `POST` | `/auth/forgot-password` |
| `POST` | `/auth/reset-password` |
| `POST` | `/user-role/create-customer` |

También se conservarán:

- URL predeterminada `https://oopsissora.com/api/v1`.
- Configuración alternativa mediante `API_BASE_URL`.
- Rol `CLIENTE` en el registro ciudadano.
- Mapeo de roles de RappiGo a SerenoYa.
- Tokens en `flutter_secure_storage`.
- Refresh automático ante respuestas `401`.
- Restauración de sesión.
- Guards de navegación por rol.

## 9. Fases de implementación

### Fase 1: línea base

- [ ] Ejecutar `flutter analyze`.
- [ ] Ejecutar `flutter test`.
- [ ] Compilar el APK de depuración.
- [ ] Confirmar que el comportamiento actual funciona antes de migrar.

### Fase 2: reorganización de modelos

- [ ] Crear `lib/models`.
- [ ] Mover los modelos de aplicación desde `domain/models`.
- [ ] Actualizar imports.
- [ ] Mantener los DTO dentro de `data/models`.

### Fase 3: repositorio

- [ ] Mover `AuthRepository` a `data/repositories`.
- [ ] Mantener `AuthRepositoryImpl` en la capa `data`.
- [ ] Actualizar imports en composición, routing y ViewModels.
- [ ] Verificar que el repositorio siga siendo la fuente de verdad.

### Fase 4: eliminación de casos de uso

Eliminar:

- [ ] `login_use_case.dart`
- [ ] `google_login_use_case.dart`
- [ ] `register_citizen_use_case.dart`
- [ ] `forgot_password_use_case.dart`
- [ ] `reset_password_use_case.dart`
- [ ] `restore_session_use_case.dart`
- [ ] `refresh_session_use_case.dart`
- [ ] `validate_session_use_case.dart`
- [ ] `logout_use_case.dart`

### Fase 5: simplificación de ViewModels

- [ ] Inyectar `AuthRepository` en `LoginViewModel`.
- [ ] Inyectar `AuthRepository` en `RegisterViewModel`.
- [ ] Inyectar `AuthRepository` en `ForgotPasswordViewModel`.
- [ ] Inyectar `AuthRepository` en `ResetPasswordViewModel`.
- [ ] Inyectar `AuthRepository` en `SessionViewModel`.
- [ ] Sustituir todas las llamadas a `UseCase.execute()`.
- [ ] Mantener validaciones y estados visuales actuales.

### Fase 6: composición de dependencias

`AppDependencies` construirá únicamente:

- [ ] `ApiClient`
- [ ] `SessionStorageService`
- [ ] `AuthApiService`
- [ ] `AuthRepositoryImpl`
- [ ] `AuthInterceptor`
- [ ] `AuthRouterNotifier`
- [ ] `GoRouter`

### Fase 7: routing

- [ ] Crear ViewModels de ruta con el mismo `AuthRepository`.
- [ ] Mantener redirecciones según estado de sesión.
- [ ] Mantener guards para los cuatro roles.
- [ ] Verificar acceso no autorizado.

### Fase 8: limpieza

- [ ] Eliminar `lib/domain` cuando quede vacío.
- [ ] Eliminar imports obsoletos.
- [ ] Verificar que no existan referencias a `UseCase`.
- [ ] Actualizar la documentación arquitectónica.
- [ ] Ejecutar `dart format lib test`.

### Fase 9: verificación final

- [ ] Ejecutar `flutter analyze` sin observaciones.
- [ ] Ejecutar todas las pruebas.
- [ ] Compilar el APK de depuración.
- [ ] Verificar manualmente login y navegación por rol.
- [ ] Verificar registro y recuperación de contraseña.
- [ ] Verificar refresh y logout.

## 10. Pruebas requeridas

- Login exitoso.
- Credenciales incorrectas.
- Registro de ciudadano.
- Recuperación de contraseña.
- Restablecimiento de contraseña.
- Restauración con access token válido.
- Restauración con access token vencido.
- Refresh exitoso y rechazado.
- Múltiples respuestas `401` simultáneas.
- Logout eliminando ambos tokens.
- Conversión de roles de RappiGo.
- Redirección hacia cada módulo.
- Sesión offline únicamente con JWT vigente.

## 11. Criterios de finalización

La migración estará terminada cuando:

- No exista `lib/domain`.
- No existan clases `UseCase`.
- Todos los ViewModels dependan directamente de `AuthRepository`.
- Ninguna View acceda directamente al repositorio o a un servicio.
- Ningún ViewModel acceda a Dio o Secure Storage.
- El repositorio conserve el estado global de sesión.
- Los siete endpoints de RappiGo mantengan su comportamiento.
- El refresh automático y el almacenamiento seguro continúen funcionando.
- `flutter analyze` no reporte problemas.
- Todas las pruebas estén aprobadas.
- El APK Android compile correctamente.

## 12. Nombre oficial de la arquitectura

La arquitectura del proyecto se documentará como:

> **Flutter MVVM: Views, ViewModels, Repositories and Services**

No se describirá como Clean Architecture ni como una arquitectura híbrida.
