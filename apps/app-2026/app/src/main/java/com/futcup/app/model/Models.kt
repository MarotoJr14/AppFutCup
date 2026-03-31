package com.futcup.app.model

data class Torneo(
    val nombre: String,
    val campo: String,
    val fecha_inicio: String,
    val fecha_fin: String
)

data class Equipo(
    val id: Int,
    val nombre: String,
    val ganados: Int = 0
)

data class Partido(
    val id: Int,
    val ronda: String,
    val orden_ronda: Int,
    val equipo_local: String,
    val equipo_visitante: String,
    val goles_local: Int?,
    val goles_visitante: Int?,
    val penaltis_local: Int? = null,
    val penaltis_visitante: Int? = null,
    val jugado: String,
    val hora: String,
    val campo: String
) {
    fun getResultado(): String {
        return if (jugado != "Pendiente" && goles_local != null && goles_visitante != null) {
            val base = "$goles_local - $goles_visitante"
            if (penaltis_local != null && penaltis_visitante != null) {
                "$base (Pen: $penaltis_local-$penaltis_visitante)"
            } else base
        } else {
            "-"
        }
    }

    fun getGanador(): String? {
        if (jugado != "Finalizado" || goles_local == null || goles_visitante == null) return null
        return when {
            goles_local > goles_visitante -> equipo_local
            goles_visitante > goles_local -> equipo_visitante
            penaltis_local != null && penaltis_visitante != null ->
                if (penaltis_local > penaltis_visitante) equipo_local else equipo_visitante
            else -> null
        }
    }
}

data class Goleador(
    val nombre: String,
    val equipo: String,
    val goles: Int
)

data class TorneoData(
    val torneo: Torneo,
    val equipos: List<Equipo>,
    val partidos: List<Partido>,
    val goleadores: List<Goleador>
)
