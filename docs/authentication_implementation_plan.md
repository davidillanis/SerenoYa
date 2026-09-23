# Plan de implementación del módulo de autenticación

## SerenoYa

**Estado:** aprobado para implementación  
**Arquitectura:** Flutter MVVM con Repository, Services y capa de dominio  
**Protocolo:** REST sobre HTTPS  
**Referencia funcional:** módulo de autenticación de RappiGo  
**Fecha de elaboración:** 20 de septiembre de 2026

## 1. Objetivo

Implementar en SerenoYa un módulo de autenticación basado en los flujos funcionales y endpoints existentes de RappiGo, adaptándolo a una arquitectura MVVM consistente, segura, comprobable y escalable.

La implementación no copiará la organización interna híbrida de RappiGo. Todas las operaciones de autenticación deberán recorrer la misma dirección de dependencias:

```text
View
  -> ViewModel
    -> Auth Use Case
      -> AuthRepository
        -> AuthApiService / SessionStorageService
          -> REST API / Secure Storage
```

## 2. Alcance funcional

El módulo incluirá:

- Inicio de sesión con correo y contraseña.
- Inicio de sesión con Google, si se configura el proveedor para SerenoYa.
- Registro público de ciudadanos.
- Validación de access token.
- Renovación de sesión mediante refresh token.
- Recuperación de contraseña.
- Restablecimiento de contraseña mediante token.
- Restauración segura de sesión al abrir la aplicación.
- Cierre de sesión local completo.
- Navegación y protección de rutas por rol.
- Manejo automático de respuestas HTTP `401`.

Módulos autorizables:

- `Citizen`
- `Officer`
- `Administrator`
- `Developer`

## 3. Decisión arquitectónica

Se utilizará MVVM siguiendo las recomendaciones oficiales de Flutter:

- Las Views muestran estado y delegan acciones.
- Cada pantalla tiene su propio ViewModel.
- Los ViewModels exponen estado inmutable y comandos.
- El repositorio es la única fuente de verdad de la sesión.
- Los servicios encapsulan fuentes externas y no mantienen estado de negocio.
- La inyección de dependencias se realiza por constructor.
- La navegación declarativa y sus redirecciones se implementan con `go_router`.
- La capa de dominio se utilizará en autenticación porque sus reglas son transversales, reutilizables y sensibles.

Referencias:

- [Flutter: Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter: Architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations)

## 4. Estructura objetivo

```text
lib/
|-- app/
|   |-- app.dart
|   |-- app_bootstrap.dart
|   `-- app_dependencies.dart
|
|-- config/
|   |-- api_config.dart
|   `-- environment.dart
|
|-- routing/
|   |-- app_router.dart
|   |-- route_names.dart
|   `-- role_route_resolver.dart
|
|-- domain/
|   |-- models/
|   |   |-- auth_session.dart
|   |   |-- authenticated_user.dart
|   |   |-- auth_failure.dart
|   |   `-- user_role.dart
|   |-- repositories/
|   |   `-- auth_repository.dart
|   `-- use_cases/
|       `-- auth/
|           |-- login_use_case.dart
|           |-- google_login_use_case.dart
|           |-- register_citizen_use_case.dart
|           |-- validate_session_use_case.dart
|           |-- restore_session_use_case.dart
|           |-- refresh_session_use_case.dart
|           |-- forgot_password_use_case.dart
|           |-- reset_password_use_case.dart
|           `-- logout_use_case.dart
|
|-- data/
|   |-- models/
|   |   `-- auth/
|   |       |-- api_response_dto.dart
|   |       |-- auth_response_dto.dart
|   |       |-- authenticated_user_dto.dart
|   |       |-- login_request_dto.dart
|   |       |-- refresh_token_request_dto.dart
|   |       |-- register_citizen_request_dto.dart
|   |       `-- reset_password_request_dto.dart
|   |-- repositories/
|   |   `-- auth_repository_impl.dart
|   `-- services/
|       |-- api/
|       |   |-- api_client.dart
|       |   |-- auth_api_service.dart
|       |   `-- auth_interceptor.dart
|       `-- storage/
|           `-- session_storage_service.dart
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
        |-- command.dart
        |-- result.dart
        `-- widgets/
```

## 5. Reglas de dependencia

1. Una View solo puede conocer su ViewModel y componentes visuales.
2. Un ViewModel solo puede consumir casos de uso y modelos de dominio.
3. Un caso de uso depende del contrato abstracto `AuthRepository`.
4. `AuthRepositoryImpl` implementa el contrato de dominio y coordina servicios.
5. Los servicios no conocen repositorios, casos de uso, ViewModels ni Views.
6. Los DTO solo existen dentro de la capa `data`.
7. Las excepciones de Dio no pueden llegar directamente a UI.
8. Los modelos de dominio no importan Flutter, Dio ni almacenamiento seguro.
9. Todas las variantes de login deben utilizar la misma cadena arquitectónica.

## 6. Endpoints de RappiGo que se replicarán

La URL base será configurable por ambiente. La ruta usada actualmente por RappiGo es `/api/v1`, pero SerenoYa no debe fijar el dominio de RappiGo dentro del código.

| Método | Ruta | Operación | Autenticación |
|---|---|---|---|
| `POST` | `/auth/login` | Iniciar sesión con credenciales | Pública |
| `POST` | `/auth/google-login` | Intercambiar token de Google por sesión propia | Pública |
| `GET` | `/auth/validateToken/{token}` | Validar access token | Token en ruta por compatibilidad |
| `POST` | `/auth/refresh` | Renovar access y refresh token | Refresh token en body |
| `POST` | `/auth/forgot-password` | Solicitar recuperación de contraseña | Pública |
| `POST` | `/auth/reset-password` | Establecer una contraseña nueva | Token de recuperación en body |
| `POST` | `/user-role/create-customer` | Registrar un ciudadano | Pública |

### 6.1 Inicio de sesión

```http
POST /auth/login
Content-Type: application/json
```

```json
{
  "email": "ciudadano@example.com",
  "password": "secret"
}
```

Respuesta esperada:

```json
{
  "isSuccess": true,
  "message": "Inicio de sesión exitoso",
  "data": {
    "id": 1,
    "name": "Dani",
    "lastName": "Quispe",
    "imageUrl": null,
    "phone": "999999999",
    "accessToken": "access-token",
    "refreshToken": "refresh-token"
  },
  "errors": null
}
```

El correo, los roles y los identificadores asociados pueden obtenerse de los claims del JWT, tal como ocurre en RappiGo, pero deberán transformarse a un modelo de dominio dentro del repositorio.

### 6.2 Login con Google

```http
POST /auth/google-login
Content-Type: application/json
```

```json
{
  "idToken": "google-id-token"
}
```

El backend valida el token de Google y devuelve la misma estructura de sesión que `/auth/login`. La aplicación nunca utilizará el token de Google como access token de la API de SerenoYa.

Esta operación quedará incluida en el contrato, pero su activación en UI dependerá de contar con las credenciales OAuth para Android, iOS y web.

### 6.3 Validación de token

```http
GET /auth/validateToken/{token}
```

Respuesta esperada:

```json
{
  "isSuccess": true,
  "data": true,
  "errors": null
}
```

Se replicará esta ruta por compatibilidad con RappiGo. Sin embargo, enviar el token dentro de la URL puede exponerlo en historiales, proxies y logs. Se registrará como mejora prioritaria reemplazarla por una de estas alternativas:

```text
GET  /auth/me
POST /auth/validate
```

En ambas alternativas el access token se enviaría mediante `Authorization: Bearer`.

### 6.4 Renovación de sesión

```http
POST /auth/refresh
Content-Type: application/json
```

```json
{
  "refreshToken": "refresh-token"
}
```

La respuesta conserva el mismo formato de `/auth/login` y debe contener un access token y un refresh token nuevos.

Reglas del cliente:

- Guardar los dos tokens nuevos como una sola operación lógica.
- No continuar utilizando el access token anterior.
- Permitir un solo refresh simultáneo.
- Reintentar una solicitud fallida una sola vez.
- Limpiar la sesión si el refresh es rechazado.
- Excluir `/auth/login`, `/auth/google-login` y `/auth/refresh` del refresh automático.

### 6.5 Recuperación de contraseña

```http
POST /auth/forgot-password
Content-Type: application/json
```

```json
{
  "email": "ciudadano@example.com"
}
```

La respuesta de RappiGo utiliza `ResponseStatusDTO<string>`. El cliente no debe revelar si el correo existe; se mostrará un mensaje neutral siempre que la solicitud sea aceptada.

### 6.6 Restablecimiento de contraseña

```http
POST /auth/reset-password
Content-Type: application/json
```

```json
{
  "token": "password-reset-token",
  "newPassword": "new-secret",
  "email": "ciudadano@example.com"
}
```

La contraseña será validada en el ViewModel para experiencia de usuario y nuevamente en el backend como regla de seguridad.

### 6.7 Registro de ciudadano

RappiGo registra clientes fuera de `/auth`, mediante:

```http
POST /user-role/create-customer
Content-Type: application/json
```

Payload compatible:

```json
{
  "name": "Dani",
  "lastName": "Quispe",
  "dni": "12345678",
  "phone": "999999999",
  "address": "San Jerónimo",
  "imageUrl": "",
  "email": "ciudadano@example.com",
  "password": "secret",
  "roles": ["CITIZEN"]
}
```

Adaptación obligatoria para SerenoYa:

- El registro público solo puede producir usuarios `Citizen`.
- El backend debe ignorar o rechazar cualquier rol privilegiado recibido desde el cliente.
- `Officer`, `Administrator` y `Developer` solo se asignan mediante operaciones administrativas protegidas.
- Si el backend exige conservar el valor de RappiGo, `CLIENTE` se mapeará internamente a `UserRole.citizen`.
- La aplicación nunca tomará el rol enviado durante el registro como prueba de autorización.

## 7. Envelope de respuesta

Se conservará el envelope compatible con RappiGo:

```json
{
  "isSuccess": true,
  "message": "Descripción opcional",
  "data": {},
  "errors": null
}
```

Contrato conceptual:

```text
ApiResponseDto<T>
  isSuccess: bool
  message: String?
  data: T?
  errors: List<String>?
```

En SerenoYa los campos esenciales no serán opcionales silenciosamente. El servicio validará el formato y el repositorio lo convertirá a `Result<T>` o `AuthFailure` antes de entregarlo al dominio.

## 8. Mapeo de roles

| Rol externo compatible | Rol de dominio SerenoYa | Módulo UI |
|---|---|---|
| `CLIENTE` o `CITIZEN` | `UserRole.citizen` | `ui/citizen` |
| `REPARTIDOR`, `DEALER_EDITOR`, `SERENAZGO` u `OFFICER` | `UserRole.officer` | `ui/officer` |
| `ADMINISTRADOR` o `ADMINISTRATOR` | `UserRole.administrator` | `ui/admin` |
| `DEVELOPMENT` o `DEVELOPER` | `UserRole.developer` | `ui/dev_tools` |

No se incluirá el rol `RESTAURANTE`, porque no pertenece al dominio funcional de SerenoYa.

Para la primera versión cada cuenta deberá tener un único rol operativo. Si el backend devuelve varios roles, SerenoYa no escogerá el primero de manera implícita. La sesión se marcará como ambigua hasta aplicar una política definida o presentar una selección de contexto.

## 9. Fuente de verdad y estados de sesión

`AuthRepository` será la única fuente de verdad y expondrá un estado observable equivalente a:

```text
unknown
unauthenticated
authenticating
authenticated
refreshing
expired
```

Transición inicial:

```text
Aplicación inicia
  -> leer tokens seguros
    -> no existen: unauthenticated
    -> existen:
       -> access token vigente: validar sesión
       -> access token vencido: refresh
          -> refresh exitoso: authenticated
          -> refresh rechazado: limpiar -> unauthenticated
```

La decodificación local del JWT solo podrá utilizarse para leer expiración y claims de presentación. La autorización real será responsabilidad del backend.

## 10. Almacenamiento seguro

Se utilizará `flutter_secure_storage` para:

- `accessToken`
- `refreshToken`

No se almacenarán:

- Contraseñas.
- Tokens en preferencias sin cifrar.
- Encabezados HTTP.
- Respuestas completas innecesarias.
- Excepciones que contengan credenciales.

El usuario autenticado se mantendrá en memoria. Si posteriormente se requiere persistencia para modo offline, se almacenará un perfil mínimo y no sensible con una estrategia independiente.

## 11. Interceptor HTTP

`AuthInterceptor` deberá:

1. Adjuntar el access token a solicitudes protegidas.
2. Detectar respuestas `401`.
3. Coordinar un único refresh aunque fallen varias solicitudes simultáneamente.
4. Esperar el resultado del refresh en las solicitudes pendientes.
5. Reintentar cada solicitud una sola vez con el token nuevo.
6. Cerrar la sesión cuando no sea posible renovarla.
7. Evitar ciclos sobre endpoints públicos y de refresh.
8. Omitir tokens y datos sensibles de logs.

## 12. Navegación

Rutas previstas:

```text
/splash
/login
/register
/forgot-password
/reset-password
/citizen
/officer
/admin
/dev
/unauthorized
```

Política de redirección:

| Estado | Destino |
|---|---|
| Sesión no inicializada | `/splash` |
| Sin sesión | `/login` |
| `Citizen` | `/citizen` |
| `Officer` | `/officer` |
| `Administrator` | `/admin` |
| `Developer` | `/dev` |
| Rol desconocido o ambiguo | `/unauthorized` |

Los guards del cliente mejoran navegación y experiencia de usuario, pero no sustituyen la autorización del backend.

## 13. Dependencias previstas

Las versiones se resolverán durante la implementación según la versión estable de Flutter utilizada por el proyecto.

- `provider`: inyección y exposición de ViewModels.
- `go_router`: navegación y redirecciones.
- `dio`: API REST e interceptores.
- `flutter_secure_storage`: almacenamiento de tokens.
- `json_annotation`: contratos JSON.
- `json_serializable`: generación de serialización.
- `build_runner`: generación de código.
- `mocktail` o fakes manuales: pruebas unitarias.

Se utilizará inyección por constructor. No se incorporará inicialmente un service locator.

## 14. Plan por fases

### Fase 1: contratos y modelos

- [ ] Confirmar URL base por ambiente.
- [ ] Confirmar los siete endpoints compatibles.
- [ ] Confirmar envelope de respuesta.
- [ ] Definir `AuthenticatedUser`, `AuthSession`, `UserRole` y `AuthFailure`.
- [ ] Definir `AuthRepository`.
- [ ] Crear DTO separados de los modelos del dominio.

### Fase 2: servicios y repositorio

- [ ] Configurar Dio y timeouts.
- [ ] Implementar `AuthApiService`.
- [ ] Implementar `SessionStorageService`.
- [ ] Implementar mapeadores DTO a dominio.
- [ ] Implementar `AuthRepositoryImpl` como fuente de verdad.

### Fase 3: ciclo de sesión

- [ ] Implementar login.
- [ ] Implementar restauración de sesión.
- [ ] Implementar validación de token compatible.
- [ ] Implementar refresh.
- [ ] Implementar interceptor de `401`.
- [ ] Implementar logout local completo.

### Fase 4: casos de uso

- [ ] Login con credenciales.
- [ ] Login con Google.
- [ ] Registro de ciudadano.
- [ ] Recuperación de contraseña.
- [ ] Restablecimiento de contraseña.
- [ ] Restauración, validación, renovación y cierre de sesión.

### Fase 5: ViewModels y Views

- [ ] Crear estados inmutables.
- [ ] Implementar comandos y bloqueo de envíos duplicados.
- [ ] Implementar pantalla de login.
- [ ] Implementar registro.
- [ ] Implementar recuperación y restablecimiento.
- [ ] Mostrar errores seguros y comprensibles.

### Fase 6: routing y roles

- [ ] Configurar `go_router`.
- [ ] Crear guard global de autenticación.
- [ ] Crear redirección por rol.
- [ ] Proteger los cuatro módulos.
- [ ] Implementar pantalla de acceso no autorizado.

### Fase 7: pruebas y endurecimiento

- [ ] Probar servicios y parsing de respuestas.
- [ ] Probar repositorio, persistencia y transiciones de sesión.
- [ ] Probar cada ViewModel sin widgets.
- [ ] Probar formularios mediante widget tests.
- [ ] Probar redirecciones por sesión y rol.
- [ ] Probar múltiples respuestas `401` simultáneas.
- [ ] Probar refresh rechazado.
- [ ] Probar logout sin conexión.
- [ ] Verificar que los tokens no aparezcan en logs.

## 15. Endpoints futuros recomendados

Estos endpoints no existen en el módulo revisado de RappiGo y, por tanto, no forman parte de la réplica inicial:

```text
POST /auth/logout
GET  /auth/me
```

Se recomiendan para una segunda iteración:

- `/auth/logout` permitiría revocar el refresh token en el servidor.
- `/auth/me` permitiría validar la sesión y obtener el usuario sin colocar el token en la URL.

Hasta que exista `/auth/logout`, SerenoYa eliminará siempre ambos tokens de forma local durante el cierre de sesión.

## 16. Criterios de finalización

El módulo estará terminado cuando:

- Todos los flujos sigan la misma cadena MVVM.
- Ninguna View o ViewModel realice solicitudes HTTP directas.
- El repositorio sea la única fuente de verdad de la sesión.
- Los tokens se almacenen de forma segura.
- El refresh funcione al iniciar y ante respuestas `401`.
- El logout elimine access token, refresh token y sesión en memoria.
- Los siete endpoints compatibles estén encapsulados en servicios.
- Cada módulo privado valide sesión y rol.
- Los errores de red estén transformados antes de llegar a UI.
- Los escenarios críticos tengan pruebas automatizadas.
- `flutter analyze` y la suite de tests finalicen sin errores.

## 17. Fuentes verificadas en RappiGo

- [`AuthService.ts`](../../RappiGo/src/domain/services/AuthService.ts)
- [`UserService.ts`](../../RappiGo/src/domain/services/UserService.ts)
- [`AuthEntity.ts`](../../RappiGo/src/domain/entities/AuthEntity.ts)
- [`UserEntity.ts`](../../RappiGo/src/domain/entities/UserEntity.ts)
- [`AuthContext.tsx`](../../RappiGo/src/presentation/context/AuthContext.tsx)
- [`DecodeToken.ts`](../../RappiGo/src/infrastructure/configuration/security/DecodeToken.ts)

Los endpoints y payloads de este documento fueron obtenidos del estado de RappiGo identificado por el commit `37d137b` (`refactor auth service`).
