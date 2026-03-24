import { useParams, useNavigate } from 'react-router-dom'
import Layout from '../components/layout/Layout'
import UsersTable from './tables/UsersTable'
import TournamentsTable from './tables/TournamentsTable'
import TeamsTable from './tables/TeamsTable'
import PlayersTable from './tables/PlayersTable'
import MatchesTable from './tables/MatchesTable'
import AuditLogsTable from './tables/AuditLogsTable'

const TABLE_MAP = {
  users:       { component: UsersTable,       title: 'Gestión de Users' },
  tournaments: { component: TournamentsTable, title: 'Gestión de Tournaments' },
  teams:       { component: TeamsTable,       title: 'Gestión de Teams' },
  players:     { component: PlayersTable,     title: 'Gestión de Players' },
  matches:     { component: MatchesTable,     title: 'Gestión de Matches' },
  'audit-logs':{ component: AuditLogsTable,   title: 'Audit Logs' },
}

export default function TablePage() {
  const { tableKey } = useParams()
  const navigate = useNavigate()
  const entry = TABLE_MAP[tableKey]

  if (!entry) return (
    <Layout title="No encontrado">
      <div className="text-center py-20">
        <p className="text-error text-lg mb-4">Tabla no encontrada: {tableKey}</p>
        <button onClick={() => navigate('/')} className="btn-primary">Volver al panel</button>
      </div>
    </Layout>
  )

  const Component = entry.component
  return (
    <Layout title={entry.title}>
      <div className="mb-4">
        <button onClick={() => navigate('/')} className="text-hint hover:text-primary transition-colors text-sm flex items-center gap-1">
          ← Volver al panel
        </button>
      </div>
      <Component />
    </Layout>
  )
}
