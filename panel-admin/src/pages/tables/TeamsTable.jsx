import { useState, useEffect } from 'react'
import useCrud from '../../hooks/useCrud'
import useToast from '../../hooks/useToast'
import useExportData from '../../hooks/useExportData'
import useImportData from '../../hooks/useImportData'
import CrudTable from '../../components/tables/CrudTable'
import TableToolbar from '../../components/tables/TableToolbar'
import GenericForm from '../../components/tables/GenericForm'
import Modal from '../../components/common/Modal'
import ImportModal from '../../components/common/ImportModal'
import ExportMenu from '../../components/common/ExportMenu'
import Toast from '../../components/common/Toast'
import Spinner from '../../components/common/Spinner'
import api from '../../api/axios'

const fmtDt = v => v ? new Date(v).toLocaleString('es-ES', { day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', second:'2-digit' }) : '—'
const TEMPLATE_HEADERS = ['name', 'group', 'kit_color', 'logo_url']

export default function TeamsTable() {
  const { items, loading, create, update, remove } = useCrud('/teams')
  const { toast, showToast, hideToast } = useToast()
  const { exportData } = useExportData()
  const { importData } = useImportData()
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)
  const [tournaments, setTournaments] = useState([])
  const [players, setPlayers] = useState([])
  const [tournamentFilter, setTournamentFilter] = useState('')

  useEffect(() => {
    api.get('/tournaments').then(r => setTournaments(r.data)).catch(() => {})
    api.get('/players').then(r => setPlayers(r.data)).catch(() => {})
  }, [])

  const tName = id => tournaments.find(t => t.id === id)?.name ?? `#${id}`
  const filtered = tournamentFilter ? items.filter(t => String(t.tournament_id) === tournamentFilter) : items
  const exportFilename = tournamentFilter ? `teams_${tName(Number(tournamentFilter)).replace(/\s/g, '_')}` : 'teams'

  const COLUMNS = [
    { key: 'id',            label: 'ID' },
    { key: 'name',          label: 'Nombre' },
    { key: 'group',         label: 'Grupo' },
    { key: 'kit_color',     label: 'Equipación' },
    { key: 'tournament_id', label: 'Torneo',     render: v => tName(v), csvRender: v => tName(v) },
    { key: 'created_at',    label: 'Creado',     render: fmtDt, csvRender: fmtDt },
    { key: 'updated_at',    label: 'Modificado', render: fmtDt, csvRender: fmtDt },
  ]
  const fields = [
    { key: 'name',          label: 'Nombre',          required: true },
    { key: 'group',         label: 'Grupo / Clase',   required: true },
    { key: 'kit_color',     label: 'Color equipación', required: true },
    { key: 'logo_url',      label: 'URL del logo',    placeholder: 'https://...' },
    { key: 'tournament_id', label: 'Torneo',          required: true, type: 'select',
      options: tournaments.map(t => ({ value: t.id, label: t.name })) },
  ]

  const handleCreate = async (data) => {
    try { await create(data); setModal(null); showToast('Equipo creado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleEdit = async (data) => {
    try { await update(selected.id, data); setModal(null); showToast('Equipo actualizado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleDelete = async (id) => {
    try { await remove(id); showToast('Equipo eliminado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleImport = async (file, format, context) => {
    return await importData(file, format, async (row) => {
      await api.post('/teams', {
        name: row.name, group: row.group, kit_color: row.kit_color,
        logo_url: row.logo_url || undefined,
        tournament_id: Number(context.tournament_id),
      })
    })
  }

  return (
    <div>
      <TableToolbar
        title={<>Teams <span className="text-hint text-sm font-normal">({filtered.length})</span></>}
        filters={[
          <select key="t" value={tournamentFilter} onChange={e => setTournamentFilter(e.target.value)} className="input-base w-auto text-sm">
            <option value="">Todos los torneos</option>
            {tournaments.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>
        ]}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(filtered, COLUMNS, exportFilename, fmt)} />,
          <button key="imp" onClick={() => setModal('import')} className="btn-secondary text-sm">⬇ Importar</button>,
          <button key="cre" onClick={() => setModal('create')} className="btn-primary text-sm">+ Crear equipo</button>,
        ]}
      />

      <CrudTable columns={COLUMNS} items={filtered} loading={loading} searchKeys={['name', 'group']}
        onEdit={item => { setSelected(item); setModal('edit') }}
        onDelete={handleDelete}
        onView={item => { setSelected(item); setModal('view') }}
      />

      {modal === 'view' && selected && (
        <Modal title={selected.name} onClose={() => setModal(null)}>
          <div className="space-y-2 mb-6">
            {COLUMNS.map(c => (
              <div key={c.key} className="flex gap-2">
                <span className="text-hint text-sm w-28 shrink-0">{c.label}:</span>
                <span className="text-white text-sm">{c.render ? c.render(selected[c.key]) : String(selected[c.key] ?? '—')}</span>
              </div>
            ))}
          </div>
          <TeamPlayers teamId={selected.id} players={players} onToast={showToast} />
        </Modal>
      )}

      {modal === 'create' && (
        <Modal title="Crear equipo" onClose={() => setModal(null)}>
          <GenericForm fields={fields} onSubmit={handleCreate} onCancel={() => setModal(null)} submitLabel="Crear equipo" />
        </Modal>
      )}

      {modal === 'edit' && selected && (
        <Modal title={`Editar: ${selected.name}`} onClose={() => setModal(null)}>
          <GenericForm fields={fields} initial={selected} onSubmit={handleEdit} onCancel={() => setModal(null)} submitLabel="Guardar cambios" />
        </Modal>
      )}

      {modal === 'import' && (
        <ImportModal title="Teams" templateHeaders={TEMPLATE_HEADERS}
          contextFields={[{ key: 'tournament_id', label: 'Torneo destino', options: tournaments.map(t => ({ value: t.id, label: t.name })) }]}
          onImport={handleImport} onClose={() => setModal(null)} />
      )}

      {toast && <Toast {...toast} onClose={hideToast} />}
    </div>
  )
}

// Players list — read only except for removing the assignment
function TeamPlayers({ teamId, players, onToast }) {
  const [playerTeams, setPlayerTeams] = useState([])
  const [loading, setLoading] = useState(true)

  const load = () => {
    setLoading(true)
    api.get('/player-teams', { params: { team_id: teamId } })
      .then(r => setPlayerTeams(r.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [teamId])

  const handleRemove = async (ptId) => {
    try { await api.delete(`/player-teams/${ptId}`); load(); onToast('Jugador desvinculado del equipo') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }

  if (loading) return <Spinner />

  return (
    <div>
      <h4 className="text-primary font-semibold mb-2">
        Jugadores del equipo
        <span className="text-hint font-normal text-xs ml-2">({playerTeams.length})</span>
      </h4>

      {playerTeams.length === 0 ? (
        <p className="text-hint text-sm">Sin jugadores asignados</p>
      ) : (
        <div className="space-y-1">
          {playerTeams.map(pt => {
            const player = players.find(p => p.id === pt.player_id)
            return (
              <div key={pt.id} className="flex items-center justify-between bg-surface-alt px-3 py-2 rounded-lg">
                <div className="flex items-center gap-3">
                  <span className="text-primary font-bold w-8 text-sm">#{pt.number}</span>
                  <span className="text-white text-sm">{player?.name ?? `Jugador #${pt.player_id}`}</span>
                  {player?.dni && <span className="text-hint text-xs">{player.dni}</span>}
                </div>
                <button
                  onClick={() => handleRemove(pt.id)}
                  className="text-error text-xs hover:underline"
                  title="Desvincular jugador del equipo"
                >
                  Quitar
                </button>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
