package com.futcup.app.ui.bracket

import android.os.Bundle
import android.graphics.Typeface
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.futcup.app.MainActivity
import com.futcup.app.R
import com.futcup.app.model.Partido

class BracketFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? = inflater.inflate(R.layout.fragment_bracket, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val data = (requireActivity() as MainActivity).torneoData ?: return

        val rondas = listOf("1/8 de Final", "1/4 de Final", "Semifinal", "Final")

        rondas.forEach { nombreRonda ->
            val containerRes = when (nombreRonda) {
                "1/8 de Final" -> R.id.ll_octavos
                "1/4 de Final" -> R.id.ll_cuartos
                "Semifinal" -> R.id.ll_semis
                "Final" -> R.id.ll_final
                else -> return@forEach
            }

            val container = view.findViewById<LinearLayout>(containerRes)
            val partidos = data.partidos.filter { it.ronda == nombreRonda }

            if (partidos.isEmpty()) {
                val tv = TextView(requireContext()).apply {
                    text = "Sin partidos asignados"
                    textSize = 12f
                    setTextColor(ContextCompat.getColor(requireContext(), R.color.text_secondary))
                    val dp8 = (8 * resources.displayMetrics.density).toInt()
                    setPadding(0, dp8, 0, dp8)
                }
                container.addView(tv)
            } else {
                partidos.forEach { partido ->
                    container.addView(crearLlave(partido))
                }
            }
        }
    }

    private fun crearLlave(partido: Partido): View {
        val inflater = LayoutInflater.from(requireContext())
        val llave = inflater.inflate(R.layout.item_llave, null)

        val ganador = partido.getGanador()

        val tvLocal = llave.findViewById<TextView>(R.id.tv_llave_local)
        val tvVisitante = llave.findViewById<TextView>(R.id.tv_llave_visitante)
        val tvGolesLocal = llave.findViewById<TextView>(R.id.tv_llave_goles_local)
        val tvGolesVisitante = llave.findViewById<TextView>(R.id.tv_llave_goles_visitante)

        tvLocal.text = partido.equipo_local
        tvVisitante.text = partido.equipo_visitante

        if (partido.jugado == "Finalizado" && partido.goles_local != null && partido.goles_visitante != null) {
            tvGolesLocal.text = partido.goles_local.toString()
            tvGolesVisitante.text = partido.goles_visitante.toString()

            if (ganador == partido.equipo_local) {
                tvLocal.setTypeface(null, Typeface.BOLD)
                tvLocal.setTextColor(ContextCompat.getColor(requireContext(), R.color.gold_primary))
                tvGolesLocal.setTypeface(null, Typeface.BOLD)
                tvGolesLocal.setTextColor(ContextCompat.getColor(requireContext(), R.color.gold_primary))
            } else if (ganador == partido.equipo_visitante) {
                tvVisitante.setTypeface(null, Typeface.BOLD)
                tvVisitante.setTextColor(ContextCompat.getColor(requireContext(), R.color.gold_primary))
                tvGolesVisitante.setTypeface(null, Typeface.BOLD)
                tvGolesVisitante.setTextColor(ContextCompat.getColor(requireContext(), R.color.gold_primary))
            }
        } else {
            tvGolesLocal.text = "-"
            tvGolesVisitante.text = "-"
        }

        val dp8 = (8 * resources.displayMetrics.density).toInt()
        llave.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = dp8 }

        return llave
    }
}
