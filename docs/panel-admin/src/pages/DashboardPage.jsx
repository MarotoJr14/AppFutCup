import { useNavigate } from 'react-router-dom'
import Layout from '../components/layout/Layout'
import logoDark from '../assets/futcup_logo_letrablanca.png'

const TABLES = [
  { key: 'users', label: 'Usuarios', icon: '👥', desc: 'Gestión de usuarios del sistema' },
  { key: 'tournaments', label: 'Torneos', icon: '🏆', desc: 'Gestión de torneos registrados' },
  { key: 'teams', label: 'Equipos', icon: '🛡️', desc: 'Gestión de equipos registrados' },
  { key: 'players', label: 'Jugadores', icon: '⚽', desc: 'Gestión de jugadores registrados' },
  { key: 'matches', label: 'Partidos', icon: '📅', desc: 'Gestión de partidos registrados' },
  { key: 'audit-logs', label: 'Auditoría', icon: '📋', desc: 'Registro de auditoría', special: true },
]

export default function DashboardPage() {
  const navigate = useNavigate()
  const logoSrc = logoDark

  return (
    <Layout title="Panel de Administración">
      <div className="text-center mb-8">
        <div className="flex items-center justify-center mb-4">
          <img src={logoSrc} alt="FutCup" className="h-20 w-auto" />
        </div>
        <h2 className="text-2xl font-bold text-white">FutCup App</h2>
        <p className="text-hint">Selecciona una tabla para gestionar</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {TABLES.map(t => (
          <button
            key={t.key}
            onClick={() => navigate(`/table/${t.key}`)}
            className={`card text-left hover:border-primary transition-all hover:scale-[1.02] group
              ${t.special ? 'border-warning/40 hover:border-warning' : ''}`}
          >
            <div className="flex items-center gap-4">
              <div
                className={`w-14 h-14 rounded-xl flex items-center justify-center text-2xl flex-shrink-0
                ${t.special ? 'bg-warning/20' : 'bg-primary/20'}`}
              >
                {t.icon}
              </div>
              <div>
                <h3 className={`font-bold text-lg ${t.special ? 'text-warning group-hover:text-warning' : 'text-primary'}`}>
                  {t.label}
                </h3>
                <p className="text-hint text-sm">{t.desc}</p>
              </div>
            </div>
          </button>
        ))}
      </div>
    </Layout>
  )
}
