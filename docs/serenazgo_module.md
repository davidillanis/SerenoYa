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
El mapa interno (`OfficerMapScreen`) muestra siempre la ubicación actual del
sereno con seguimiento en vivo y, solo en incidentes aceptados o en curso
(`ACCEPTED`, `ON_SITE`),
compara rutas con `POST /route/compare`: dibuja la más rápida y permite
cambiar entre auto, moto, bicicleta y a pie. En pendientes no se consulta
la comparación.

## Límites de la API v2 revisada

- No expone avance (llegada/atendido). Solo los pendientes tienen acción;
  otros estados no muestran botones hasta contar con el endpoint
  correspondiente.
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
