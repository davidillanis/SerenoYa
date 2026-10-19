# Módulo de Serenazgo

La ruta de Serenazgo conserva el control de acceso existente. `AppDependencies`
construye `OfficerRepository` con `IncidentApiService` (API v2) y el mismo
cliente autenticado. Los view models gestionan carga, filtros, paginación,
errores y acciones; los widgets no consultan directamente la API. No se
modificó autenticación.

## Contrato conectado (API v2)

| Operación | Endpoint |
| --- | --- |
| Bolsa general y pendientes por aceptar | `GET /incident/list` |
| Casos propios, reportes y métricas | `GET /incident/list-me-sereno` |
| Detalle del sereno | `GET /incident/byId-sereno/{id}`, consulta `fields` e `id` |
| Aceptar con ubicación del sereno | `POST /incident/accept`, cuerpo `incidentId`, `acceptedLatitude`, `acceptedLongitude` |

`fields` incluye identificador, estado, coordenadas, descripción, referencia,
fechas, categoría y ciudadano (`citizen.id`, `citizen.userEntity.phone`).
La paginación usa `page,size,sortBy=id,direction=DESC` (`PageRequestDTO`).
Estados: `REQUESTED` → Pendiente, `ACCEPTED` → En curso, `ON_SITE` →
Atendiendo, `ATTENDED` → Atendido. La aceptación obtiene el GPS con
`CitizenLocationService`; sin ubicación no se llama a la API.

Inicio muestra "Mis incidentes" (`GET /incident/list-me-sereno` con
`status=REQUESTED`, con reintento y paginación) más los aceptados en sesión y
los pendientes de la bolsa general. La tarjeta recién aceptada en sesión no se
duplica aunque ya llegue por `list-me-sereno`. Reportes, métricas y filtros
usan `list-me-sereno`. No se simula el envío de
mensajes: la respuesta al ciudadano depende de la aceptación del backend.
GPS abre Google Maps con las coordenadas recibidas mediante `url_launcher`.
El mapa interno (`OfficerMapScreen`) obtiene la ubicación actual del
sereno y, solo en incidentes aceptados o en curso
(`ACCEPTED`, `ON_SITE`),
ofrece un botón «Iniciar Seguimiento»: recién al presionarlo compara rutas con
`POST /incident/incident-compare/{id}` (origen GPS del sereno, destino del
incidente), dibuja
la más rápida, permite
cambiar entre auto, moto, bicicleta y a pie, y mantiene el seguimiento del
sereno hasta el lugar. Incluye botones flotantes para ir a la ubicación
actual del sereno o al lugar del incidente. En pendientes no se consulta
la comparación.

### Seguimiento en segundo plano (Android)

- `OfficerTrackingViewModel`, provisto en la raíz de la aplicación, conserva el
  recorrido al salir del mapa. Al volver a abrirlo se reutilizan su ubicación,
  ruta y estado, sin repetir la comparación. El inicio de Serenazgo ofrece
  «Ver seguimiento activo» para volver al mapa y detenerlo.
- Solo puede haber un incidente en seguimiento. Para iniciar otro es necesario
  detener primero el actual.
- `CitizenLocationService(backgroundTracking: true)` configura el servicio de
  ubicación de `geolocator` con una notificación persistente y un wake lock.
  Continúa al minimizar o bloquear la pantalla. Se solicita alta precisión,
  actualizaciones cada 5 segundos y un desplazamiento mínimo de 10 metros;
  Android puede ajustar la frecuencia efectiva. Los mapas sin recorrido hacen
  una lectura puntual y no mantienen este servicio abierto.
- Se registra la llegada con `POST /incident/onSite/{id}` dentro de un radio de
  50 metros, después de iniciar correctamente el recorrido. El GPS y la
  notificación se detienen cuando el servidor confirma la llegada, al pulsar
  «Detener seguimiento» o al cerrar/cambiar de sesión. Si falla la llegada, se
  reintenta con el GPS y cada 15 segundos mientras se permanezca en el radio.
- El manifiesto incluye `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` y
  `WAKE_LOCK`. El servicio de tipo `location` lo declara el plugin. Se inicia
  desde el botón con la app visible y el permiso de ubicación concedido; no
  requiere acceso permanente mediante `ACCESS_BACKGROUND_LOCATION`.
- Este alcance conserva el proceso de la aplicación: no restaura recorridos
  después de forzar la detención, terminar el proceso o reiniciar el teléfono.
  iOS y web no tienen habilitada ejecución en segundo plano.

Para verificar en un Android real: iniciar con el GPS habilitado, comprobar la
notificación, salir del mapa, minimizar/bloquear el dispositivo y acercarse al
incidente. Confirmar la llegada en el servidor y que desaparezca la notificación.
Repetir con detención manual, cierre de sesión y un fallo de conexión al llegar.

## Límites de la API v2 revisada

- La llegada usa `POST /incident/onSite/{id}`. La finalización como atendido no
  tiene una acción conectada en este flujo.
- `IncidentEntity` no tiene prioridad. El modelo Flutter admite alta, media y
  baja (`HIGH`, `MEDIUM`, `LOW`), pero presenta «Prioridad sin informar» cuando
  falta. No solicita un campo inexistente ni deduce prioridad por categoría.
- El ciudadano disponible incluye identificador y teléfono; no hay nombre en
  `UserEntity`. No se muestran nombres inventados.
- El detalle devuelve la primera evidencia, no una colección. Para una galería
  completa se requiere ampliar ese contrato.
- No se recibió el adjunto mencionado en la solicitud; se reutilizó el tema
  existente y se revisaron capturas en claro y oscuro, a 320 y 1000 px.

## Verificación

`flutter test test/officer_module_test.dart` cubre contratos v2, mapeos,
métricas, paginación, respuestas obsoletas, disposición, aceptación con GPS y
navegación adaptable. Las capturas opcionales se generan en `/tmp` pasando
`--dart-define=OFFICER_SCREENSHOTS=true` y
`--dart-define=OFFICER_FONT_DIR=<Flutter SDK>/bin/cache/artifacts/material_fonts`.
La validación usa respuestas simuladas; no se realizaron operaciones en producción.
