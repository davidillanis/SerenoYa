# Módulo de Serenazgo

La ruta de Serenazgo conserva el control de acceso existente. `AppDependencies`
construye `OfficerRepository` con el mismo cliente autenticado de incidentes.
Los view models gestionan carga, filtros, paginación, errores y acciones; los
widgets no consultan directamente la API. No se modificó autenticación.

## Contrato conectado

| Operación | Endpoint |
| --- | --- |
| Listado y totales por estado | `GET /incidents/list` |
| Detalle y primera evidencia | `GET /incidents/byId/{id}` |
| Aceptar y comunicar ETA | `PUT /incidents/{id}/accept`, cuerpo `etaMinutes` |
| Registrar llegada o atención | `PUT /incidents/update-status`, parámetros `incidentId`, `status` |

Estados: `REQUESTED` → Pendiente, `ACCEPTED` → En curso, `ON_SITE` → Atendiendo,
`ATTENDED` → Atendido. Cancelados, expirados y estados desconocidos se muestran
sin acciones operativas. Se valida ETA entre 1 y 180 minutos. No se simula el
envío de mensajes: la respuesta al ciudadano depende de la aceptación del backend.

Las métricas utilizan `totalElements` del servidor, no la cantidad de tarjetas
cargadas. Los reportes son generales; no representan la productividad individual.
GPS abre Google Maps con las coordenadas recibidas mediante `url_launcher`.

## Límites del backend local revisado

- No expone listado de asignaciones del sereno. Inicio identifica únicamente
  incidentes aceptados durante la sesión actual y lo indica en pantalla. Al
  actualizar, consulta sus detalles; no atribuye incidentes ajenos al usuario.
  Recuperar asignaciones tras reiniciar requiere un endpoint autorizado por sereno.
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

`flutter test test/officer_module_test.dart` cubre contratos, mapeos, métricas,
paginación, respuestas obsoletas, disposición, transiciones y navegación adaptable.
Las capturas opcionales se generan en `/tmp` pasando
`--dart-define=OFFICER_SCREENSHOTS=true` y
`--dart-define=OFFICER_FONT_DIR=<Flutter SDK>/bin/cache/artifacts/material_fonts`.
La validación usa respuestas simuladas; no se realizaron operaciones en producción.
