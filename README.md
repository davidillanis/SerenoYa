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
Para compilar un APK con las mismas variables:

```powershell
flutter build apk --dart-define-from-file=.env
```

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

## Verificación del proyecto

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

La planificación del módulo está en
[`docs/authentication_implementation_plan.md`](docs/authentication_implementation_plan.md).
