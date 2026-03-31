package com.futcup.app.ui.scorers

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

class ScorersFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? = inflater.inflate(R.layout.fragment_scorers, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val data = (requireActivity() as MainActivity).torneoData ?: return
        val container = view.findViewById<LinearLayout>(R.id.ll_goleadores)

        val goleadoresOrdenados = data.goleadores
            .filter { it.goles > 0 }
            .sortedWith(compareByDescending<com.futcup.app.model.Goleador> { it.goles }
                .thenBy { it.equipo }
                .thenBy { it.nombre })

        goleadoresOrdenados.forEachIndexed { index, goleador ->
            val inflater = LayoutInflater.from(requireContext())
            val row = inflater.inflate(R.layout.item_goleador, null)

            val posicion = when (index) {
                0 -> "🥇"
                1 -> "🥈"
                2 -> "🥉"
                else -> "${index + 1}º"
            }

            row.findViewById<TextView>(R.id.tv_posicion).text = posicion
            row.findViewById<TextView>(R.id.tv_nombre).text = goleador.nombre
            row.findViewById<TextView>(R.id.tv_equipo).text = goleador.equipo
            row.findViewById<TextView>(R.id.tv_goles).text =
                "${goleador.goles} ⚽"

            if (index < 3) {
                if(index == 0) {
                    row.setBackgroundColor(
                        ContextCompat.getColor(requireContext(), R.color.gold_light)
                    )
                } else if (index == 1) {
                    row.setBackgroundColor(
                        ContextCompat.getColor(requireContext(), R.color.silver_light)
                    )
                } else {
                    row.setBackgroundColor(
                        ContextCompat.getColor(requireContext(), R.color.bronze_light)
                    )
                }
                row.findViewById<TextView>(R.id.tv_nombre).apply {
                    setTypeface(null, Typeface.BOLD)
                }
            }

            val dp8 = (8 * resources.displayMetrics.density).toInt()
            val dp16 = (16 * resources.displayMetrics.density).toInt()
            row.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp16, 0, dp16, dp8) }

            container.addView(row)
        }
    }
}
