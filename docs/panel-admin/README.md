# Panel Admin (React + Vite) — `docs/panel-admin/`

Esta carpeta contiene el **panel de administración web** del proyecto FutCup. Es una SPA (Single Page Application) que consume la API del backend (`backend/`) para administrar los datos del sistema.

Funcionalidad principal:
- Login de administradores (JWT)
- Panel con accesos a “tablas” (usuarios, torneos, equipos, jugadores, partidos, auditoría…)
- Operaciones CRUD (crear/editar/eliminar) según permisos del backend
- Importación/exportación de datos desde la UI (según tabla)
- Gestión de sesión con logout automático ante 401 y sincronización entre pestañas

## Stack

- React + React Router
- Vite
- Tailwind CSS
- Axios (con interceptores y Bearer token)

## Requisitos

- Node.js (recomendado: 18+)
- Backend levantado (ver `backend/README.md`)

## Configuración de la API (base URL)

El cliente Axios resuelve la URL base así (ver `docs/panel-admin/src/api/axios.js`):
1) `VITE_API_BASE_URL` (si existe)
2) En desarrollo: `http://localhost:8000/api/v1`
3) En producción: `https://<tu-dominio>/api/v1` (same-origin)

Ejemplo:
- Copia `docs/panel-admin/.env.example` a `docs/panel-admin/.env` y ajusta:

```bash
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

## Ejecutar en desarrollo

Desde `docs/panel-admin/`:

```bash
npm install
npm run dev
```

Servidor dev: `http://localhost:3000`

## Build / Preview / Deploy

Build:

```bash
npm run build
```

Preview:

```bash
npm run preview
```

Salida:
- `docs/panel-admin/dist`

Detalle importante:
- `vite.config.js` configura `base: './'` en build para que los assets funcionen al desplegar el build bajo subrutas (por ejemplo, servido desde una carpeta estática).

## Autenticación y sesión (cómo funciona)

Login:
- `POST /auth/login` → devuelve `access_token`
- Con token, se consulta `GET /users/me`
- Si `me.role !== 'admin'`, se deniega el acceso (ver `docs/panel-admin/src/context/AuthContext.jsx`)

Token:
- Se guarda en `localStorage` y se añade como `Authorization: Bearer <token>` en cada request (interceptor Axios).

Gestión de sesión:
- Si una llamada devuelve 401 (no-login), se limpia sesión y se redirige a `/login`.
- Hay un “registry” de pestañas para sincronizar logout y evitar sesiones huérfanas entre tabs (ver `docs/panel-admin/src/session/*`).

## Pantallas y “tablas”

Rutas principales (ver `docs/panel-admin/src/App.jsx`):
- `/login`
- `/` (dashboard)
- `/table/:tableKey` (vista CRUD por tabla)

Tablas disponibles (según UI actual, ver `DashboardPage.jsx` y `TablePage.jsx`):
- `users`
- `tournaments`
- `teams`
- `players`
- `matches`
- `audit-logs` (auditoría)

Cada tabla está implementada en `docs/panel-admin/src/pages/tables/*Table.jsx` y normalmente usa:
- `useCrud(endpoint)` para listar/crear/editar/eliminar
- Componentes genéricos (tabla, formulario, modales)
- Acciones de import/export (según tabla)

## Estructura de carpetas (resumen)

- `docs/panel-admin/src/api/`
  - Cliente Axios y configuración de base URL

- `docs/panel-admin/src/context/`
  - Contexto de autenticación (login/logout, usuario, sesión)

- `docs/panel-admin/src/pages/`
  - Páginas principales (Login, Dashboard, Table)
  - `pages/tables/`: una tabla por recurso

- `docs/panel-admin/src/components/`
  - Layout, tablas, modales y UI reutilizable

- `docs/panel-admin/src/hooks/`
  - Hooks comunes (CRUD, toasts, import/export, etc.)

- `docs/panel-admin/src/session/`
  - Gestión de claves de sesión, timeouts, sincronización entre pestañas

## Preparar un admin de prueba

El panel requiere un usuario con rol `admin`.

Opciones:
- Usa el script: `backend/scripts/seed_users.py`
- O crea un admin vía API (si el backend lo permite según tu configuración)

## Troubleshooting

- **CORS**: si sirves panel y backend en orígenes distintos, asegúrate de que el backend permita el origen (en dev actualmente permite `*`).
- **401 constantes**: revisa que `VITE_API_BASE_URL` apunte a `/api/v1` y que el backend esté levantado.
- **Build en subruta**: el `base: './'` está pensado para static hosting; si lo sirves desde raíz, debería funcionar igualmente.
- **Acentos/encoding**: si ves caracteres raros en textos, revisa UTF-8 en editor/terminal.
