# ⚽ FutCup 2026 – Plataforma de administración del sistema

Platadorma web que sirve para la administración del sistemapor parte solo de usuarios de tipo "admin".

Es un producto separado de la app móvil de la Futcup, pero que accede al mismo backend.
En esta plataforma solo se puede acceder si ya tienes una cuenta. No hay formulario de registro.
La web será responsive, es decir, se adaptará al ancho del dispositivo desde el cual se accede a ella.

---

# Stack tecnológico
Para programar este panel de administradión se utilizará React.

---

# Funcionalidades de la plataforma

## 1. Log-In
- Formulario de entrada con los campos:
    - Username
    - Password
- Botón de “iniciar sesión”. 
    - Solo permitirá entrar a usuarios que tengan el rol "admin".
    - Si no hay errores, lleva a la página principal.

---

## 2. Header
- El panel tendrá un header con el título de la página en el centro.
- En la esquina derecha del header, se mostrará un icono predeterminado de usuario, y el username y rol del usuario
- El header será visible desde cualquier punto de la aplicación.

---

## 3. Panel principal
- En la parte superior del panel se incluirá una imagen del logo de la FutCup.
- Debajo de la imagen habrá una serie de cards, una para cada tabla de la base de datos:
    - Cada card contendrá un icono representativo de la tabla.
    - El nombre de la tabla
    - Se hará un card de las siguientes tablas:
        - Users
        - Tournaments
        - Teams
        - Players
        - Matches
        - Audit_logs (Card especial, su panel solo incluye un listado con los registros del log de auditoría)
    - Al hacer click en una card, se redirigirá a un panel específico de esa tabla, el cual contendrá un CRUD de esa tabla.
        - Primero, habrá un botón de Crear (elemento). Este abrirá un formulario para crear un elemento de esa tabla.
            - El formulario contendrá todos los atributos de la tabla salvo el id, created_at, updated_at.
            - Los campos booleanos serán un desplegable (Sí / No)
            - Los campos que sean foreign keys de otras tablas, contendrán un desplegable con el nombre del elemento referenciado (ejemplo: En el desplegable no se muestra id_equipo 1, sino el nombre del equipo que tiene id 1).
            - Validaciones necesarias para todos los campos.
            - Botón de "Crear (nombre de la tabla)"
        - Debajo de ese botón, se incluirá una lista con la información estructurada de todos los registros de la tabla.
            - Cada registro incluirá un botón de "Editar datos" y otro de "Eliminar registro".
                - El botón de eliminar registro requerirá una doble confirmación para evitar eliminaciones por error.
                - El botón de editar datos abrirá un formulario como el descrito para crear un elemento, pero por defecto se escribirán sobre los labels el contenido actual de los campos correspondientes.
            - Al hacer click sobre un label de un registro se accede a una ventana en la cual se visualizará la información de ese registro.
            - Se incluirá una paginación en las listas de los registros
        - Se puede incluir encima del listado un buscador para poder encontrar un elemento concreto.
    - Las tablas restantes son secundarias y se incluirán pero dentro de otros paneles de otras tablas principales:
        - Player_teams se mostrará dentro de un "Team". Ahí se podrá añadir / quitar jugadores, o editar info como el número (dorsal).
        - User_tournaments se mostrará desde "User". Ahí se podrán añadir / quitar torneos que siga el usuario.
        - Events: Se mostrará desde un Match. Habrá un borón de "Ver eventos" y otro de "Crear evento"
        - Lineups: Se mostrará desde un Match. Habrá un botón de gestionar alineaciones para cada equipo del partido (local y visitante)