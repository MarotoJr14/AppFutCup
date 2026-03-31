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
import api from '../../api/axios'

const fmtDt = v => v ? new Date(v).toLocaleString('es-ES', { day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', second:'2-digit' }) : '—'

const COLUMNS = [
  { key: 'id',         label: 'ID' },
  { key: 'username',   label: 'Usuario' },
  { key: 'email',      label: 'Correo' },
  { key: 'role',       label: 'Rol' },
  { key: 'created_at', label: 'Creado',     render: fmtDt, csvRender: fmtDt },
  { key: 'updated_at', label: 'Modificado', render: fmtDt, csvRender: fmtDt },
]
const FIELDS = [
  { key: 'username', label: 'Usuario', required: true },
  { key: 'email',    label: 'Correo electrónico', required: true, type: 'email' },
  { key: 'password', label: 'Contraseña', type: 'password', required: true, placeholder: 'Mín. 8 caracteres' },
  { key: 'role',     label: 'Rol', required: true, type: 'select', options: [{ value: 'admin', label: 'Admin' }, { value: 'org', label: 'Org' }, { value: 'user', label: 'User' }] },
]
const EDIT_FIELDS = FIELDS.map(f => f.key === 'password' ? { ...f, required: false, placeholder: 'Dejar vacío para no cambiar' } : f)
const TEMPLATE_HEADERS = ['username', 'email', 'password', 'role']
const ROLES = ['admin', 'org', 'user']

export default function UsersTable() {
  const { items, loading, create, update, remove } = useCrud('/users')
  const { toast, showToast, hideToast } = useToast()
  const { exportData } = useExportData()
  const { importData } = useImportData()
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)
  const [tournaments, setTournaments] = useState([])
  const [roleFilter, setRoleFilter] = useState('')

  useEffect(() => { api.get('/tournaments').then(r => setTournaments(r.data)).catch(() => {}) }, [])

  const filtered = roleFilter ? items.filter(u => u.role === roleFilter) : items
  const exportFilename = `users${roleFilter ? '_' + roleFilter : ''}`

  const handleCreate = async (data) => {
    try { await create(data); setModal(null); showToast('Usuario creado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleEdit = async (data) => {
    try { await update(selected.id, data); setModal(null); showToast('Usuario actualizado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleDelete = async (id) => {
    const u = items.find(u => u.id === id)
    if (u?.role === 'admin' && items.filter(u => u.role === 'admin').length <= 1) {
      showToast('No se puede eliminar el único administrador del sistema', 'error'); return
    }
    try { await remove(id); showToast('Usuario eliminado') }
    catch (e) { showToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const handleImport = async (file, format) => {
    return await importData(file, format, async (row) => {
      await api.post('/users', { username: row.username, email: row.email, password: row.password, role: row.role || 'user' })
    })
  }

  return (
    <div>
      <TableToolbar
        title={<>Users <span className="text-hint text-sm font-normal">({filtered.length})</span></>}
        filters={[
          <select key="role" value={roleFilter} onChange={e => setRoleFilter(e.target.value)} className="input-base w-auto text-sm">
            <option value="">Todos los roles</option>
            {ROLES.map(r => <option key={r} value={r}>{r}</option>)}
          </select>
        ]}
        actions={[
          <ExportMenu key="exp" onExport={fmt => exportData(filtered, COLUMNS, exportFilename, fmt)} />,
          <button key="imp" onClick={() => setModal('import')} className="btn-secondary text-sm">⬇ Importar</button>,
          <button key="cre" onClick={() => setModal('create')} className="btn-primary text-sm">+ Crear usuario</button>,
        ]}
      />

      <CrudTable columns={COLUMNS} items={filtered} loading={loading} searchKeys={['username', 'email', 'role']}
        onEdit={item => { setSelected(item); setModal('edit') }}
        onDelete={handleDelete}
        onView={item => { setSelected(item); setModal('view') }}
      />

      {modal === 'view' && selected && (
        <Modal title={`Usuario: ${selected.username}`} onClose={() => setModal(null)}>
          <div className="space-y-2 mb-6">
            {COLUMNS.map(c => (<div key={c.key} className="flex gap-2"><span className="text-hint text-sm w-28 shrink-0">{c.label}:</span><span className="text-white text-sm">{c.render ? c.render(selected[c.key]) : String(selected[c.key] ?? '—')}</span></div>))}
          </div>
          <UserTournaments userId={selected.id} tournaments={tournaments} onToast={showToast} />
        </Modal>
      )}
      {modal === 'create' && (<Modal title="Crear usuario" onClose={() => setModal(null)}><GenericForm fields={FIELDS} onSubmit={handleCreate} onCancel={() => setModal(null)} submitLabel="Crear usuario" /></Modal>)}
      {modal === 'edit' && selected && (<Modal title={`Editar: ${selected.username}`} onClose={() => setModal(null)}><GenericForm fields={EDIT_FIELDS} initial={selected} onSubmit={handleEdit} onCancel={() => setModal(null)} submitLabel="Guardar cambios" /></Modal>)}
      {modal === 'import' && (<ImportModal title="Users" templateHeaders={TEMPLATE_HEADERS} onImport={handleImport} onClose={() => setModal(null)} />)}
      {toast && <Toast {...toast} onClose={hideToast} />}
    </div>
  )
}

function UserTournaments({ userId, tournaments, onToast }) {
  const [followed, setFollowed] = useState([])
  useEffect(() => { api.get('/user-tournaments').then(r => setFollowed(r.data.filter(ut => ut.user_id === userId))).catch(() => {}) }, [userId])
  const follow = async (tid) => {
    try { await api.post('/user-tournaments/follow', { user_id: userId, tournament_id: tid }); const r = await api.get('/user-tournaments'); setFollowed(r.data.filter(ut => ut.user_id === userId)); onToast('Torneo añadido') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const unfollow = async (utId) => {
    try { await api.delete(`/user-tournaments/${utId}`); setFollowed(f => f.filter(ut => ut.id !== utId)); onToast('Torneo eliminado') }
    catch (e) { onToast(e.response?.data?.detail || 'Error', 'error') }
  }
  const followedIds = followed.map(ut => ut.tournament_id)
  return (
    <div>
      <h4 className="text-primary font-semibold mb-2">Torneos que sigue</h4>
      {followed.length === 0 && <p className="text-hint text-sm mb-3">No sigue ningún torneo</p>}
      <div className="space-y-1 mb-4">
        {followed.map(ut => { const t = tournaments.find(x => x.id === ut.tournament_id); return (<div key={ut.id} className="flex items-center justify-between bg-surface-alt px-3 py-2 rounded-lg"><span className="text-white text-sm">{t?.name ?? `Torneo #${ut.tournament_id}`}</span><button onClick={() => unfollow(ut.id)} className="text-error text-xs hover:underline">Quitar</button></div>) })}
      </div>
      {tournaments.filter(t => !followedIds.includes(t.id)).length > 0 && (
        <div><h4 className="text-hint text-sm mb-2">Añadir torneo:</h4><div className="space-y-1">{tournaments.filter(t => !followedIds.includes(t.id)).map(t => (<div key={t.id} className="flex items-center justify-between bg-surface-alt px-3 py-2 rounded-lg"><span className="text-white text-sm">{t.name}</span><button onClick={() => follow(t.id)} className="text-primary text-xs hover:underline">Seguir</button></div>))}</div></div>
      )}
    </div>
  )
}
