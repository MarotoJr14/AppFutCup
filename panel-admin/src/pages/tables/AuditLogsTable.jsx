import { useState } from 'react'
import useCrud from '../../hooks/useCrud'
import useExportData from '../../hooks/useExportData'
import TableToolbar from '../../components/tables/TableToolbar'
import ExportMenu from '../../components/common/ExportMenu'
import SearchBar from '../../components/common/SearchBar'
import Pagination from '../../components/common/Pagination'
import Spinner from '../../components/common/Spinner'

const PAGE_SIZE = 15
const ACTION_COLORS = { Create:'bg-success/20 text-success', Update:'bg-warning/20 text-warning', Delete:'bg-error/20 text-error' }
const ENTITIES = ['User','Tournament','User_tournament','Team','Player','Player_team','Match','Event','Lineup']
const ACTIONS   = ['Create','Update','Delete']

const fmtDt = v => v ? new Date(v).toLocaleString('es-ES', { day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', second:'2-digit' }) : '—'

const COLUMNS = [
  { key: 'id',         label: 'ID' },
  { key: 'entity',     label: 'Entidad' },
  { key: 'action',     label: 'Acción' },
  { key: 'user_id',    label: 'Usuario ID' },
  { key: 'details',    label: 'Detalles' },
  { key: 'created_at', label: 'Fecha', csvRender: fmtDt },
]

export default function AuditLogsTable() {
  const { items, loading } = useCrud('/audit-logs')
  const { exportData } = useExportData()
  const [page, setPage]           = useState(1)
  const [search, setSearch]       = useState('')
  const [entityFilter, setEntity] = useState('')
  const [actionFilter, setAction] = useState('')

  const filtered = items
    .filter(i => !entityFilter || i.entity === entityFilter)
    .filter(i => !actionFilter || i.action === actionFilter)
    .filter(i => !search || [i.entity, i.action, i.details, String(i.user_id)].some(v => String(v ?? '').toLowerCase().includes(search.toLowerCase())))

  const totalPages = Math.ceil(filtered.length / PAGE_SIZE)
  const paginated  = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const exportFilename = ['audit_logs', entityFilter, actionFilter].filter(Boolean).join('_')

  if (loading) return <Spinner />

  return (
    <div>
      <TableToolbar
        title={<>Audit Logs <span className="text-hint text-sm font-normal">({filtered.length})</span></>}
        filters={[
          <select key="e" value={entityFilter} onChange={e => { setEntity(e.target.value); setPage(1) }} className="input-base w-auto text-sm">
            <option value="">Todas las entidades</option>
            {ENTITIES.map(e => <option key={e} value={e}>{e}</option>)}
          </select>,
          <select key="a" value={actionFilter} onChange={e => { setAction(e.target.value); setPage(1) }} className="input-base w-auto text-sm">
            <option value="">Todas las acciones</option>
            {ACTIONS.map(a => <option key={a} value={a}>{a}</option>)}
          </select>,
        ]}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(filtered, COLUMNS, exportFilename, fmt)} />,
        ]}
      />
      <div className="mb-4">
        <SearchBar value={search} onChange={v => { setSearch(v); setPage(1) }} />
      </div>   
      <div className="overflow-x-auto rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface-alt border-b border-border">
              {['ID','Entidad','Acción','Usuario','Detalles','Fecha'].map(h => (
                <th key={h} className="text-left px-4 py-3 text-primary font-semibold">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {paginated.length === 0 ? (
              <tr><td colSpan={6} className="text-center text-hint py-8">Sin registros</td></tr>
            ) : paginated.map(log => (
              <tr key={log.id} className="border-b border-border hover:bg-surface-alt/50 transition-colors">
                <td className="px-4 py-3 text-hint">{log.id}</td>
                <td className="px-4 py-3 text-white font-medium">{log.entity}</td>
                <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${ACTION_COLORS[log.action] || 'bg-surface-alt text-white'}`}>{log.action}</span></td>
                <td className="px-4 py-3 text-white">#{log.user_id}</td>
                <td className="px-4 py-3 text-hint text-xs max-w-xs truncate">{log.details ?? '—'}</td>
                <td className="px-4 py-3 text-hint text-xs whitespace-nowrap">{fmtDt(log.created_at)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={page} totalPages={totalPages} onChange={setPage} />
    </div>
  )
}
