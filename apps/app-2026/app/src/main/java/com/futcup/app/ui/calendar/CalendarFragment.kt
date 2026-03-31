package com.futcup.app.ui.calendar

import android.os.Bundle
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

class CalendarFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? = inflater.inflate(R.layout.fragment_calendar, container, false)

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
                    container.addView(crearCardPartido(partido))
                }
            }
        }
    }


    private fun crearCardPartido(partido: Partido): View {
        val inflater = LayoutInflater.from(requireContext())
        val card = inflater.inflate(R.layout.item_partido, null)

        card.findViewById<TextView>(R.id.tv_hora).text = partido.hora
        card.findViewById<TextView>(R.id.tv_estado).text = partido.jugado
        card.findViewById<TextView>(R.id.tv_campo).text = partido.campo
        card.findViewById<TextView>(R.id.tv_local).text = partido.equipo_local
        card.findViewById<TextView>(R.id.tv_visitante).text = partido.equipo_visitante
        card.findViewById<TextView>(R.id.tv_resultado).text = partido.getResultado()

        val dp8 = (8 * resources.displayMetrics.density).toInt()
        val dp16 = (16 * resources.displayMetrics.density).toInt()
        card.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(dp16, 0, dp16, dp8) }

        return card
    }
}
