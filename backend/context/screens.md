# ⚽ FutCup 2026 – Aplicación de Gestión del Torneo

Aplicación para la gestión de horarios, resultados y goleadores del torneo **FutCup 2026**, organizado por el centro educativo Pro2FP, y celebrado el 13 de marzo de 2026 en el polideportivo Entremontes de Las Rozas de Madrid.

---

# 🚀 Pantallas de la Aplicación

---

## 1️⃣ Pantalla de Log-in
Es la entrada de la aplicación.
- Formulario con:
    - Correo electrónico
    - Contraseña
- Botón de “iniciar sesión”. Si no hay errores, lleva a la página principal (Punto 5).
- Botón adicional de “Crear cuenta”. Dirige a la pantalla de registro (Punto 2).

---

## 2️⃣ Pantalla de Registro
- Sólo se permitirá desde la app crear usuarios de tipo "user". Ni "org" ni "admin".
- En el formulario de registro se pedirá al usuario:
    - Nombre de usuario
    - Correo electrónico (obligatorio dominio "@pro2fp.es").
    - Contraseña (al menos 8 caracteres, con al menos 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial)
    - Equipo al que apoya
    - El rol siempre será “user” (por lo que no será un campo como tal del formulario).
- Botón de “Crear cuenta”. Si no hay errores, lleva automáticamente a la pantalla de inicio de sesión (Punto 1).

---

## 3️⃣ Menú Superior
- Visible para todos los usuarios
- Visible desde todas las pantallas, salvo Log-in y Registro.
- Consta de:
    - Botón para desplegar menú lateral (Punto 4) a la izquierda
    - Título de la página donde se encuentra el usuario en el centro
    - Icono por defecto de usuario, Nombre de usuario y rol de usuario a la derecha.

---

## 4️⃣ Menú Desplegable Lateral
- Accesible para todos los usuarios.
- Accesible desde el menú superior (Punto 3).
- Permite navegar entre las secciones de:
    - Pantalla principal (Punto 5).
    - Pantalla de seguir torneos.
    - Calendario de partidos (Punto 7)
    - Cuadro del torneo (Punto 8)
    - Listado de equipos (Punto 13)
    - Máximos goleadores (Punto 16)

---

## 5️⃣ Pantalla Principal
- Para usuarios de tipo "user":
    - De primeras, aparece un selector de los torneos que sigue el usuario.
    - Se muestra un card con la información del torneo seleccionado.
        - Imagen del logo del torneo
        - Nombre del torneo
        - Lugar donde se celebra el torneo
        - Fecha de inicio y de final del torneo (Si son la misma fecha, solo se muestra la de inicio).
- Para usuarios de tipo "org":
    - Se muestra el mismo tipo de card mencionado antes, pero del torneo que esté activo.

---

## 6️⃣ Pantalla de Calendario de Partidos
- Sección superior: un filtro por nombre del torneo y ronda
- Debajo de los filtros, solo si el torneo está activo, los usuarios de tipo org tendrán un botón de añadir partido, que creará un partido con los datos mínimos requeridos:
    - Tournament_id Es el que ha seleccionado el usuario en el filtro
    - Round Es la que ha seleccionado el usuario en el filtro
    - Status (por defecto tiene el valor “pending”)
- Justo debajo se muestran todos los partidos de ese torneo que pertenezcan a esa ronda. Para cada partido se muestra una tabla:
    - Ronda / Jornada (0,0)
    - Fecha y hora (0,1)
    - Campo (0,2)
    - Equipo local (1,0) combinado con (2,0)
    - Estado del partido (1,1)
    - Marcador del partido (2,1)
    - Equipo visitante (1,2) combinado con (2,2)
    - Botón que manda a la ficha del partido. (3,1) (Punto 9)
        -Al hacer click sobre el nombre de uno de los equipos, se redirige a la pantalla de información del equipo (Punto 14)

---

## 7️⃣ Cuadro del Torneo
- En la parte superior se muestra un selector para especificar el torneo del que se quieren consultar los datos.
- Se muestran las llaves del cuadro
    - Para cada partido, se muestra simplemente el nombre de cada equipo y los goles de cada equipo.
    - Al hacer click en un partido, dirige a la pantalla de ficha del partido (Punto 9)

---

## 8️⃣ Ficha del Partido
- Sección superior: Se muestra la información del partido (Formato Punto 7.c.).
    - En esa sección, justo debajo del marcador se muestra un cuadro en el que se introduce el logo de un patrocinador o del torneo.
- Justo debajo, se muestran los eventos del partido, ordenados por minuto ascendentemente.
    - Para cada evento se muestra un icono descriptivo del tipo de evento y el nombre del jugador protagonista.
    - El evento se muestra en una columna izquierda si el jugador es del equipo local, y en una columna derecha si el jugador es del equipo visitante.
- Justo debajo se muestran las alineaciones, primero del equipo local y después del equipo visitante.
    - Primero los jugadores titulares del equipo local.
    - Debajo jugadores suplentes del equipo local.
    - Debajo jugadores titulares del equipo visitante.
    - Debajo jugadores suplentes del equipo visitante.
- Los usuarios de tipo org, en esta pantalla tendrán 3 botones, solo si el torneo del partido está activo:
    - Botón de “Editar información del partido”, Arriba de la información del partido. Dirige a una pantalla de editar datos del partido (Punto 12).
    - Botón de añadir evento, al lado del título “Eventos del partido”. Dirige a una pantalla de “Crear Evento” (Punto 10).
    - Botón de añadir alineaciones, al lado del título “Alineaciones”. Dirige a una pantalla de “Añadir alineaciones” (Punto 11)

---

## 9️⃣ Añadir Evento
- Formulario para registrar un evento. Se puden los siguientes campos:
    - El match_id es el id del partido desde el cual se accede a esa pantalla.
    - Team_id (desplegable con el nombre de los equipos que juegan el partido)
    - Player_id (desplegable con el numero y nombre de los jugadores del equipo seleccionado)
    - Event_type (desplegable con las opciones “Gol”, “Gol en propia”, “Tarjeta amarilla”, “Segunda amarilla”, “Tarjeta roja”).
    - Minute (se introduce el minuto a mano) es opcional.
    - Description es opcional.
    - Botón de “Crear evento” que guarda el evento con los datos introducidos. Dirige de vuelta a la pantalla de ficha del partido (Punto 9).

---

## 🔟 Añadir Alineaciones
- En la parte superior tiene un selector para elegir entre el equipo local o el equipo visitante. Al comienzo se muestra por defecto la del equipo local.
- Debajo del selector, se muestra una lista con el dorsal y el nombre de todos los jugadores del equipo, y a la derecha de cada nombre se muestra un desplegable con las opciones “Titular” o “Suplente”.
- Al final, se muestra un botón de “Cargar alineaciones” que funciona solo cuando todos los jugadores de ambos equipos tienen asignado su rol “Titular” o “Suplente”. Este botón dirige de vuelta a la pantalla de ficha de partido (Punto 9).

---

## 1️⃣1️⃣ Editar Partido
- Formulario con los datos del partido. Se pueden editar:
    - Equipo local (desplegable)
    - Equipo visitante (desplegable)
    - Fecha y hora del partido
    - Campo donde se juega (Texto)
    - Estado del partido (desplegable)

---

## 1️⃣2️⃣ Listado de Equipos
- En la parte superior se muestra un selector para especificar el torneo del que se quieren consultar los datos.
- Se muestra una lista con el nombre de todos los equipos ordenada alfabéticamente.
- Cuando haces click en un equipo, se redirige a una pantalla de información del equipo (Punto 14).
- Si el torneo está activo, los usuarios de tipo org tienen un botón de “Añadir equipo” que dirige a la página de añadir equipo (Punto 17).

---

## 1️⃣3️⃣ Información de Equipo
- Tabla con los datos del equipo.
    - Nombre del equipo
    - Clases que forman el equipo (ej. “2º DAM” o “Profesores”)
    - Color(es) de la equipación
- Listado de jugadores del equipo
    - Dorsal
    - Nombre
- Cuando haces click en un jugador, se redirige a una pantalla de información del jugador (Punto 15).
- Si el torneo en el que se encuentra el equipo está activo, los usuarios de tipo org tienen un botón de “Añadir jugador” que dirige a la página de añadir jugador (Punto 18).

---

## 1️⃣4️⃣ Información de Jugador
- Tabla con los datos del jugador en el torneo desde el que se están consultando los datos.
    - Dorsal y nombre del jugador
    - Nombre del equipo
    - Partidos jugados
        - De titular 
        - De suplente
    - Sanciones
        - Tarjetas amarillas
        - Dobles amarillas
        - Tarjetas rojas
    -Goles
        - Total
        - Goles por partido

---

## 1️⃣5️⃣ Máximos Goleadores
- En la parte superior se muestra un selector para especificar el torneo del que se quieren consultar los datos.
- Tabla con los jugadores que más goles han marcado en el torneo.
    - Nombre del jugador
    - Nombre de su equipo
    - Total de goles
- Cuando haces click en un jugador, se redirige a la pantalla de información del jugador (Punto 15).

---

## 1️⃣6️⃣ Añadir Equipo
- Formulario para introducir los datos del nuevo equipo del torneo. Se pedirán los siguientes datos:
    - Nombre del equipo
    - Grupos de clase que componen el equipo
    - Color de la equipación
    - Tournament_id (será el id del torneo desde el cual se accede a esta pantalla)
    - Botón para enviar datos del equipo, que dirige de vuelta a la pantalla de listado de equipos. (Punto 13)
- Si existe un equipo con el nombre introducido en ese torneo, el nombre del equipo no será válido y se pedirá al usuario que introduzca otro.

---

## 1️⃣7️⃣ Añadir Jugador
- Formulario para introducir los datos del nuevo jugador del equipo. Se pedirán los siguientes datos:
    - Inicialmente se pide el DNI.
    - Habrá un botón para comprobar coincidencias en el sistema.
        - Si se encuentra un jugador con ese DNI, se mostrará una card con los datos del jugador:
            - Nombre
            - DNI
        - Si no se encuentra un jugador con ese DNI, se mostrará otro formulario con los siguientes campos:
            - Nombre del jugador
            - DNI: Será un campo fijo, con el DNI introducido en el paso anterior
            - El id_equipo será el id del equipo desde el cual se accedió a esta pantalla.
            - Dorsal
        - En cualquiera de los 2 casos, se añadirá un Botón para enviar datos del jugador, que dirige de vuelta a la pantalla de información del equipo. (Punto 14)
            - Si el jugador no existía, se crea un registro en player y el player_teams correspondiente.
            - Si el jugador ya existía, solo se crea un registro en player_teams


---

## 1️⃣7️⃣ Seguir torneos
- Pantalla donde se muestra una lista de todos los torneos que hay en la base de datos.
    - Para cada torneo, se muestra el nombre del torneo
    - A la derecha un botón de "Seguir torneo".
- En la parte superior hay un buscador para buscar el nombre del torneo que quieres encontrar.

---

# 🦶 Footer
Imagen del Banner del torneo.
    - La imagen se debe pegar al fondo de la página.
    - Se debe ajustar al ancho de la pantalla del dispositivo, manteniendo la proporción original del banner.
    - El contenido de las páginas debe ser scrolleable entre el menú superior y la imagen de banner.