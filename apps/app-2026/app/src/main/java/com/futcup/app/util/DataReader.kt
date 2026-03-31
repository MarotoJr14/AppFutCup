package com.futcup.app.util

import android.content.Context
import com.futcup.app.R
import com.futcup.app.model.*
import org.json.JSONObject
import java.net.URL

object DataReader {

    // ⚙️ CAMBIA ESTA URL por la de tu archivo JSON en GitHub (URL "raw")
    const val JSON_URL = "https://raw.githubusercontent.com/MarotoJr14/AppFutCup2026/refs/heads/main/app/src/main/res/raw/torneo.json"

    fun cargarDatos(context: Context): TorneoData {
        val json = try {
            val connection = URL(JSON_URL).openConnection()
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.getInputStream().bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            // Sin conexión: usa el JSON local como fallback
            context.resources.openRawResource(R.raw.torneo)
                .bufferedReader().use { it.readText() }
        }
        return parsearJson(json)
    }

    fun parsearJson(json: String): TorneoData {
        val root = JSONObject(json)

        // Torneo
        val t = root.getJSONObject("torneo")
        val torneo = Torneo(
            nombre = t.getString("nombre"),
            campo = t.getString("campo"),
            fecha_inicio = t.getString("fecha_inicio"),
            fecha_fin = t.getString("fecha_fin")
        )

        // Equipos
        val equiposJson = root.getJSONArray("equipos")
        val equipos = (0 until equiposJson.length()).map {
            val e = equiposJson.getJSONObject(it)
            Equipo(
                id = e.getInt("id"),
                nombre = e.getString("nombre"),
                ganados = e.getInt("ganados")
            )
        }

        // Partidos
        val partidosJson = root.getJSONArray("partidos")
        val partidos = (0 until partidosJson.length()).map {
            val p = partidosJson.getJSONObject(it)
            Partido(
                id = p.getInt("id"),
                ronda = p.getString("ronda"),
                orden_ronda = p.getInt("orden_ronda"),
                equipo_local = p.getString("equipo_local"),
                equipo_visitante = p.getString("equipo_visitante"),
                goles_local = if (p.isNull("goles_local")) null else p.getInt("goles_local"),
                goles_visitante = if (p.isNull("goles_visitante")) null else p.getInt("goles_visitante"),
                penaltis_local = if (p.isNull("penaltis_local")) null else p.getInt("penaltis_local"),
                penaltis_visitante = if (p.isNull("penaltis_visitante")) null else p.getInt("penaltis_visitante"),
                jugado = p.getString("jugado"),
                hora = p.getString("hora"),
                campo = p.getString("campo")
            )
        }

        // Goleadores
        val goleadoresJson = root.getJSONArray("goleadores")
        val goleadores = (0 until goleadoresJson.length()).map {
            val g = goleadoresJson.getJSONObject(it)
            Goleador(
                nombre = g.getString("nombre"),
                equipo = g.getString("equipo"),
                goles = if (g.isNull("goles")) 0 else g.getInt("goles")
            )
        }

        return TorneoData(torneo, equipos, partidos, goleadores)
    }
}
