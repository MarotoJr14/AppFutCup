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
const ROUND_LABELS = { Octavofinal:'Octavos', Quarterfinal:'Cuartos', Semifinal:'Semifinal', Final:'Final' }
const ROUNDS = ['Octavofinal','Quarterfinal','Semifinal','Final']
const TEMPLATE_HEADERS = ['round','status','datetime','field','team_home_name','team_away_name','goals_home','goals_away']

export default function MatchesTable() {
  const { items, loading, create, update, remove } = useCrud('/matches')
  const { toast, showToast, hideToast } = useToast()
  const { exportData } = useExportData()
  const { importData } = useImportData()
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)
  const [tournaments, setTournaments] = useState([])
  const [teams, setTeams] = useState([])
  const [tournamentFilter, setTournamentFilter] = useState('')
  const [roundFilter, setRoundFilter] = useState('')

  useEffect(() => {
    api.get('/tournaments').then(r => setTournaments(r.data)).catch(() => {})
    api.get('/teams').then(r => setTeams(r.data)).catch(() => {})
  }, [])

  const tName = id => tournaments.find(t => t.id === id)?.name ?? `#${id}`
  const teamName = id => teams.find(t => t.id === id)?.name ?? (id ? `#${id}` : '—')
  const filtered = items
    .filter(m => !tournamentFilter || String(m.tournament_id) === tournamentFilter)
    .filter(m => !roundFilter || m.round === roundFilter)

  const COLUMNS = [
    { key: 'id',            label: 'ID' },
    { key: 'tournament_id', label: 'Torneo',    render: v => tName(v),     csvRender: v => tName(v) },
    { key: 'round',         label: 'Ronda',     render: v => ROUND_LABELS[v] ?? v },
    { key: 'team_home_id',  label: 'Local',     render: v => teamName(v),  csvRender: v => teamName(v) },
    { key: 'team_away_id',  label: 'Visitante', render: v => teamName(v),  csvRender: v => teamName(v) },
    { key: 'status',        label: 'Estado' },
    { key: 'goals_home',    label: 'G.L',       render: v => v ?? '—' },
    { key: 'goals_away',    label: 'G.V',       render: v => v ?? '—' },
    { key: 'created_at',    label: 'Creado',     render: fmtDt, csvRender: fmtDt },
    { key: 'updated_at',    label: 'Modificado', render: fmtDt, csvRender: fmtDt },
  ]
  const fields = [
    { key: 'tournament_id', label: 'Torneo',           required: true, type: 'select', options: tournaments.map(t => ({ value: t.id, label: t.name })) },
    { key: 'round',         label: 'Ronda',            required: true, type: 'select', options: ROUNDS.map(r => ({ value: r, label: ROUND_LABELS[r] })) },
    { key: 'status',        label: 'Estado',           required: true, type: 'select', default: 'Pending', options: [{ value:'Pending', label:'Pendiente' }, { value:'Playing', label:'En juego' }, { value:'Finished', label:'Finalizado' }] },
    { key: 'team_home_id',  label: 'Equipo local',     type: 'select', options: teams.map(t => ({ value: t.id, label: t.name })) },
    { key: 'team_away_id',  label: 'Equipo visitante', type: 'select', options: teams.map(t => ({ value: t.id, label: t.name })) },
    { key: 'datetime',      label: 'Fecha y hora',     type: 'datetime' },
    { key: 'field',         label: 'Campo',            placeholder: 'Ej: Campo 1' },
    { key: 'goals_home',    label: 'Goles local',      type: 'number' },
    { key: 'goals_away',    label: 'Goles visitante',  type: 'number' },
  ]

  const handleCreate = async (data) => {
    try { await create(data); setModal(null); showToast('Partido creado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleEdit = async (data) => {
    try { await update(selected.id, data); setModal(null); showToast('Partido actualizado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleDelete = async (id) => {
    try { await remove(id); showToast('Partido eliminado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleImport = async (file, format, context) => {
    return await importData(file, format, async (row) => {
      const homeTeam = teams.find(t => t.name === row.team_home_name)
      const awayTeam = teams.find(t => t.name === row.team_away_name)
      await api.post('/matches', { tournament_id: Number(context.tournament_id), round: row.round, status: row.status || 'Pending', datetime: row.datetime || undefined, field: row.field || undefined, team_home_id: homeTeam?.id || undefined, team_away_id: awayTeam?.id || undefined, goals_home: row.goals_home ? Number(row.goals_home) : undefined, goals_away: row.goals_away ? Number(row.goals_away) : undefined })
    })
  }

  const exportFilename = ['matches', tournamentFilter ? tName(Number(tournamentFilter)).replace(/\s/g,'_') : null, roundFilter || null].filter(Boolean).join('_')

  return (
    <div>
      <TableToolbar
        title={<>Matches <span className="text-hint text-sm font-normal">({filtered.length})</span></>}
        filters={[
          <select key="t" value={tournamentFilter} onChange={e => setTournamentFilter(e.target.value)} className="input-base w-auto text-sm">
            <option value="">Todos los torneos</option>
            {tournaments.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>,
          <select key="r" value={roundFilter} onChange={e => setRoundFilter(e.target.value)} className="input-base w-auto text-sm">
            <option value="">Todas las rondas</option>
            {ROUNDS.map(r => <option key={r} value={r}>{ROUND_LABELS[r]}</option>)}
          </select>
        ]}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(filtered, COLUMNS, exportFilename, fmt)} />,
          <button key="imp" onClick={() => setModal('import')} className="btn-secondary text-sm">⬇ Importar</button>,
          <button key="cre" onClick={() => setModal('create')} className="btn-primary text-sm">+ Crear partido</button>,
        ]}
      />
      <CrudTable columns={COLUMNS} items={filtered} loading={loading} searchKeys={['round','status']}
        onEdit={item => { setSelected(item); setModal('edit') }}
        onDelete={handleDelete}
        onView={item => { setSelected(item); setModal('view') }}
      />
      {modal === 'view' && selected && (<Modal title={`Partido #${selected.id}`} onClose={() => setModal(null)}><div className="space-y-2 mb-6">{COLUMNS.map(c => (<div key={c.key} className="flex gap-2"><span className="text-hint text-sm w-28 shrink-0">{c.label}:</span><span className="text-white text-sm">{c.render ? c.render(selected[c.key]) : String(selected[c.key] ?? '—')}</span></div>))}</div><MatchEvents matchId={selected.id} teams={teams} onToast={showToast} /><div className="mt-6"><MatchLineups matchId={selected.id} homeTeamId={selected.team_home_id} awayTeamId={selected.team_away_id} teams={teams} onToast={showToast} /></div></Modal>)}
      {modal === 'create' && (<Modal title="Crear partido" onClose={() => setModal(null)}><GenericForm fields={fields} onSubmit={handleCreate} onCancel={() => setModal(null)} submitLabel="Crear partido" /></Modal>)}
      {modal === 'edit' && selected && (<Modal title={`Editar partido #${selected.id}`} onClose={() => setModal(null)}><GenericForm fields={fields} initial={{ ...selected, datetime: selected.datetime?.slice(0,16) || '' }} onSubmit={handleEdit} onCancel={() => setModal(null)} submitLabel="Guardar cambios" /></Modal>)}
      {modal === 'import' && (<ImportModal title="Matches" templateHeaders={TEMPLATE_HEADERS} contextFields={[{ key: 'tournament_id', label: 'Torneo destino', options: tournaments.map(t => ({ value: t.id, label: t.name })) }]} onImport={handleImport} onClose={() => setModal(null)} />)}
      {toast && <Toast {...toast} onClose={hideToast} />}
    </div>
  )
}

function MatchEvents({ matchId, teams, onToast }) {
  const [events, setEvents] = useState([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [players, setPlayers] = useState([])
  const [form, setForm] = useState({ team_id:'', player_id:'', event_type:'', minute:'', description:'' })
  const EVENT_ICONS = { Goal:'⚽', Owngoal:'🙈', Yellow:'🟨', YellowX2:'🟧', Red:'🟥' }
  const load = () => { setLoading(true); api.get('/events', { params:{ match_id: matchId } }).then(r => setEvents(r.data)).finally(() => setLoading(false)) }
  useEffect(() => { load() }, [matchId])
  useEffect(() => { if (form.team_id) api.get('/player-teams', { params:{ team_id: form.team_id } }).then(r => setPlayers(r.data)) }, [form.team_id])
  const handleCreate = async () => {
    try { await api.post('/events', { match_id: matchId, team_id: Number(form.team_id), player_id: Number(form.player_id), event_type: form.event_type, minute: form.minute ? Number(form.minute) : undefined, description: form.description || undefined }); load(); setShowForm(false); onToast('Evento creado') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleDelete = async (id) => {
    try { await api.delete(`/events/${id}`); load(); onToast('Evento eliminado') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }
  if (loading) return <Spinner />
  return (
    <div>
      <div className="flex items-center justify-between mb-2"><h4 className="text-primary font-semibold">Eventos del partido</h4><button onClick={() => setShowForm(!showForm)} className="text-primary text-sm hover:underline">{showForm ? 'Cancelar' : '+ Crear evento'}</button></div>
      {showForm && (<div className="bg-surface-alt rounded-lg p-3 mb-3 space-y-2"><select value={form.team_id} onChange={e => setForm(f => ({ ...f, team_id: e.target.value, player_id:'' }))} className="input-base bg-bg"><option value="">— Equipo —</option>{teams.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}</select><select value={form.player_id} onChange={e => setForm(f => ({ ...f, player_id: e.target.value }))} className="input-base bg-bg"><option value="">— Jugador —</option>{players.map(p => <option key={p.player_id} value={p.player_id}>#{p.number} Jugador {p.player_id}</option>)}</select><select value={form.event_type} onChange={e => setForm(f => ({ ...f, event_type: e.target.value }))} className="input-base bg-bg"><option value="">— Tipo —</option>{Object.entries(EVENT_ICONS).map(([k,v]) => <option key={k} value={k}>{v} {k}</option>)}</select><input type="number" placeholder="Minuto (opcional)" value={form.minute} onChange={e => setForm(f => ({ ...f, minute: e.target.value }))} className="input-base" /><input type="text" placeholder="Descripción (opcional)" value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input-base" /><button onClick={handleCreate} className="btn-primary w-full">Crear evento</button></div>)}
      {events.length === 0 && <p className="text-hint text-sm">Sin eventos</p>}
      <div className="space-y-1">{events.sort((a,b) => (a.minute??99)-(b.minute??99)).map(e => (<div key={e.id} className="flex items-center gap-2 bg-surface-alt px-3 py-2 rounded-lg"><span>{EVENT_ICONS[e.event_type]??'•'}</span><span className="text-white text-sm flex-1">Jugador {e.player_id}</span>{e.minute && <span className="text-hint text-xs">{e.minute}'</span>}<button onClick={() => handleDelete(e.id)} className="text-error text-xs hover:underline">Borrar</button></div>))}</div>
    </div>
  )
}

function MatchLineups({ matchId, homeTeamId, awayTeamId, teams, onToast }) {
  const [lineups, setLineups] = useState([])
  const [loading, setLoading] = useState(true)
  const load = () => { setLoading(true); api.get('/lineups', { params:{ match_id: matchId } }).then(r => setLineups(r.data)).finally(() => setLoading(false)) }
  useEffect(() => { load() }, [matchId])
  const handleDelete = async (id) => {
    try { await api.delete(`/lineups/${id}`); load(); onToast('Alineación eliminada') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const teamName = id => teams.find(t => t.id === id)?.name ?? `#${id}`
  const grouped = { [homeTeamId]:[], [awayTeamId]:[] }
  lineups.forEach(l => { if (grouped[l.team_id]) grouped[l.team_id].push(l) })
  if (loading) return <Spinner />
  return (
    <div>
      <h4 className="text-primary font-semibold mb-2">Alineaciones</h4>
      {[homeTeamId, awayTeamId].filter(Boolean).map(tid => (<div key={tid} className="mb-3"><p className="text-white text-sm font-semibold mb-1">{teamName(tid)}</p>{(grouped[tid]||[]).length === 0 ? <p className="text-hint text-xs">Sin alineación</p> : grouped[tid].map(l => (<div key={l.id} className="flex items-center gap-2 bg-surface-alt px-3 py-1 rounded mb-1"><span className="text-hint text-xs w-16">{l.role}</span><span className="text-white text-sm flex-1">Jugador {l.player_id}</span><button onClick={() => handleDelete(l.id)} className="text-error text-xs hover:underline">Borrar</button></div>))}</div>))}
    </div>
  )
}
