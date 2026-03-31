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

const fmtDt   = v => v ? new Date(v).toLocaleString('es-ES', { day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', second:'2-digit' }) : '—'
const fmtDate = v => v ? new Date(v).toLocaleDateString('es-ES') : '—'

const COLUMNS = [
  { key: 'id',         label: 'ID' },
  { key: 'name',       label: 'Nombre' },
  { key: 'place',      label: 'Lugar' },
  { key: 'date_ini',   label: 'Inicio',     render: fmtDate, csvRender: fmtDate },
  { key: 'date_end',   label: 'Fin',        render: fmtDate, csvRender: fmtDate },
  { key: 'is_active',  label: 'Activo',     csvRender: v => v ? 'Sí' : 'No' },
  { key: 'created_at', label: 'Creado',     render: fmtDt,   csvRender: fmtDt },
  { key: 'updated_at', label: 'Modificado', render: fmtDt,   csvRender: fmtDt },
]
const FIELDS = [
  { key: 'name',      label: 'Nombre',       required: true },
  { key: 'place',     label: 'Lugar',        required: true },
  { key: 'date_ini',  label: 'Fecha inicio', required: true, type: 'datetime' },
  { key: 'date_end',  label: 'Fecha fin',    required: true, type: 'datetime' },
  { key: 'is_active', label: 'Activo',       type: 'boolean', default: 'false' },
]
const TEMPLATE_HEADERS = ['name', 'place', 'date_ini', 'date_end', 'is_active']

export default function TournamentsTable() {
  const { items, loading, create, update, remove } = useCrud('/tournaments')
  const { toast, showToast, hideToast } = useToast()
  const { exportData } = useExportData()
  const { importData } = useImportData()
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)

  const handleCreate = async (data) => {
    try { await create(data); setModal(null); showToast('Torneo creado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleEdit = async (data) => {
    try { await update(selected.id, data); setModal(null); showToast('Torneo actualizado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleDelete = async (id) => {
    try { await remove(id); showToast('Torneo eliminado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleImport = async (file, format) => {
    return await importData(file, format, async (row) => {
      await api.post('/tournaments', {
        name: row.name, place: row.place,
        date_ini: row.date_ini, date_end: row.date_end,
        is_active: row.is_active === 'true' || row.is_active === 'Sí' || row.is_active === true,
      })
    })
  }

  return (
    <div>
      <TableToolbar
        title={<>Tournaments <span className="text-hint text-sm font-normal">({items.length})</span></>}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(items, COLUMNS, 'tournaments', fmt)} />,
          <button key="imp" onClick={() => setModal('import')} className="btn-secondary text-sm">⬇ Importar</button>,
          <button key="cre" onClick={() => setModal('create')} className="btn-primary text-sm">+ Crear torneo</button>,
        ]}
      />

      <CrudTable columns={COLUMNS} items={items} loading={loading} searchKeys={['name', 'place']}
        onEdit={item => { setSelected(item); setModal('edit') }}
        onDelete={handleDelete}
        onView={item => { setSelected(item); setModal('view') }}
      />

      {modal === 'view' && selected && (
        <Modal title={selected.name} onClose={() => setModal(null)}>
          {/* Tournament info */}
          <div className="space-y-2 mb-6">
            {COLUMNS.map(c => (
              <div key={c.key} className="flex gap-2">
                <span className="text-hint text-sm w-28 shrink-0">{c.label}:</span>
                <span className="text-white text-sm">{c.render ? c.render(selected[c.key]) : String(selected[c.key] ?? '—')}</span>
              </div>
            ))}
          </div>
          {/* Teams list — read only */}
          <TournamentTeams tournamentId={selected.id} />
        </Modal>
      )}

      {modal === 'create' && (
        <Modal title="Crear torneo" onClose={() => setModal(null)}>
          <GenericForm fields={FIELDS} onSubmit={handleCreate} onCancel={() => setModal(null)} submitLabel="Crear torneo" />
        </Modal>
      )}

      {modal === 'edit' && selected && (
        <Modal title={`Editar: ${selected.name}`} onClose={() => setModal(null)}>
          <GenericForm
            fields={FIELDS}
            initial={{
              ...selected,
              date_ini: selected.date_ini?.slice(0, 16) || '',
              date_end: selected.date_end?.slice(0, 16) || '',
              is_active: String(selected.is_active),
            }}
            onSubmit={handleEdit}
            onCancel={() => setModal(null)}
            submitLabel="Guardar cambios"
          />
        </Modal>
      )}

      {modal === 'import' && (
        <ImportModal title="Tournaments" templateHeaders={TEMPLATE_HEADERS} onImport={handleImport} onClose={() => setModal(null)} />
      )}

      {toast && <Toast {...toast} onClose={hideToast} />}
    </div>
  )
}

function TournamentTeams({ tournamentId }) {
  const [teams, setTeams] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    api.get('/teams', { params: { tournament_id: tournamentId } })
      .then(r => setTeams(r.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [tournamentId])

  if (loading) return <Spinner />

  return (
    <div>
      <h4 className="text-primary font-semibold mb-2">
        Equipos del torneo
        <span className="text-hint font-normal text-xs ml-2">({teams.length})</span>
      </h4>
      {teams.length === 0 ? (
        <p className="text-hint text-sm">Sin equipos registrados</p>
      ) : (
        <div className="space-y-1">
          {teams.map(t => (
            <div key={t.id} className="flex items-center justify-between bg-surface-alt px-3 py-2 rounded-lg">
              <div>
                <span className="text-white text-sm font-medium">{t.name}</span>
                <span className="text-hint text-xs ml-2">{t.group}</span>
              </div>
              <span className="text-hint text-xs">{t.kit_color}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
