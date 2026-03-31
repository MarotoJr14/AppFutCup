import { useState, useEffect } from 'react'
import useCrud from '../../hooks/useCrud'
import useToast from '../../hooks/useToast'
import useExportData from '../../hooks/useExportData'
import useImportData from '../../hooks/useImportData'
import CrudTable from '../../components/tables/CrudTable'
import TableToolbar from '../../components/tables/TableToolbar'
import Modal from '../../components/common/Modal'
import ImportModal from '../../components/common/ImportModal'
import ExportMenu from '../../components/common/ExportMenu'
import Toast from '../../components/common/Toast'
import Spinner from '../../components/common/Spinner'
import api from '../../api/axios'

const fmtDt = v => v ? new Date(v).toLocaleString('es-ES', { day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', second:'2-digit' }) : '—'
const ROUND_LABELS = { RoundOf16:'Octavos de final', Quarterfinal:'Cuartos de final', Semifinal:'Semifinal', Final:'Final' }
const ROUNDS = ['RoundOf16', 'Quarterfinal', 'Semifinal', 'Final']
const ROUND_LIMITS = { RoundOf16: 8, Quarterfinal: 4, Semifinal: 2, Final: 1 }
const STATUSES = [
  { value: 'Pending',  label: 'Pendiente' },
  { value: 'Playing',  label: 'En juego' },
  { value: 'Penalties', label: 'Penaltis' },
  { value: 'Finished', label: 'Finalizado' },
]
const TEMPLATE_HEADERS = ['round','datetime','field','team_home_name','team_away_name']

// ── Standalone match form (bypasses GenericForm to control types precisely) ──
function MatchForm({ initial = {}, teams, tournaments, onSubmit, onCancel, onToast, submitLabel = 'Guardar', hideStatus = false }) {
  const [form, setForm] = useState({
    tournament_id: initial.tournament_id ?? '',
    round:         initial.round         ?? '',
    status:        initial.status        ?? 'Pending',
    team_home_id:  initial.team_home_id  ?? '',
    team_away_id:  initial.team_away_id  ?? '',
    datetime:      initial.datetime      ? initial.datetime.slice(0, 16) : '',
    field:         initial.field         ?? '',
  })
  const [errors, setErrors] = useState({})
  const [saving, setSaving] = useState(false)
  const isEdit = Boolean(initial?.id)
  const isPlaying = initial?.status === 'Playing'
  const isPenalties = initial?.status === 'Penalties'
  const isFinished = initial?.status === 'Finished'
  const lockInfo = isPlaying || isPenalties || isFinished
  const isDraw = (Number(initial?.goals_home ?? 0) === Number(initial?.goals_away ?? 0))

  const set = (k, v) => setForm(p => ({ ...p, [k]: v }))
  const normalizeDatetime = (v) => {
    if (!v) return v
    // <input type="datetime-local"> returns YYYY-MM-DDTHH:MM (no seconds)
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(v)) return `${v}:00`
    // Strip fractional seconds (some backends reject them)
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+$/.test(v)) return v.replace(/\.\d+$/, '')
    return v
  }

  const validate = () => {
    const errs = {}
    if (!form.tournament_id) errs.tournament_id = 'Campo requerido'
    if (!form.round)         errs.round         = 'Campo requerido'
    if (!hideStatus && !form.status) errs.status = 'Campo requerido'
    setErrors(errs)
    return Object.keys(errs).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!validate()) return
    const payload = {
      tournament_id: Number(form.tournament_id),
      round:         form.round,
    }
    if (!hideStatus) payload.status = form.status
    if (form.team_home_id) payload.team_home_id = Number(form.team_home_id)
    if (form.team_away_id) payload.team_away_id = Number(form.team_away_id)
    if (form.datetime)     payload.datetime     = normalizeDatetime(form.datetime)
    if (form.field)        payload.field        = form.field
    setSaving(true)
    try {
      await onSubmit(payload)
    } catch (e) {
      onToast?.(e.response?.data?.detail || e.message || 'Error', 'error')
    } finally {
      setSaving(false)
    }
  }

  const sel = (label, key, options, required = false, disabled = false) => (
    <div>
      <label className="text-sm text-hint mb-1 block">{label}{required && <span className="text-error ml-1">*</span>}</label>
      <select value={form[key]} onChange={e => set(key, e.target.value)} disabled={disabled} className="input-base bg-surface-alt">
        <option value="">— Selecciona —</option>
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
      {errors[key] && <p className="text-error text-xs mt-1">{errors[key]}</p>}
    </div>
  )

  const inp = (label, key, type = 'text', placeholder = '', disabled = false) => (
    <div>
      <label className="text-sm text-hint mb-1 block">{label}</label>
      <input type={type} value={form[key]} onChange={e => set(key, e.target.value)} disabled={disabled}
        className="input-base" placeholder={placeholder} />
    </div>
  )

  const tournamentTeams = form.tournament_id
    ? teams.filter(t => String(t.tournament_id) === String(form.tournament_id))
    : []

  const statusOptions =
    initial.status === 'Pending'
      ? STATUSES.filter(s => s.value === 'Pending' || s.value === 'Playing')
      : initial.status === 'Playing'
        ? (isDraw ? STATUSES.filter(s => s.value === 'Playing' || s.value === 'Penalties') : STATUSES.filter(s => s.value === 'Playing' || s.value === 'Finished'))
        : initial.status === 'Penalties'
          ? STATUSES.filter(s => s.value === 'Penalties' || s.value === 'Finished')
          : STATUSES.filter(s => s.value === 'Finished')

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {sel('Torneo', 'tournament_id', tournaments.map(t => ({ value: t.id, label: t.name })), true, isEdit || lockInfo)}
      {sel('Ronda', 'round', ROUNDS.map(r => ({ value: r, label: ROUND_LABELS[r] })), true, lockInfo)}
      {!hideStatus && sel('Estado', 'status', statusOptions, true, isFinished)}
      {sel('Equipo local', 'team_home_id', tournamentTeams.map(t => ({ value: t.id, label: t.name })), false, lockInfo || initial.team_home_id != null || !form.tournament_id)}
      {sel('Equipo visitante', 'team_away_id', tournamentTeams.map(t => ({ value: t.id, label: t.name })), false, lockInfo || initial.team_away_id != null || !form.tournament_id)}
      <div>
        <label className="text-sm text-hint mb-1 block">Fecha y hora</label>
        <input type="datetime-local" value={form.datetime} onChange={e => set('datetime', e.target.value)} disabled={lockInfo} className="input-base" />
      </div>
      {inp('Campo', 'field', 'text', 'Ej: Campo 1', lockInfo)}
      <div className="flex gap-3 justify-end pt-2">
        <button type="button" onClick={onCancel} disabled={saving} className="btn-secondary">Cancelar</button>
        <button type="submit" disabled={saving || isFinished} className="btn-primary">{saving ? 'Guardando...' : submitLabel}</button>
      </div>
    </form>
  )
}

// ── Main table ────────────────────────────────────────────────────────────────
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

  const tName    = id => tournaments.find(t => t.id === id)?.name  ?? `#${id}`
  const teamName = id => teams.find(t => t.id === id)?.name ?? (id ? `#${id}` : '—')

  const filtered = items
    .filter(m => !tournamentFilter || String(m.tournament_id) === tournamentFilter)
    .filter(m => !roundFilter      || m.round === roundFilter)

  const COLUMNS = [
    { key: 'id',            label: 'ID' },
    { key: 'tournament_id', label: 'Torneo',     render: v => tName(v),    csvRender: v => tName(v) },
    { key: 'round',         label: 'Ronda',      render: v => ROUND_LABELS[v] ?? v },
    { key: 'team_home_id',  label: 'Local',      render: v => teamName(v), csvRender: v => teamName(v) },
    { key: 'team_away_id',  label: 'Visitante',  render: v => teamName(v), csvRender: v => teamName(v) },
    { key: 'status',        label: 'Estado' },
    { key: 'goals_home',    label: 'G.L',        render: v => v ?? '—' },
    { key: 'goals_away',    label: 'G.V',        render: v => v ?? '—' },
    { key: 'created_at',    label: 'Creado',     render: fmtDt, csvRender: fmtDt },
    { key: 'updated_at',    label: 'Modificado', render: fmtDt, csvRender: fmtDt },
  ]

  const handleCreate = async (data) => {
    console.log('Payload enviado:', JSON.stringify(data))
    const limit = ROUND_LIMITS[data.round]
    if (limit) {
      const count = items.filter(m => m.tournament_id === data.tournament_id && m.round === data.round).length
      if (count >= limit) {
        showToast(`Límite alcanzado: máximo ${limit} partidos en ${ROUND_LABELS[data.round] || data.round}`, 'error')
        return
      }
    }
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
    const tournamentId = Number(context.tournament_id)
    const roundCounts = {}
    items
      .filter(m => m.tournament_id === tournamentId)
      .forEach(m => { roundCounts[m.round] = (roundCounts[m.round] || 0) + 1 })

    return await importData(file, format, async (row) => {
      const limit = ROUND_LIMITS[row.round]
      if (limit) {
        const nextCount = (roundCounts[row.round] || 0) + 1
        if (nextCount > limit) {
          throw new Error(`Límite alcanzado: máximo ${limit} partidos en ${ROUND_LABELS[row.round] || row.round}`)
        }
        roundCounts[row.round] = nextCount
      }
      const homeTeam = teams.find(t => t.name === row.team_home_name && String(t.tournament_id) === String(context.tournament_id))
      const awayTeam = teams.find(t => t.name === row.team_away_name && String(t.tournament_id) === String(context.tournament_id))
      await api.post('/matches', {
        tournament_id: tournamentId,
        round: row.round,
        datetime: row.datetime || undefined, field: row.field || undefined,
        team_home_id: homeTeam?.id, team_away_id: awayTeam?.id,
      })
    })
  }

  const exportFilename = ['matches',
    tournamentFilter ? tName(Number(tournamentFilter)).replace(/\s/g, '_') : null,
    roundFilter || null,
  ].filter(Boolean).join('_')

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
          </select>,
        ]}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(filtered, COLUMNS, exportFilename, fmt)} />,
          <button key="imp" onClick={() => setModal('import')} className="btn-secondary text-sm">⬇ Importar</button>,
          <button key="cre" onClick={() => setModal('create')} className="btn-primary text-sm">+ Crear partido</button>,
        ]}
      />

      <CrudTable columns={COLUMNS} items={filtered} loading={loading} searchKeys={['round', 'status']}
        onEdit={item => { setSelected(item); setModal('edit') }}
        onDelete={handleDelete}
        onView={item => { setSelected(item); setModal('view') }}
      />

      {modal === 'view' && selected && (
        <Modal title={`Partido #${selected.id}`} onClose={() => setModal(null)}>
          <div className="space-y-2 mb-6">
            {COLUMNS.map(c => (
              <div key={c.key} className="flex gap-2">
                <span className="text-hint text-sm w-28 shrink-0">{c.label}:</span>
                <span className="text-white text-sm">{c.render ? c.render(selected[c.key]) : String(selected[c.key] ?? '—')}</span>
              </div>
            ))}
          </div>
          <MatchEvents matchId={selected.id} matchStatus={selected.status} homeTeamId={selected.team_home_id} awayTeamId={selected.team_away_id} teams={teams} onToast={showToast} />
          <div className="mt-6">
            <MatchLineups matchId={selected.id} matchStatus={selected.status} homeTeamId={selected.team_home_id} awayTeamId={selected.team_away_id} teams={teams} onToast={showToast} />
          </div>
        </Modal>
      )}

      {modal === 'create' && (
        <Modal title="Crear partido" onClose={() => setModal(null)}>
          <MatchForm teams={teams} tournaments={tournaments} onSubmit={handleCreate} onCancel={() => setModal(null)} onToast={showToast} submitLabel="Crear partido" hideStatus />
        </Modal>
      )}

      {modal === 'edit' && selected && (
        <Modal title={`Editar partido #${selected.id}`} onClose={() => setModal(null)}>
          <MatchForm initial={selected} teams={teams} tournaments={tournaments} onSubmit={handleEdit} onCancel={() => setModal(null)} onToast={showToast} submitLabel="Guardar cambios" />
        </Modal>
      )}

      {modal === 'import' && (
        <ImportModal title="Matches" templateHeaders={TEMPLATE_HEADERS}
          contextFields={[{ key: 'tournament_id', label: 'Torneo destino', options: tournaments.map(t => ({ value: t.id, label: t.name })) }]}
          onImport={handleImport} onClose={() => setModal(null)} />
      )}

      {toast && <Toast {...toast} onClose={hideToast} />}
    </div>
  )
}

function MatchEvents({ matchId, matchStatus, homeTeamId, awayTeamId, teams, onToast }) {
  const [events, setEvents] = useState([])
  const [loading, setLoading] = useState(true)
  const [showMatchForm, setShowMatchForm] = useState(false)
  const [showPenaltyForm, setShowPenaltyForm] = useState(false)
  const [playerTeams, setPlayerTeams] = useState([]) // player-teams del equipo seleccionado
  const [allPlayers, setAllPlayers] = useState([])   // todos los jugadores para cruzar nombres
  const defaultForm = { team_id:'', player_id:'', event_type:'', minute:'', description:'' }
  const [form, setForm] = useState(defaultForm)
  const EVENT_ICONS = { Goal:'⚽', Owngoal:'❌', Yellow:'🟨', YellowX2:'🟨🟥', Red:'🟥' }
  const PENALTY_ICONS = { PenaltyScored:'✅', PenaltyMissed:'❌' }
  const matchTeams = teams.filter(t => [homeTeamId, awayTeamId].includes(t.id))
  const canAddMatchEvents = matchStatus === 'Playing' && Boolean(homeTeamId) && Boolean(awayTeamId)
  const canAddPenalties = matchStatus === 'Penalties' && Boolean(homeTeamId) && Boolean(awayTeamId)

  useEffect(() => {
    if (!canAddMatchEvents) setShowMatchForm(false)
  }, [canAddMatchEvents])

  useEffect(() => {
    if (!canAddPenalties) setShowPenaltyForm(false)
  }, [canAddPenalties])

  useEffect(() => {
    if (!form.team_id) return
    const allowed = matchTeams.some(t => String(t.id) === String(form.team_id))
    if (!allowed) setForm(f => ({ ...f, team_id: '', player_id: '' }))
  }, [form.team_id, homeTeamId, awayTeamId, teams])

  const load = () => {
    setLoading(true)
    api.get('/events', { params:{ match_id: matchId } })
      .then(r => setEvents(r.data))
      .finally(() => setLoading(false))
  }

  // Load all players once for name lookup
  useEffect(() => {
    load()
    api.get('/players').then(r => setAllPlayers(r.data)).catch(() => {})
  }, [matchId])

  // When team changes, load its player-teams
  useEffect(() => {
    if (!form.team_id) { setPlayerTeams([]); return }
    api.get('/player-teams', { params:{ team_id: form.team_id } })
      .then(r => setPlayerTeams(r.data))
      .catch(() => {})
  }, [form.team_id])

  const playerName = (playerId) => {
    const player = allPlayers.find(p => p.id === playerId)
    return player?.name ?? `Jugador ${playerId}`
  }
  const teamName = (teamId) =>
    teams.find(t => t.id === teamId)?.name ?? (teamId ? `Equipo ${teamId}` : '—')

  const handleCreate = async () => {
    const isPenaltyType = form.event_type === 'PenaltyScored' || form.event_type === 'PenaltyMissed'
    if (isPenaltyType && !canAddPenalties) { onToast?.('Solo se pueden añadir penaltis cuando el partido está en penaltis', 'error'); return }
    if (!isPenaltyType && !canAddMatchEvents) { onToast?.('Solo se pueden añadir eventos cuando el partido está en juego', 'error'); return }
    if (!form.team_id || !form.player_id || !form.event_type) {
      onToast('Equipo, jugador y tipo de evento son obligatorios', 'error'); return
    }
    try {
      await api.post('/events', {
        match_id: matchId,
        team_id: Number(form.team_id),
        player_id: Number(form.player_id),
        event_type: form.event_type,
        minute: form.minute ? Number(form.minute) : undefined,
        description: form.description || undefined,
      })
      load()
      setShowMatchForm(false)
      setShowPenaltyForm(false)
      setForm(defaultForm)
      setPlayerTeams([])
      onToast('Evento creado')
    } catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }

  const handleDelete = async (id) => {
    try { await api.delete(`/events/${id}`); load(); onToast('Evento eliminado') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }

  if (loading) return <Spinner />
  const normalEvents = events.filter(e => e.event_type !== 'PenaltyScored' && e.event_type !== 'PenaltyMissed')
  const penaltyEvents = events.filter(e => e.event_type === 'PenaltyScored' || e.event_type === 'PenaltyMissed')
  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <h4 className="text-primary font-semibold">Eventos del partido</h4>
      {canAddMatchEvents ? (
          <button
            onClick={() => setShowMatchForm(s => {
              const next = !s
              if (next) {
                setShowPenaltyForm(false)
                setForm(defaultForm)
                setPlayerTeams([])
              }
              return next
            })}
            className="text-primary text-sm hover:underline"
          >
            {showMatchForm ? 'Cancelar' : '+ Crear evento'}
          </button>
        ) : (
          <span className="text-hint text-xs">
            {matchStatus === 'Finished'
              ? 'Partido finalizado'
              : matchStatus === 'Penalties'
                ? 'El partido está en penaltis'
                : 'Pon el partido en juego para añadir eventos'}
          </span>
        )}
      </div>

      {showMatchForm && (
        <div className="bg-surface-alt rounded-lg p-3 mb-3 space-y-2">
          {/* Team selector */}
          <select value={form.team_id}
            onChange={e => setForm(f => ({ ...f, team_id: e.target.value, player_id:'' }))}
            className="input-base bg-bg">
            <option value="">— Equipo —</option>
            {matchTeams.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>

          {/* Player selector — shows real name */}
          <select value={form.player_id}
            onChange={e => setForm(f => ({ ...f, player_id: e.target.value }))}
            className="input-base bg-bg">
            <option value="">— Jugador —</option>
            {playerTeams.map(pt => (
              <option key={pt.player_id} value={pt.player_id}>
                #{pt.number} — {playerName(pt.player_id)}
              </option>
            ))}
          </select>

          {/* Event type */}
          <select value={form.event_type}
            onChange={e => setForm(f => ({ ...f, event_type: e.target.value }))}
            className="input-base bg-bg">
            <option value="">— Tipo de evento —</option>
            {Object.entries(EVENT_ICONS).map(([k,v]) => (
              <option key={k} value={k}>{v} {k}</option>
            ))}
          </select>

          <input type="number" placeholder="Minuto (opcional)" value={form.minute}
            onChange={e => setForm(f => ({ ...f, minute: e.target.value }))} className="input-base" />
          <input type="text" placeholder="Descripción (opcional)" value={form.description}
            onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input-base" />

          <button onClick={handleCreate} className="btn-primary w-full">Crear evento</button>
        </div>
      )}

      {normalEvents.length === 0 && <p className="text-hint text-sm">Sin eventos</p>}
      <div className="space-y-1">
        {normalEvents.sort((a,b) => (a.minute??99)-(b.minute??99)).map(e => (
          <div key={e.id} className="flex items-center gap-2 bg-surface-alt px-3 py-2 rounded-lg">
            <span>{EVENT_ICONS[e.event_type]??'•'}</span>
            <div className="flex-1 min-w-0">
              <div className="text-white text-sm truncate">{playerName(e.player_id)}</div>
              <div className="text-hint text-xs truncate">{teamName(e.team_id)}</div>
            </div>
            {e.minute && <span className="text-hint text-xs">{e.minute}'</span>}
            <button onClick={() => handleDelete(e.id)} className="text-error text-xs hover:underline">Borrar</button>
          </div>
        ))}
      </div>

      <div className="mt-5">
        <div className="flex items-center justify-between mb-2">
          <h4 className="text-primary font-semibold">Tanda de penaltis</h4>
          {canAddPenalties ? (
            <button
              onClick={() => setShowPenaltyForm(s => {
                const next = !s
                if (next) {
                  setShowMatchForm(false)
                  setForm(defaultForm)
                  setPlayerTeams([])
                }
                return next
              })}
              className="text-primary text-sm hover:underline"
            >
              {showPenaltyForm ? 'Cancelar' : '+ Registrar penalti'}
            </button>
          ) : (
            <span className="text-hint text-xs">
              {matchStatus === 'Penalties' ? 'Selecciona un equipo y jugador' : 'Pon el partido en penaltis para registrar penaltis'}
            </span>
          )}
        </div>

        {showPenaltyForm && (
          <div className="bg-surface-alt rounded-lg p-3 mb-3 space-y-2">
            <select value={form.team_id}
              onChange={e => setForm(f => ({ ...f, team_id: e.target.value, player_id:'' }))}
              className="input-base bg-bg">
              <option value="">— Equipo —</option>
              {matchTeams.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>

            <select value={form.player_id}
              onChange={e => setForm(f => ({ ...f, player_id: e.target.value }))}
              className="input-base bg-bg">
              <option value="">— Jugador —</option>
              {playerTeams.map(pt => (
                <option key={pt.player_id} value={pt.player_id}>
                  #{pt.number} — {playerName(pt.player_id)}
                </option>
              ))}
            </select>

            <select value={form.event_type}
              onChange={e => setForm(f => ({ ...f, event_type: e.target.value }))}
              className="input-base bg-bg">
              <option value="">— Resultado —</option>
              {Object.entries(PENALTY_ICONS).map(([k,v]) => (
                <option key={k} value={k}>{v} {k}</option>
              ))}
            </select>

            <input type="text" placeholder="Descripción (opcional)" value={form.description}
              onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input-base" />

            <button onClick={handleCreate} className="btn-primary w-full">Registrar penalti</button>
          </div>
        )}

        {penaltyEvents.length === 0 && <p className="text-hint text-sm">Sin penaltis</p>}
        <div className="space-y-1">
          {penaltyEvents.sort((a,b) => (a.id)-(b.id)).map(e => (
            <div key={e.id} className="flex items-center gap-2 bg-surface-alt px-3 py-2 rounded-lg">
              <span>{PENALTY_ICONS[e.event_type]??'•'}</span>
              <div className="flex-1 min-w-0">
                <div className="text-white text-sm truncate">{playerName(e.player_id)}</div>
                <div className="text-hint text-xs truncate">{teamName(e.team_id)}</div>
              </div>
              <button onClick={() => handleDelete(e.id)} className="text-error text-xs hover:underline">Borrar</button>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}


function MatchLineups({ matchId, matchStatus, homeTeamId, awayTeamId, teams, onToast }) {
  const [lineups, setLineups] = useState([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [allPlayers, setAllPlayers] = useState([])
  const [playerTeams, setPlayerTeams] = useState([])
  const [form, setForm] = useState({ team_id: '', player_id: '', role: '' })

  const matchTeams = teams.filter(t => [homeTeamId, awayTeamId].includes(t.id))
  const canAdd = matchStatus === 'Pending' && Boolean(homeTeamId) && Boolean(awayTeamId)

  useEffect(() => {
    if (!canAdd) setShowForm(false)
  }, [canAdd])

  const load = () => {
    setLoading(true)
    api.get('/lineups', { params: { match_id: matchId } })
      .then(r => setLineups(r.data))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    api.get('/players').then(r => setAllPlayers(r.data)).catch(() => {})
  }, [matchId])

  useEffect(() => {
    if (!form.team_id) { setPlayerTeams([]); return }
    api.get('/player-teams', { params: { team_id: form.team_id } })
      .then(r => setPlayerTeams(r.data))
      .catch(() => {})
  }, [form.team_id])

  const playerName = (playerId) =>
    allPlayers.find(p => p.id === playerId)?.name ?? `Jugador ${playerId}`

  const handleCreate = async () => {
    if (!canAdd) {
      onToast?.('Las alineaciones solo se pueden cargar cuando el partido está pendiente', 'error')
      return
    }
    if (!form.team_id || !form.player_id || !form.role) {
      onToast('Equipo, jugador y rol son obligatorios', 'error'); return
    }
    try {
      await api.post('/lineups', {
        match_id: matchId,
        team_id: Number(form.team_id),
        player_id: Number(form.player_id),
        role: form.role,
      })
      load()
      setShowForm(false)
      setForm({ team_id: '', player_id: '', role: '' })
      onToast('Alineación añadida')
    } catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }

  const handleDelete = async (id) => {
    try { await api.delete(`/lineups/${id}`); load(); onToast('Alineación eliminada') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }

  const teamName = id => teams.find(t => t.id === id)?.name ?? `#${id}`
  const grouped = { [homeTeamId]: [], [awayTeamId]: [] }
  lineups.forEach(l => { if (grouped[l.team_id] !== undefined) grouped[l.team_id].push(l) })

  if (loading) return <Spinner />

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <h4 className="text-primary font-semibold">Alineaciones</h4>
        {canAdd ? (
          <button onClick={() => setShowForm(!showForm)} className="text-primary text-sm hover:underline">
            {showForm ? 'Cancelar' : '+ Añadir alineación'}
          </button>
        ) : (
          <span className="text-hint text-xs">
            {matchStatus === 'Finished'
              ? 'Partido finalizado'
              : 'Las alineaciones solo se cargan en estado Pendiente'}
          </span>
        )}
      </div>

      {showForm && (
        <div className="bg-surface-alt rounded-lg p-3 mb-3 space-y-2">
          {/* Team */}
          <select value={form.team_id}
            onChange={e => setForm(f => ({ ...f, team_id: e.target.value, player_id: '' }))}
            className="input-base bg-bg">
            <option value="">— Equipo —</option>
            {matchTeams.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>

          {/* Player */}
          <select value={form.player_id}
            onChange={e => setForm(f => ({ ...f, player_id: e.target.value }))}
            className="input-base bg-bg">
            <option value="">— Jugador —</option>
            {playerTeams.map(pt => (
              <option key={pt.player_id} value={pt.player_id}>
                #{pt.number} — {playerName(pt.player_id)}
              </option>
            ))}
          </select>

          {/* Role */}
          <select value={form.role}
            onChange={e => setForm(f => ({ ...f, role: e.target.value }))}
            className="input-base bg-bg">
            <option value="">— Rol —</option>
            <option value="Starter">Titular</option>
            <option value="Bench">Suplente</option>
          </select>

          <button onClick={handleCreate} className="btn-primary w-full">Añadir alineación</button>
        </div>
      )}

      {[homeTeamId, awayTeamId].filter(Boolean).map(tid => (
        <div key={tid} className="mb-3">
          <p className="text-white text-sm font-semibold mb-1">{teamName(tid)}</p>
          {(grouped[tid] || []).length === 0
            ? <p className="text-hint text-xs">Sin alineación</p>
            : grouped[tid].map(l => (
                <div key={l.id} className="flex items-center gap-2 bg-surface-alt px-3 py-1 rounded mb-1">
                  <span className={`text-xs w-16 font-medium ${l.role === 'Starter' ? 'text-success' : 'text-hint'}`}>
                    {l.role === 'Starter' ? 'Titular' : 'Suplente'}
                  </span>
                  <span className="text-white text-sm flex-1">{playerName(l.player_id)}</span>
                  {canAdd && (
                    <button onClick={() => handleDelete(l.id)} className="text-error text-xs hover:underline">Borrar</button>
                  )}
                </div>
              ))
          }
        </div>
      ))}
    </div>
  )
}
