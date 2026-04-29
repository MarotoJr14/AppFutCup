# FutCup 2026 (Android nativo) — `apps/app-2026/`

Esta carpeta contiene una **app Android nativa** (Kotlin + Views + Fragments) enfocada en mostrar información del torneo **FutCup 2026**.

Funcionalidad principal:
- Pantalla de inicio (resumen)
- Calendario/partidos
- Goleadores
- Cuadro/bracket del torneo
- Carga de datos asíncrona con pantalla de “cargando” y reintento

La app utiliza un **Navigation Drawer** y navega entre fragments.

## Requisitos

- Android Studio (recomendado)
- SDK Android configurado
- JDK compatible con el Android Gradle Plugin del proyecto

## Cómo ejecutar

### Opción A: Android Studio

1) Abre `apps/app-2026` como proyecto.
2) Sincroniza Gradle.
3) Ejecuta el módulo `app` en un emulador o dispositivo.

### Opción B: línea de comandos (Windows)

Desde `apps/app-2026/`:

```bash
.\gradlew.bat assembleDebug
```

## Fuente de datos (JSON) y modo offline

La app obtiene datos desde un JSON con **fallback local**:

1) Intenta descargar un JSON remoto (útil para actualizar resultados sin recompilar).
2) Si falla (sin internet/timeout), carga el JSON local incluido en la app.

Implementación:
- Remoto: `apps/app-2026/app/src/main/java/com/futcup/app/util/DataReader.kt` (`JSON_URL`)
- Local: `apps/app-2026/app/src/main/res/raw/torneo.json`

Si necesitas usar tu propio JSON:
- Cambia `JSON_URL` a la URL “raw” (por ejemplo en GitHub) del archivo JSON.

Notas:
- Se aplican timeouts a la conexión.
- La UI muestra error con botón “reintentar” si no se pudo cargar.

## Estructura de carpetas (resumen)

- `apps/app-2026/app/src/main/java/com/futcup/app/MainActivity.kt`
  - Setea toolbar + drawer
  - Lanza la carga asíncrona de datos
  - Renderiza fragments y gestiona navegación

- `apps/app-2026/app/src/main/java/com/futcup/app/util/DataReader.kt`
  - Descarga/carga el JSON y lo parsea a modelos

- `apps/app-2026/app/src/main/java/com/futcup/app/model/`
  - Modelos de datos usados por la UI (torneo, equipos, partidos, goleadores…)

- `apps/app-2026/app/src/main/java/com/futcup/app/ui/*`
  - Fragments de cada sección:
    - `home/`
    - `calendar/`
    - `scorers/`
    - `bracket/`

- `apps/app-2026/app/src/main/res/`
  - `layout/`: vistas (activity + fragments + items)
  - `menu/`: menú del drawer y toolbar
  - `drawable/`, `mipmap*/`: imágenes/recursos
  - `raw/torneo.json`: datos offline

## Formato del JSON (contrato)

El JSON local/remoto (`torneo.json`) contiene, a alto nivel:
- `torneo`: metadatos (nombre, campo, fechas)
- `equipos`: listado con `id`, `nombre`, `ganados`
- `partidos`: listado con ronda, equipos, goles, hora, campo…
- `goleadores`: listado con nombre, equipo, goles

Si cambias el contrato del JSON, debes ajustar el parseo en `DataReader.parsearJson`.

## Troubleshooting

- **Sin internet**: la app debería funcionar con el JSON local; si falla, revisa que `raw/torneo.json` esté presente.
- **URL remota no accesible**: confirma que `JSON_URL` apunta a la URL “raw” correcta.
- **Recursos/imagenes no se ven**: revisa `res/drawable` y que las referencias en layouts existan.
