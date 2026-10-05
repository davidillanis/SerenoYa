# Configuración Google Sign-In — SerenoYa Android

## 1. Obtener SHA-1 Android

```bash
cd /home/abel/Documentos/Flutter/sereno_ya/android
./gradlew signingReport
```

Buscar:

```text
Variant: debug
SHA1: TU_SHA1_DEBUG
```

---

## 2. Proyecto Google Cloud

```text
Proyecto: serenoya-e3583
```

---

## 3. Cliente OAuth Android

```text
Tipo: Android
Nombre: SerenoYa Android Debug
Nombre del paquete: com.example.sereno_ya
SHA-1: TU_SHA1_DEBUG
```

---

## 4. Cliente OAuth Web

```text
Tipo: Aplicación web
Nombre: SerenoYa Backend
Orígenes autorizados: vacío
URI de redirección: vacío
```

Copiar el ID generado:

```text
TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

> Este es el ID que se usa en Flutter y en el backend.

---

## 5. Backend

Endpoint:

```text
POST /auth/google-login
```

Body:

```json
{
  "idToken": "TOKEN_DE_GOOGLE"
}
```

Configurar como audiencia válida:

```text
TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

Respuesta esperada:

```json
{
  "isSuccess": true,
  "message": "Autenticación completada",
  "data": {
    "id": "ID_INTERNO",
    "name": "NOMBRE",
    "lastName": "APELLIDO",
    "accessToken": "JWT_SERENOYA",
    "refreshToken": "REFRESH_TOKEN_SERENOYA"
  },
  "errors": []
}
```

El `accessToken` debe incluir los roles que utiliza SerenoYa.

---

## 6. Ejecutar Flutter

```bash
cd /home/abel/Documentos/Flutter/sereno_ya

flutter pub get

flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com \
  --dart-define=API_BASE_URL=https://TU_DOMINIO/api/v1
```

---

## Configuración final

```text
ANDROID OAUTH
Package:
com.example.sereno_ya

SHA-1:
TU_SHA1_DEBUG


FLUTTER
GOOGLE_SERVER_CLIENT_ID=
TU_CLIENT_ID_WEB.apps.googleusercontent.com


BACKEND
POST /auth/google-login

aud =
TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

## Importante

**No usar el Client ID Android en `GOOGLE_SERVER_CLIENT_ID`.**

Usar siempre:

```text
Client ID Web
```