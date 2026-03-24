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

const COLUMNS = [
  { key: 'id',         label: 'ID' },
  { key: 'name',       label: 'Nombre' },
  { key: 'dni',        label: 'DNI' },
  { key: 'created_at', label: 'Creado',     render: fmtDt, csvRender: fmtDt },
  { key: 'updated_at', label: 'Modificado', render: fmtDt, csvRender: fmtDt },
]
const EDIT_FIELDS = [
  { key: 'name', label: 'Nombre', required: true },
  { key: 'dni',  label: 'DNI',    required: true },
]
const TEMPLATE_HEADERS = ['name', 'dni', 'number']

function CreatePlayerWizard({ teams, onClose, onSuccess, onToast }) {
  const [step, setStep] = useState(1)
  const [dni, setDni] = useState('')
  const [searching, setSearching] = useState(false)
  const [found, setFound] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [name, setName] = useState('')
  const [teamId, setTeamId] = useState('')
  const [number, setNumber] = useState('')
  const [saving, setSaving] = useState(false)

  const handleSearch = async () => {
    if (!dni.trim()) return
    setSearching(true)
    try {
      const res = await api.get(`/players/search-dni/${dni.trim()}`)
      if (res.data) { setFound(res.data); setNotFound(false) }
      else { setFound(null); setNotFound(true) }
    } catch { setFound(null); setNotFound(true) }
    finally { setSearching(false); setStep(2) }
  }
  const handleSubmit = async () => {
    if (!teamId || !number) { onToast('Equipo y dorsal son obligatorios', 'error'); return }
    if (!found && !name.trim()) { onToast('El nombre es obligatorio para jugadores nuevos', 'error'); return }
    setSaving(true)
    try {
      await api.post('/player-teams/register', { dni: dni.trim(), name: found ? undefined : name.trim(), team_id: Number(teamId), number: Number(number) })
      onToast('Jugador creado y asignado al equipo'); onSuccess(); onClose()
    } catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
    finally { setSaving(false) }
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="text-hint text-sm mb-1 block">DNI del jugador <span className="text-error">*</span></label>
        <div className="flex gap-2">
          <input type="text" value={dni} onChange={e => { setDni(e.target.value); setStep(1); setFound(null); setNotFound(false) }} className="input-base flex-1" placeholder="12345678A" />
          <button onClick={handleSearch} disabled={!dni.trim() || searching} className="btn-primary whitespace-nowrap">{searching ? '...' : 'Buscar'}</button>
        </div>
      </div>
      {step === 2 && (
        <>
          {found ? (
            <div className="bg-success/10 border border-success/40 rounded-lg p-3 flex items-center gap-3"><span className="text-success text-xl">✓</span><div><p className="text-white font-semibold">{found.name}</p><p className="text-hint text-xs">{found.dni} · Jugador ya registrado</p></div></div>
          ) : (
            <div className="space-y-3">
              <div className="bg-warning/10 border border-warning/40 rounded-lg p-3 text-warning text-sm">Jugador no encontrado. Completa sus datos.</div>
              <div><label className="text-hint text-sm mb-1 block">Nombre <span className="text-error">*</span></label><input type="text" value={name} onChange={e => setName(e.target.value)} className="input-base" /></div>
              <div><label className="text-hint text-sm mb-1 block">DNI</label><input type="text" value={dni} readOnly className="input-base opacity-50 cursor-not-allowed" /></div>
            </div>
          )}
          <div><label className="text-hint text-sm mb-1 block">Equipo <span className="text-error">*</span></label><select value={teamId} onChange={e => setTeamId(e.target.value)} className="input-base bg-surface-alt"><option value="">— Selecciona equipo —</option>{teams.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}</select></div>
          <div><label className="text-hint text-sm mb-1 block">Dorsal <span className="text-error">*</span></label><input type="number" value={number} onChange={e => setNumber(e.target.value)} className="input-base" min={1} /></div>
          <div className="flex gap-3 justify-end pt-2"><button onClick={onClose} className="btn-secondary">Cancelar</button><button onClick={handleSubmit} disabled={saving} className="btn-primary">{saving ? 'Guardando...' : 'Crear jugador'}</button></div>
        </>
      )}
      {step === 1 && <div className="flex justify-end pt-2"><button onClick={onClose} className="btn-secondary">Cancelar</button></div>}
    </div>
  )
}

export default function PlayersTable() {
  const { items, loading, update, remove, fetchAll } = useCrud('/players')
  const { toast, showToast, hideToast } = useToast()
  const { exportData } = useExportData()
  const { importData } = useImportData()
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)
  const [teams, setTeams] = useState([])
  const [teamFilter, setTeamFilter] = useState('')
  const [filteredItems, setFilteredItems] = useState([])

  useEffect(() => { api.get('/teams').then(r => setTeams(r.data)).catch(() => {}) }, [])
  useEffect(() => {
    if (!teamFilter) { setFilteredItems(items); return }
    api.get('/player-teams', { params: { team_id: teamFilter } }).then(r => {
      const ids = r.data.map(pt => pt.player_id)
      setFilteredItems(items.filter(p => ids.includes(p.id)))
    }).catch(() => setFilteredItems(items))
  }, [teamFilter, items])

  const handleEdit = async (data) => {
    try { await update(selected.id, data); setModal(null); showToast('Jugador actualizado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleDelete = async (id) => {
    try { await remove(id); showToast('Jugador eliminado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleImport = async (file, format, context) => {
    return await importData(file, format, async (row) => {
      await api.post('/player-teams/register', { dni: row.dni, name: row.name, team_id: Number(context.team_id), number: Number(row.number) })
    })
  }

  const teamName = id => teams.find(t => t.id === Number(id))?.name ?? `#${id}`
  const exportFilename = teamFilter ? `players_${teamName(teamFilter).replace(/\s/g,'_')}` : 'players'

  return (
    <div>
      <TableToolbar
        title={<>Players <span className="text-hint text-sm font-normal">({filteredItems.length})</span></>}
        filters={[
          <select key="t" value={teamFilter} onChange={e => setTeamFilter(e.target.value)} className="input-base w-auto text-sm">
            <option value="">Todos los equipos</option>
            {teams.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>
        ]}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(filteredItems, COLUMNS, exportFilename, fmt)} />,
          <button key="imp" onClick={() => setModal('import')} className="btn-secondary text-sm">⬇ Importar</button>,
          <button key="cre" onClick={() => setModal('create')} className="btn-primary text-sm">+ Crear jugador</button>,
        ]}
      />
      <CrudTable columns={COLUMNS} items={filteredItems} loading={loading} searchKeys={['name', 'dni']}
        onEdit={item => { setSelected(item); setModal('edit') }}
        onDelete={handleDelete}
        onView={item => { setSelected(item); setModal('view') }}
      />
      {modal === 'view' && selected && (<Modal title={selected.name} onClose={() => setModal(null)}><div className="space-y-2 mb-6">{COLUMNS.map(c => (<div key={c.key} className="flex gap-2"><span className="text-hint text-sm w-28 shrink-0">{c.label}:</span><span className="text-white text-sm">{c.render ? c.render(selected[c.key]) : String(selected[c.key] ?? '—')}</span></div>))}</div><PlayerTeams playerId={selected.id} teams={teams} onToast={showToast} /></Modal>)}
      {modal === 'create' && (<Modal title="Crear jugador" onClose={() => setModal(null)}><CreatePlayerWizard teams={teams} onClose={() => setModal(null)} onSuccess={fetchAll} onToast={showToast} /></Modal>)}
      {modal === 'edit' && selected && (<Modal title={`Editar: ${selected.name}`} onClose={() => setModal(null)}><GenericForm fields={EDIT_FIELDS} initial={selected} onSubmit={handleEdit} onCancel={() => setModal(null)} submitLabel="Guardar cambios" /></Modal>)}
      {modal === 'import' && (<ImportModal title="Players" templateHeaders={TEMPLATE_HEADERS} contextFields={[{ key: 'team_id', label: 'Equipo destino', options: teams.map(t => ({ value: t.id, label: t.name })) }]} onImport={handleImport} onClose={() => setModal(null)} />)}
      {toast && <Toast {...toast} onClose={hideToast} />}
    </div>
  )
}

function PlayerTeams({ playerId, teams, onToast }) {
  const [playerTeams, setPlayerTeams] = useState([])
  const [loading, setLoading] = useState(true)
  const load = () => { setLoading(true); api.get('/player-teams', { params: { player_id: playerId } }).then(r => setPlayerTeams(r.data)).catch(() => {}).finally(() => setLoading(false)) }
  useEffect(() => { load() }, [playerId])
  const handleRemove = async (ptId) => {
    try { await api.delete(`/player-teams/${ptId}`); load(); onToast('Asignación eliminada') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }
  if (loading) return <Spinner />
  return (
    <div>
      <h4 className="text-primary font-semibold mb-2">Equipos asignados</h4>
      {playerTeams.length === 0 && <p className="text-hint text-sm">Sin equipos asignados</p>}
      <div className="space-y-1">{playerTeams.map(pt => { const team = teams.find(t => t.id === pt.team_id); return (<div key={pt.id} className="flex items-center justify-between bg-surface-alt px-3 py-2 rounded-lg"><div><span className="text-primary font-bold mr-2">#{pt.number}</span><span className="text-white text-sm">{team?.name ?? `Equipo #${pt.team_id}`}</span></div><button onClick={() => handleRemove(pt.id)} className="text-error text-xs hover:underline">Quitar</button></div>) })}</div>
    </div>
  )
}
