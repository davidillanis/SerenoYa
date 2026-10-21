# Publicación Android de SerenoYa

Esta guía documenta la configuración y los comandos necesarios para compilar,
probar y publicar SerenoYa en Google Play.

## Identidad de la aplicación

- Nombre visible: `SerenoYa`.
- Application ID: `com.oppsissora.serenoya`.
- Proyecto Firebase: `serenoya-e3583`.
- Archivo de Firebase: `android/app/google-services.json`.
- Clave de carga local: `serenoya-upload.jks`.

El nombre visible puede cambiar. El Application ID no debe cambiar después de
crear la aplicación en Play Console.

## 1. Preparar Windows y Flutter

Flutter necesita soporte para enlaces simbólicos en Windows. Abre la
configuración y activa **Modo de desarrollador**:

```powershell
start ms-settings:developers
```

Cierra y vuelve a abrir PowerShell después de activarlo. Desde la raíz del
proyecto, comprueba el entorno y restaura las dependencias:

```powershell
flutter doctor -v
flutter clean
flutter pub get
```

Los avisos sobre versiones nuevas de paquetes no impiden compilar. Las
dependencias no deben actualizarse como parte de una publicación sin probar
antes sus cambios.

## 2. Crear la clave de carga

Este paso se ejecuta una sola vez. Crea la clave fuera del repositorio:

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\AndroidKeys" -Force

keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\AndroidKeys\serenoya-upload.jks" `
  -storetype JKS `
  -alias serenoya-upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 36500
```

Guarda el archivo, el alias y las contraseñas en ubicaciones seguras. No los
subas a Git. Una validez de `10000` días también es suficiente; no recrees la
clave después de registrarla en Google Play solamente para cambiar su vigencia.

Obtén sus certificados:

```powershell
keytool -list -v `
  -keystore "$env:USERPROFILE\AndroidKeys\serenoya-upload.jks" `
  -alias serenoya-upload
```

Registra las huellas SHA-1 y SHA-256 en la aplicación Android
`com.oppsissora.serenoya` de Firebase.

## 3. Referenciar la clave desde Gradle

Crea `android/key.properties` con valores locales:

```properties
storePassword=CONTRASENA_DEL_ALMACEN
keyPassword=CONTRASENA_DE_LA_CLAVE
keyAlias=serenoya-upload
storeFile=C:\\Users\\USUARIO\\AndroidKeys\\serenoya-upload.jks
```

No uses comillas. Si una contraseña contiene una barra invertida, escápala
como `\\`. El archivo está excluido por `android/.gitignore`.

Comprueba que Git lo ignore:

```powershell
git check-ignore -v android/key.properties
```

`android/app/build.gradle.kts` carga estas propiedades para la variante
`release` y detiene la compilación si la configuración está incompleta.

## 4. Configurar Firebase y Google OAuth

En Firebase debe existir una aplicación Android con:

```text
com.oppsissora.serenoya
```

Registra tanto la SHA de depuración como la SHA de la clave de carga. La SHA de
depuración de una máquina puede obtenerse con:

```powershell
keytool -list -v `
  -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android `
  -keypass android
```

Descarga `google-services.json` y colócalo en:

```text
android/app/google-services.json
```

Crea además un cliente OAuth de tipo Web. El mismo Client ID Web debe usarse
en Flutter y como audiencia válida en el backend. No uses el Client ID Android
ni coloques un Client Secret en la aplicación.

## 5. Configuración de compilación

Crea `.env` en la raíz del proyecto:

```properties
API_BASE_URL=https://DOMINIO_REAL/api/v1
GOOGLE_SERVER_CLIENT_ID=CLIENT_ID_WEB.apps.googleusercontent.com
GOOGLE_MAPS_API_KEY=CLAVE_ANDROID_RESTRINGIDA
```

`.env` no se versiona. La clave de Maps debe restringirse al paquete
`com.oppsissora.serenoya` y a las SHA autorizadas. Para una versión distribuida
por Google Play se debe usar una API pública HTTPS, nunca `localhost`.

El backend debe validar la firma, el emisor, el vencimiento y la audiencia del
ID token. La audiencia debe ser exactamente `GOOGLE_SERVER_CLIENT_ID`.

## 6. Probar con un teléfono conectado por USB

Comprueba la conexión:

```powershell
adb devices
```

Para acceder desde el teléfono a un backend local en el puerto 8080:

```powershell
adb reverse tcp:8080 tcp:8080

flutter run `
  --dart-define-from-file=.env `
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

`localhost` representa al teléfono si no se ejecuta `adb reverse`. Los valores
de `--dart-define` se incorporan durante la compilación; un hot reload no basta
para cambiarlos.

## 7. Ejecutar las comprobaciones

Desde la raíz del proyecto:

```powershell
flutter analyze
flutter test
```

Todo fallo debe revisarse e informarse. No se deben modificar pruebas para
forzar un resultado satisfactorio.

## 8. Generar y probar el APK release

Genera un APK universal firmado:

```powershell
flutter build apk --release --dart-define-from-file=.env
```

Resultado:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Instálalo en el teléfono conectado:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Play Protect puede advertir que no conoce al desarrollador cuando el APK se
instala fuera de Google Play. Esto no implica por sí solo una firma inválida.
No desactives Play Protect globalmente; para una prueba representativa usa una
versión de prueba distribuida por Play Console.

## 9. Generar y verificar el Android App Bundle

Genera el bundle firmado:

```powershell
flutter build appbundle --release --dart-define-from-file=.env
```

Resultado:

```text
build\app\outputs\bundle\release\app-release.aab
```

Comprueba la firma y calcula un hash para conservarlo con el registro de la
versión:

```powershell
jarsigner -verify build\app\outputs\bundle\release\app-release.aab

Get-FileHash `
  build\app\outputs\bundle\release\app-release.aab `
  -Algorithm SHA256
```

`jarsigner` debe mostrar `jar verified`. Es normal que una clave de carga local
tenga un certificado autofirmado y no incluya timestamp.

## 10. Subir a Google Play

1. Abre SerenoYa en Play Console.
2. Entra en **Probar y lanzar > Prueba interna**.
3. Crea una versión y activa o confirma **Play App Signing**.
4. Sube `app-release.aab`.
5. Revisa los avisos, guarda la versión y publícala para los evaluadores.

Después de la primera carga, abre **Integridad de la app > Firma de
aplicaciones**. Copia las SHA-1 y SHA-256 del **certificado de la clave de firma
de aplicaciones** y agrégalas en Firebase. No las confundas con las huellas de
la clave de carga. Descarga otra vez `google-services.json` para mantener el
repositorio sincronizado.

Para una carga posterior, incrementa el número después de `+` en
`pubspec.yaml`. Google Play no acepta reutilizar un `versionCode` ya cargado.

## 11. Guardar los cambios en Git

Revisa el contenido antes de crear el commit:

```powershell
git status --short
git diff --check
git diff
```

Nunca deben aparecer `.env`, `android/key.properties`, archivos `.jks` ni sus
contraseñas. Después de revisar:

```powershell
git add README.md `
  docs/android_play_store_release.md `
  android/app/src/main/AndroidManifest.xml
git status --short
git commit -m "chore(android): configurar publicación en Google Play"
git push
```

No agregues `build/`: los APK y AAB son artefactos, no código fuente.

## Diagnóstico rápido

- **Google Sign-In no está configurado:** faltó
  `--dart-define-from-file=.env` o `GOOGLE_SERVER_CLIENT_ID` está vacío.
- **Token de Google inválido o expirado:** el backend suele estar validando una
  audiencia distinta, un Client ID Android o un tipo de token incorrecto.
- **Play Protect bloquea el APK:** la instalación lateral usa una firma nueva y
  Play Protect todavía no reconoce al desarrollador.
- **El teléfono no accede al backend local:** ejecuta `adb reverse` y confirma
  que el backend escuche en el puerto indicado.
- **La app descargada desde Play no inicia sesión con Google:** registra en
  Firebase la SHA de Play App Signing, no solamente las SHA debug y de carga.
