package com.futcup.app

import android.os.Bundle
import android.view.MenuItem
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.ActionBarDrawerToggle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.GravityCompat
import androidx.drawerlayout.widget.DrawerLayout
import androidx.fragment.app.Fragment
import com.futcup.app.model.TorneoData
import com.futcup.app.ui.bracket.BracketFragment
import com.futcup.app.ui.calendar.CalendarFragment
import com.futcup.app.ui.home.HomeFragment
import com.futcup.app.ui.scorers.ScorersFragment
import com.futcup.app.util.DataReader
import com.google.android.material.navigation.NavigationView
import java.util.concurrent.Executors

class MainActivity : AppCompatActivity(), NavigationView.OnNavigationItemSelectedListener {

    private lateinit var drawerLayout: DrawerLayout
    private lateinit var navView: NavigationView
    var torneoData: TorneoData? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val toolbar = findViewById<androidx.appcompat.widget.Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)

        drawerLayout = findViewById(R.id.drawer_layout)
        navView = findViewById(R.id.nav_view)
        navView.setNavigationItemSelectedListener(this)

        val toggle = ActionBarDrawerToggle(
            this, drawerLayout, toolbar,
            R.string.navigation_drawer_open,
            R.string.navigation_drawer_close
        )
        drawerLayout.addDrawerListener(toggle)
        toggle.syncState()

        cargarDatosAsync()
    }

    private fun cargarDatosAsync() {
        mostrarCargando(true)

        Executors.newSingleThreadExecutor().execute {
            val datos = try {
                DataReader.cargarDatos(this)
            } catch (e: Exception) {
                null
            }

            // Delay de 2 segundos para simular carga
            Thread.sleep(2500)

            runOnUiThread {
                mostrarCargando(false)
                if (datos != null) {
                    torneoData = datos
                    mostrarContenido()
                } else {
                    mostrarError()
                }
            }
        }
    }

    private fun mostrarCargando(loading: Boolean) {
        findViewById<LinearLayout>(R.id.ll_loading).visibility =
            if (loading) View.VISIBLE else View.GONE
        findViewById<FrameLayout>(R.id.fragment_container).visibility =
            if (loading) View.GONE else View.VISIBLE
    }

    private fun mostrarContenido() {
        loadFragment(HomeFragment())
        navView.setCheckedItem(R.id.nav_home)
        supportActionBar?.title = "FutCup 2026"
    }

    private fun mostrarError() {
        val llLoading = findViewById<LinearLayout>(R.id.ll_loading)
        llLoading.visibility = View.VISIBLE
        llLoading.findViewById<ProgressBar>(R.id.progress_bar).visibility = View.GONE
        llLoading.findViewById<TextView>(R.id.tv_cargando).text =
            "No se pudieron cargar los datos.\nComprueba tu conexión a internet."
        val btn = llLoading.findViewById<Button>(R.id.btn_reintentar)
        btn.visibility = View.VISIBLE
        btn.setOnClickListener { cargarDatosAsync() }
    }

    override fun onCreateOptionsMenu(menu: android.view.Menu): Boolean {
        menuInflater.inflate(R.menu.toolbar_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == R.id.action_refresh) {
            cargarDatosAsync()
            return true
        }
        return super.onOptionsItemSelected(item)
    }

    override fun onNavigationItemSelected(item: MenuItem): Boolean {
        val (fragment, title) = when (item.itemId) {
            R.id.nav_home -> HomeFragment() to "FutCup 2026"
            R.id.nav_calendar -> CalendarFragment() to "Calendario de Partidos"
            R.id.nav_scorers -> ScorersFragment() to "Máximos Goleadores"
            R.id.nav_bracket -> BracketFragment() to "Cuadro del Torneo"
            else -> return false
        }
        loadFragment(fragment)
        supportActionBar?.title = title
        drawerLayout.closeDrawer(GravityCompat.START)
        return true
    }

    fun loadFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }

    override fun onBackPressed() {
        if (drawerLayout.isDrawerOpen(GravityCompat.START)) {
            drawerLayout.closeDrawer(GravityCompat.START)
        } else {
            super.onBackPressed()
        }
    }
}
