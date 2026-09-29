# Plan de preparación del frontend para inicio de sesión con Google

## SerenoYa

**Estado:** propuesta para implementación  
**Alcance:** frontend Flutter y contrato de integración con el backend  
**Fecha de elaboración:** 27 de septiembre de 2026  
**Documento relacionado:** [Plan de implementación del módulo de autenticación](authentication_implementation_plan.md)

## 1. Objetivo

Preparar SerenoYa para autenticar usuarios mediante Google sin reemplazar el
sistema de sesiones actual.

El flujo esperado es:

```text
Usuario
  -> Google Sign-In
    -> ID token de Google
      -> POST /auth/google-login
        -> Validación del token en el backend
          -> Access token y refresh token de SerenoYa
            -> Sesión, autorización por rol y navegación existentes
```

Google solo comprobará la identidad del usuario. El backend de SerenoYa seguirá
siendo responsable de crear o vincular la cuenta, asignar roles y emitir los
tokens que autorizan el uso de la API.

No es obligatorio incorporar Firebase Authentication. El paquete
`google_sign_in` puede registrarse directamente contra Google Cloud y entregar
el ID token al backend existente.

## 2. Estado actual del proyecto

SerenoYa ya dispone de:

- `LoginViewModel.loginWithGoogleIdToken(...)`.
- `AuthRepository.loginWithGoogleIdToken(...)` y su implementación.
- La llamada pública `POST /auth/google-login` con el cuerpo
  `{ "idToken": "..." }`.
- Persistencia segura de los tokens propios de SerenoYa.
- Restauración y renovación de sesión.
- Redirección automática mediante `GoRouter` según el rol incluido en el access
  token.

Todavía falta:

- Incorporar el SDK de Google Sign-In a Flutter.
- Configurar las credenciales OAuth para las plataformas soportadas.
- Obtener el ID token de Google desde una capa de servicio.
- Conectar el flujo con `LoginViewModel` y `LoginScreen`.
- Sincronizar el cierre de sesión local con Google Sign-In.
- Cubrir cancelaciones, fallos de configuración y errores mediante pruebas.

## 3. Decisiones previas obligatorias

### 3.1 Plataformas iniciales

Definir cuáles serán parte de la primera entrega:

- Android.
- iOS.
- Web.
- macOS, Windows o Linux, si se publicarán realmente.

Se recomienda implementar Android primero y habilitar cada plataforma adicional
solo después de configurar y comprobar sus propias credenciales.

### 3.2 Identificadores definitivos de la aplicación

El proyecto todavía utiliza identificadores de ejemplo:

- Android: `com.example.sereno_ya`.
- iOS: `com.example.serenoYa`.

Antes de crear los clientes OAuth se deben definir los identificadores de
producción. Cambiarlos posteriormente obligaría a registrar nuevas credenciales.

El identificador debe:

- Ser único y estable.
- Pertenecer a un dominio controlado por la organización responsable.
- Mantenerse coherente entre configuraciones de desarrollo, pruebas y
  producción, o usar variantes explícitas cuando corresponda.

### 3.3 Política para cuentas Google

El equipo debe decidir qué hará el backend cuando reciba una identidad válida:

1. Permitir solo correos que ya existan en SerenoYa.
2. Crear automáticamente una cuenta de ciudadano.
3. Vincular Google a una cuenta existente después de una verificación adicional.

La recomendación inicial es habilitar Google para ciudadanos y conservar el
acceso tradicional para serenazgo y administradores, salvo que exista una
política institucional diferente.

También se debe definir el comportamiento para:

- Una cuenta existente con el mismo correo, pero creada con contraseña.
- Una cuenta deshabilitada o bloqueada.
- Una cuenta válida sin rol operativo.
- Un correo de Google no verificado.
- Un usuario que intenta cambiar el correo vinculado.

## 4. Configuración de Google Cloud

### 4.1 Proyecto y pantalla de consentimiento

Crear o reutilizar un proyecto de Google Cloud y configurar:

- Nombre visible `SerenoYa`.
- Correo de soporte.
- Datos de contacto del desarrollador.
- Logotipo, dominio, política de privacidad y términos, cuando sean requeridos.
- Usuarios de prueba mientras la aplicación permanezca en modo de pruebas.
- Estado de publicación apropiado para el entorno.

Para autenticación básica se solicitarán únicamente los datos necesarios para
identidad, normalmente `openid`, `email` y `profile`. No se deben solicitar
permisos para otras APIs de Google si la aplicación no los necesita.

### 4.2 Cliente OAuth web o de servidor

Crear un cliente OAuth de tipo **Aplicación web**. Su Client ID será el
`serverClientId` y cumplirá dos funciones:

- Indicar a Google para qué backend se solicita el ID token.
- Servir como audiencia (`aud`) que el backend de SerenoYa debe validar.

El frontend y el backend deben usar exactamente el mismo Client ID. Un desajuste
puede permitir que el selector de Google finalice correctamente, pero hará que
`/auth/google-login` rechace el token.

El Client ID no es una credencial secreta. El client secret del cliente web no
debe incluirse en Flutter, archivos versionados, logs ni variables de compilación
del frontend.

### 4.3 Cliente OAuth Android

Crear al menos un cliente OAuth de tipo **Android** con:

- Application ID definitivo.
- SHA-1 del certificado de desarrollo.
- SHA-1 del certificado de release.
- SHA-1 de Google Play App Signing cuando la aplicación se publique mediante
  Google Play.

Si existen sabores o aplicaciones con identificadores y certificados distintos,
cada combinación necesita su configuración correspondiente.

Los SHA se pueden obtener mediante el reporte de firma de Gradle o `keytool`.
No se debe usar la clave de desarrollo para firmar una versión de producción.

La integración puede realizarse de dos maneras:

- Registro directo en Google Cloud y entrega del Web Client ID como
  `serverClientId` al inicializar `GoogleSignIn`.
- Registro mediante Firebase y `google-services.json`, siempre que el archivo
  incluya también un cliente OAuth web.

Para SerenoYa se recomienda el registro directo mientras Firebase no sea una
dependencia funcional del proyecto.

### 4.4 Cliente OAuth iOS

Si se soportará iOS, crear un cliente OAuth de tipo **iOS** con el Bundle ID
definitivo. Luego configurar en `ios/Runner/Info.plist`:

- `GIDClientID` con el Client ID de iOS.
- `GIDServerClientID` con el Client ID web usado por el backend.
- `CFBundleURLTypes` con el esquema de URL del Client ID de iOS invertido.

La aplicación debe estar correctamente firmada para que el SDK pueda utilizar
Keychain.

Antes de publicar en App Store se deben revisar los requisitos vigentes de Apple
para aplicaciones que ofrecen proveedores de inicio de sesión de terceros,
incluida la posible necesidad de ofrecer Sign in with Apple.

### 4.5 Cliente OAuth web

Si se soportará Flutter Web:

- Registrar el dominio de producción como origen JavaScript autorizado.
- Registrar los orígenes locales necesarios para desarrollo.
- Utilizar un puerto local fijo para evitar cambiar la configuración en cada
  ejecución.
- Configurar el Client ID en `web/index.html` o durante la inicialización,
  siguiendo la documentación de la versión del paquete utilizada.
- Renderizar en web el botón provisto por Google Sign-In; el flujo web no utiliza
  el mismo botón personalizado que Android o iOS.

No deben autorizarse dominios genéricos ni orígenes que no controle el equipo.

## 5. Contrato y responsabilidades del backend

El endpoint existente deberá aceptar:

```http
POST /auth/google-login
Content-Type: application/json

{
  "idToken": "TOKEN_DE_IDENTIDAD_DE_GOOGLE"
}
```

El backend debe validar como mínimo:

- Firma criptográfica mediante las claves públicas vigentes de Google.
- Emisor (`iss`) permitido.
- Audiencia (`aud`) igual al Web Client ID acordado.
- Fecha de expiración (`exp`).
- Correo verificado (`email_verified`), cuando el correo se use para vincular o
  crear cuentas.
- Estado local del usuario y roles autorizados en SerenoYa.

No se debe confiar en el correo, nombre, foto ni roles enviados directamente por
el frontend. La identidad debe extraerse del token ya validado y la autorización
debe resolverse con los datos del backend.

Después de validar Google, el endpoint debe devolver la misma estructura de
sesión que el login por correo:

- Access token de SerenoYa.
- Refresh token de SerenoYa.
- Identificador y datos del usuario.
- Roles operativos.

El ID token de Google nunca reemplazará al access token de SerenoYa para consumir
la API.

## 6. Integración Flutter propuesta

### 6.1 Dependencia

Agregar al `pubspec.yaml` una versión compatible de `google_sign_in`. Al momento
de elaborar este documento, la versión estable publicada es:

```yaml
dependencies:
  google_sign_in: ^7.2.0
```

Antes de incorporarla se debe comprobar su compatibilidad con la versión de
Flutter utilizada por el proyecto. La API 7.x requiere inicialización explícita
y difiere de ejemplos antiguos basados en `GoogleSignIn().signIn()`.

### 6.2 Servicio de identidad de Google

Crear una abstracción, por ejemplo:

```text
lib/data/services/auth/google_identity_service.dart
```

Sus responsabilidades serán:

- Inicializar `GoogleSignIn.instance` exactamente una vez.
- Abrir la selección de cuenta como respuesta a una acción del usuario.
- Obtener y devolver el ID token.
- Traducir los errores del SDK a resultados controlables por la aplicación.
- Cerrar la sesión local del SDK.

Interfaz conceptual:

```dart
abstract interface class GoogleIdentityService {
  Future<void> initialize();
  Future<String?> authenticateForIdToken();
  Future<void> signOut();
}
```

La implementación utilizará el flujo equivalente a:

```dart
final googleSignIn = GoogleSignIn.instance;

await googleSignIn.initialize(
  serverClientId: googleServerClientId,
);

final account = await googleSignIn.authenticate();
final idToken = account.authentication.idToken;
```

La pantalla no debe importar ni manipular directamente el SDK.

### 6.3 Configuración por entorno

El Web Client ID puede proporcionarse mediante una configuración por entorno,
por ejemplo:

```sh
flutter run \
  --dart-define=API_BASE_URL=https://example.com/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=example.apps.googleusercontent.com
```

La configuración debe:

- Fallar de forma comprensible si Google Sign-In está habilitado y falta el
  Client ID requerido.
- Permitir credenciales separadas para desarrollo y producción.
- No registrar tokens ni información personal.
- No considerar los Client ID como secretos, pero evitar valores de producción
  mezclados accidentalmente en compilaciones de pruebas.

En iOS se puede conservar la configuración específica de plataforma en
`Info.plist`. En web puede ser necesario preparar `index.html` por entorno o
inyectar la configuración mediante el mecanismo adoptado por el proyecto.

### 6.4 Inyección de dependencias

Registrar `GoogleIdentityService` en `AppDependencies` y entregarlo por
constructor a `LoginViewModel`.

Flujo propuesto:

```text
LoginScreen
  -> LoginViewModel.loginWithGoogle()
    -> GoogleIdentityService.authenticateForIdToken()
      -> AuthRepository.loginWithGoogleIdToken(idToken)
        -> AuthApiService.loginWithGoogle(idToken)
```

Esto conserva las llamadas externas fuera de los widgets y permite sustituir el
servicio por una implementación falsa durante las pruebas.

### 6.5 ViewModel

Se recomienda exponer a la pantalla un comando de intención:

```dart
Future<bool> loginWithGoogle()
```

En lugar de pedirle al widget que obtenga y entregue manualmente el token.

El método debe:

1. Activar el estado de carga.
2. Solicitar la autenticación al servicio de Google.
3. Distinguir una cancelación voluntaria de un error.
4. Comprobar que el ID token no sea nulo ni vacío.
5. Delegar el intercambio al repositorio existente.
6. Publicar un mensaje en español cuando falle.
7. Restablecer el estado de carga en todos los caminos de salida.

La navegación no debe ejecutarse manualmente desde el ViewModel ni la pantalla.
El repositorio ya publica el nuevo `AuthState` y `GoRouter` debe redirigir según
el rol recibido.

### 6.6 Pantalla de inicio de sesión

Incorporar en `LoginScreen`:

- Un separador visual con el texto `o`.
- Un botón `Continuar con Google`.
- El logotipo oficial de Google y las pautas de marca correspondientes.
- Indicador de progreso accesible.
- Desactivación de todas las acciones de autenticación mientras haya una
  operación activa.
- Mensajes en español para errores recuperables.

La cancelación del selector de cuentas no debe mostrarse como error. La pantalla
debe permanecer en login y permitir un nuevo intento.

Los colores del botón y sus estados deben respetar el tema claro y oscuro. Los
colores de la aplicación se obtendrán mediante el tema Material o
`context.appColors`, evitando colores fijos ajenos al sistema de temas.

En Flutter Web debe usarse el botón renderizado por el SDK cuando así lo exija
la plataforma.

## 7. Manejo de errores

Mapear los resultados del SDK a mensajes comprensibles, sin mostrar códigos,
tokens ni detalles internos:

| Situación | Comportamiento esperado |
| --- | --- |
| El usuario cancela | No mostrar error; finalizar la carga |
| No se obtiene ID token | `Google no devolvió un token válido.` |
| Falta una credencial OAuth | Mensaje genérico al usuario y diagnóstico seguro en desarrollo |
| Error de red | `No se pudo conectar con Google. Verifica tu conexión.` |
| Token rechazado por el backend | Mostrar el mensaje normalizado por la capa de autenticación |
| Cuenta sin rol permitido | Informar que la cuenta no tiene acceso a SerenoYa |
| Servicio temporalmente no disponible | Permitir reintentar sin perder los campos de login tradicional |

Nunca se debe escribir el ID token, access token, refresh token, correo u otros
datos personales en los logs.

## 8. Cierre de sesión y desvinculación

El cierre de sesión debe realizar dos acciones:

1. Eliminar la sesión y los tokens propios de SerenoYa, como ocurre actualmente.
2. Ejecutar `GoogleSignIn.instance.signOut()` para que el siguiente acceso pueda
   seleccionar otra cuenta.

No se debe revocar el consentimiento de Google durante un cierre de sesión
normal. La revocación se reservará para una futura acción explícita como
`Desvincular cuenta de Google`.

El cierre de sesión local debe completarse aunque Google Sign-Out falle. Un fallo
del proveedor externo no debe dejar activos los tokens de SerenoYa.

## 9. Pruebas requeridas

### 9.1 Pruebas unitarias del servicio

- Inicializa el SDK una sola vez.
- Devuelve el ID token obtenido.
- Maneja un token nulo o vacío.
- Distingue cancelación, error de red y error de configuración.
- Ejecuta Google Sign-Out.

### 9.2 Pruebas del ViewModel

- Activa y desactiva correctamente `isLoading`.
- Entrega el ID token al repositorio.
- No llama al backend cuando el usuario cancela.
- No llama al backend cuando falta el token.
- Expone el mensaje del repositorio cuando el intercambio falla.
- Completa el flujo cuando el backend devuelve una sesión válida.

### 9.3 Pruebas de widgets

- Muestra el botón `Continuar con Google`.
- Deshabilita acciones durante la carga.
- Muestra errores accesibles.
- No muestra un error al cancelar.
- Conserva una presentación correcta en temas claro y oscuro.

### 9.4 Pruebas manuales e integración

- Android debug con el SHA de desarrollo.
- Android release con el certificado real.
- Versión distribuida por Google Play con el SHA de Play App Signing.
- iOS en dispositivo firmado, si aplica.
- Web en origen local fijo y dominio de producción, si aplica.
- Cuenta nueva, cuenta existente y cuenta bloqueada.
- Usuario que cancela antes y después de seleccionar una cuenta.
- Backend fuera de línea después de completar Google Sign-In.
- Restauración de la sesión propia al reiniciar la aplicación.
- Cierre de sesión y selección posterior de otra cuenta.

## 10. Orden de implementación

1. Definir plataformas, package name y Bundle ID definitivos.
2. Definir la política de creación o vinculación de cuentas.
3. Crear la pantalla de consentimiento y los clientes OAuth.
4. Configurar el mismo Web Client ID en frontend y backend.
5. Verificar manualmente `/auth/google-login` con un ID token válido.
6. Agregar `google_sign_in` y crear `GoogleIdentityService`.
7. Registrar el servicio en `AppDependencies`.
8. Adaptar `LoginViewModel` para exponer `loginWithGoogle()`.
9. Incorporar el botón y sus estados en `LoginScreen`.
10. Integrar Google Sign-Out con el cierre de sesión existente.
11. Agregar pruebas unitarias y de widgets.
12. Validar cada configuración de firma y plataforma.

## 11. Criterios de aceptación

- El usuario puede abrir el selector de Google desde la pantalla de login.
- Una autenticación exitosa entrega un ID token únicamente al backend de
  SerenoYa.
- El backend devuelve y la aplicación guarda sus tokens propios.
- El usuario es redirigido al módulo permitido por su rol.
- La aplicación no utiliza el token de Google como autorización de su API.
- Una cancelación no muestra un error.
- Los fallos no exponen detalles sensibles.
- El cierre de sesión elimina la sesión local aunque Google no responda.
- Android funciona tanto con firma de desarrollo como de producción.
- Las pruebas automatizadas de autenticación continúan aprobando.
- `flutter analyze` no reporta problemas relacionados con el cambio.

## 12. Validación técnica

Después de implementar, ejecutar desde la raíz del proyecto:

```sh
flutter pub get
dart format <archivos_modificados.dart>
flutter analyze
flutter test
```

También se debe comprobar el diff y evitar incluir archivos con credenciales,
tokens o datos personales.

## 13. Referencias oficiales

- [Paquete Flutter `google_sign_in`](https://pub.dev/packages/google_sign_in)
- [Integración Android del paquete](https://pub.dev/packages/google_sign_in_android)
- [Integración iOS del paquete](https://pub.dev/packages/google_sign_in_ios)
- [Integración web del paquete](https://pub.dev/packages/google_sign_in_web)
- [Autenticación de clientes Android y certificados](https://developers.google.com/android/guides/client-auth)
- [Configuración de Google Sign-In para iOS](https://developers.google.com/identity/sign-in/ios/start-integrating)
- [Configuración de Google Identity Services para web](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid)

