# SerenoYa

Aplicación Flutter para reportar incidentes ciudadanos y coordinar su atención
por el Serenazgo de San Jerónimo.

## Ejecución

```powershell
flutter pub get
flutter run --dart-define-from-file=.env
```

Configura las variables en `.env`, en la raíz del proyecto. Para una nueva copia
del repositorio, copia `.env.example` a `.env` y sustituye sus valores:

```text
API_BASE_URL=https://example.com/api/v1
GOOGLE_SERVER_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

`.env` está excluido de Git. VS Code carga ese archivo al iniciar las
configuraciones del proyecto. Reinicia la ejecución después de editarlo.

## Generar APK y AAB

Ejecuta los comandos desde la raíz del proyecto. Ambos formatos incorporan
`API_BASE_URL` y `GOOGLE_SERVER_CLIENT_ID` desde `.env`; revisa sus valores antes
de compilar. Si los cambias, genera nuevamente el archivo.

### APK: instalación directa en Android

```powershell
flutter build apk --release --dart-define-from-file=.env
```

Archivo generado: `build/app/outputs/flutter-apk/app-release.apk`.

### AAB: publicación en Google Play

```powershell
flutter build appbundle --release --dart-define-from-file=.env
```

Archivo generado: `build/app/outputs/bundle/release/app-release.aab`.

El AAB se sube a Google Play Console; para instalar directamente en un teléfono,
utiliza el APK.

### Antes de publicar

Configura la firma de producción en `android/app/build.gradle.kts`: la
configuración revisada utiliza la firma debug también para `release`. Registra
en Google OAuth la SHA-1 del certificado que firma la aplicación distribuida.
Si utilizas Play App Signing, registra la huella del certificado de firma de
aplicaciones de Google Play, no solamente la de la clave de subida.

## Acceso con Google

El login nativo incluye «Continuar con Google». El token de identidad se envía a
`POST /auth/google-login`; los tokens de sesión y roles proceden del backend.
Cancelar el selector no inicia sesión ni muestra un error. Cerrar sesión también
cierra la sesión del SDK de Google.

Para Android, registra el paquete `com.example.sereno_ya` y las huellas SHA de
las firmas utilizadas en Google Cloud. Crea además un cliente OAuth de tipo web
y usa su Client ID (público, no el secreto):

```sh
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

El backend debe aceptar ese mismo Client ID como audiencia y validar el token
de Google. El `google-services.json` actual no contiene clientes OAuth; tener
Firebase para notificaciones no configura automáticamente este acceso.

En iOS/macOS se requiere además el cliente OAuth de la aplicación y su esquema
URL invertido en la configuración nativa (`GIDClientID` y `CFBundleURLTypes`).
Esos valores deben obtenerse del proyecto Google; no se incluyen valores ficticios.
Web requiere el botón oficial renderizado por el SDK y no se habilita en este
flujo nativo. Windows y Linux tampoco muestran el botón.

Referencias: [Android](https://pub.dev/packages/google_sign_in_android),
[iOS/macOS](https://pub.dev/packages/google_sign_in_ios) y
[SDK](https://pub.dev/packages/google_sign_in).

## Google Maps dentro de Serenazgo

En Inicio y Reportes, «Ver en el mapa» abre Google Maps dentro de la app,
centrado en las coordenadas del incidente. También está disponible desde su
detalle. Muestra la ubicación reportada; no calcula rutas ni obtiene la
ubicación actual del sereno.

Agrega a tu `.env` local:

```text
GOOGLE_MAPS_API_KEY=TU_CLAVE_DE_GOOGLE_MAPS
```

Ejecuta con `flutter run --dart-define-from-file=.env` o compila con esa misma
opción. Reinicia completamente la aplicación tras cambiar la clave. Android,
iOS y web reciben la clave de esa variable; no hay que escribirla en el código.
Sin clave, la pantalla informa que el mapa no está disponible.

En Google Cloud habilita facturación y la API de la plataforma: **Maps SDK for
Android**, **Maps SDK for iOS** o **Maps JavaScript API**. Usa una clave distinta
para cada plataforma y restringe su uso al paquete y SHA-1 de Android, al bundle
ID de iOS o a los dominios web autorizados. Elige la clave correspondiente en el
archivo de variables utilizado para cada compilación. Estas claves de cliente
se incluyen en el artefacto compilado; sus restricciones son necesarias.

La integración requiere Android API 24 o superior e iOS 15 o superior. iOS usa
`google_maps_flutter_ios_sdk9`, compatible con Swift Package Manager. En Linux,
Windows y macOS nativos se muestra un aviso de plataforma no compatible.

Referencia: [configuración oficial de Google Maps para Flutter](https://developers.google.com/maps/flutter-package/config).

## Verificación del proyecto

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

La planificación del módulo está en
[`docs/authentication_implementation_plan.md`](docs/authentication_implementation_plan.md).
