# FutCup App (Flutter) — `apps/app/`

Esta carpeta contiene la **app móvil Flutter** del proyecto FutCup. Es un cliente que consume la API del backend (`backend/`) para:

- Autenticarse (JWT)
- Consultar torneos, equipos, jugadores, partidos, alineaciones, eventos y goleadores
- Gestionar acciones según rol (la app está pensada para usuarios no-admin)
- Mantener sesión y tema (modo oscuro/claro) en almacenamiento seguro

## Stack y librerías clave

- Flutter + Dart (SDK `>=3.2.0 <4.0.0`)
- **Riverpod**: estado y controladores (`apps/app/lib/providers/`)
- **Dio**: cliente HTTP + interceptores (`apps/app/lib/core/network/`)
- **flutter_secure_storage**: token/usuario/estado de sesión (`apps/app/lib/core/storage/`)
- **go_router**: navegación declarativa (`apps/app/lib/router.dart`)

## Requisitos

- Flutter instalado
- Android Studio (Android) / Xcode (iOS)
- Backend levantado (ver `backend/README.md`)

## Configuración de API (base URL)

La URL base se define en:
- `apps/app/lib/core/constants/app_strings.dart` → `baseUrl`

Valores típicos:
- Android Emulator: `http://10.0.2.2:8000/api/v1` (por defecto)
- iOS Simulator: `http://localhost:8000/api/v1`
- Dispositivo físico: `http://<IP-de-tu-PC>:8000/api/v1`

Importante:
- El backend usa JWT Bearer. Dio añade el header automáticamente si hay token guardado.
- Si cambias el backend/puerto, actualiza `baseUrl`.

## Ejecución en desarrollo

Desde `apps/app/`:

```bash
flutter pub get
flutter run
```

Tests:

```bash
flutter test
```

Si necesitas regenerar código (build_runner, si aplica a tu flujo):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Flujo de autenticación y sesión

Endpoints consumidos (relativos a `baseUrl`):
- Login: `POST /auth/login`
- Perfil: `GET /users/me`
- Registro: `POST /auth/register`
- Actualización de perfil: `PATCH /users/me`

Token:
- Se guarda en `flutter_secure_storage` con clave `auth_token`.
- Se inyecta en cada request como `Authorization: Bearer <token>` (ver `apps/app/lib/core/network/dio_client.dart`).

Control de sesión:
- La app cierra sesión al pasar a segundo plano/inactivo (ver `apps/app/lib/widgets/session_lifecycle.dart` + `apps/app/lib/providers/auth_provider.dart`).
- También existe manejo global de 401: si el backend responde 401, se limpia el almacenamiento y se fuerza logout (interceptor en `dio_client.dart`).

Restricción de rol:
- Si el usuario autenticado es `admin`, la app cierra sesión y bloquea el acceso (ver `apps/app/lib/providers/auth_provider.dart`).
  - El rol `admin` está pensado para el **panel web** `docs/panel-admin/`.

## Navegación (rutas principales)

La navegación está definida en `apps/app/lib/router.dart`. Rutas relevantes:
- `/login`, `/register`
- `/home`
- `/calendar`
- `/bracket`
- `/teams` (y detalle/edición)
- `/match/:id` (detalle/edición + alta de eventos/alineación)
- `/scorers`
- `/follow-tournaments`
- `/profile`

El router aplica redirecciones según el estado de autenticación (no permite entrar a rutas protegidas si no hay sesión).

## Estructura de carpetas (cómo “funciona” el módulo)

- `apps/app/lib/core/`
  - `constants/`: strings, colores, etc.
  - `network/`: Dio singleton, timeouts, interceptores y errores
  - `storage/`: persistencia segura (token/usuario/tema)
  - `theme/` + `ui/`: estilos, mensajes globales

- `apps/app/lib/models/`
  - Modelos de dominio (User, Tournament, Team, Player, Match, Event, Lineup, Stats…)

- `apps/app/lib/repositories/`
  - Capa de acceso a API (por recurso). Normalmente:
    - Llama a endpoints
    - Parsea modelos
    - Lanza `ApiException` en errores HTTP

- `apps/app/lib/providers/`
  - StateNotifiers / Providers Riverpod que orquestan casos de uso y alimentan UI.

- `apps/app/lib/screens/`
  - Pantallas por feature (auth, home, matches, teams, players, events, lineups, profile…)

- `apps/app/lib/widgets/`
  - Widgets reutilizables (incluye el observer de lifecycle de sesión)

## Assets

- Declarados en `apps/app/pubspec.yaml`
- Ubicación: `apps/app/assets/`

## Desarrollo: añadir una pantalla o recurso nuevo

Patrón recomendado:
1) Crear/actualizar modelo en `apps/app/lib/models/`
2) Añadir repositorio en `apps/app/lib/repositories/` (métodos contra la API)
3) Añadir provider en `apps/app/lib/providers/` (estado/carga/errores)
4) Crear pantalla en `apps/app/lib/screens/` (UI)
5) Registrar ruta en `apps/app/lib/router.dart` (si aplica)

## Troubleshooting

- **No conecta con el backend en Android Emulator**: usa `10.0.2.2` (no `localhost`) y revisa `baseUrl`.
- **401 / token expirado**: la app limpia sesión automáticamente; vuelve a iniciar sesión.
- **CORS**: no aplica a Flutter nativo, pero sí al panel web (ver `docs/panel-admin/`).
- **Acentos/encoding**: si ves caracteres raros, revisa configuración UTF-8 del editor/terminal.
