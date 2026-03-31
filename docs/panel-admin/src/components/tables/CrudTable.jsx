import { useState } from 'react'
import Pagination from '../common/Pagination'
import SearchBar from '../common/SearchBar'
import ConfirmDialog from '../common/ConfirmDialog'
import Spinner from '../common/Spinner'
import Badge from '../common/Badge'

const PAGE_SIZE = 10
const BADGE_FIELDS = ['role', 'status', 'is_active']

function SortIcon({ active, direction }) {
  if (!active) return <span className="text-border ml-1 text-xs">⇅</span>
  return <span className="text-primary ml-1 text-xs">{direction === 'asc' ? '↑' : '↓'}</span>
}

export default function CrudTable({ columns, items, loading, onEdit, onDelete, onView, searchKeys = [] }) {
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteStep, setDeleteStep] = useState(0)
  const [sortKey, setSortKey] = useState(null)
  const [sortDir, setSortDir] = useState('asc')

  const handleSort = (key) => {
    if (sortKey === key) {
      setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    } else {
      setSortKey(key)
      setSortDir('asc')
    }
    setPage(1)
  }

  const filtered = search
    ? items.filter(item =>
        searchKeys.some(k => String(item[k] ?? '').toLowerCase().includes(search.toLowerCase()))
      )
    : items

  const sorted = sortKey
    ? [...filtered].sort((a, b) => {
        const aVal = a[sortKey] ?? ''
        const bVal = b[sortKey] ?? ''
        const cmp = String(aVal).localeCompare(String(bVal), 'es', { numeric: true, sensitivity: 'base' })
        return sortDir === 'asc' ? cmp : -cmp
      })
    : filtered

  const totalPages = Math.ceil(sorted.length / PAGE_SIZE)
  const paginated = sorted.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  const handleDeleteClick = (item) => { setDeleteTarget(item); setDeleteStep(1) }
  const handleDeleteConfirm = () => {
    if (deleteStep === 1) { setDeleteStep(2); return }
    onDelete(deleteTarget.id)
    setDeleteTarget(null); setDeleteStep(0)
  }

  const renderCell = (item, col) => {
    const val = item[col.key]
    if (BADGE_FIELDS.includes(col.key)) return <Badge value={val} />
    if (col.render) return col.render(val, item)
    if (val === null || val === undefined) return <span className="text-hint">—</span>
    if (typeof val === 'boolean') return <Badge value={val} />
    const str = String(val)
    return str.length > 40 ? str.slice(0, 40) + '…' : str
  }

  if (loading) return <Spinner />

  return (
    <div>
      {searchKeys.length > 0 && (
        <div className="mb-4">
          <SearchBar value={search} onChange={v => { setSearch(v); setPage(1) }} />
        </div>
      )}

      <div className="overflow-x-auto rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface-alt border-b border-border">
              {columns.map(c => (
                <th
                  key={c.key}
                  onClick={() => handleSort(c.key)}
                  className="text-left px-4 py-3 text-primary font-semibold whitespace-nowrap cursor-pointer select-none hover:text-white transition-colors group"
                >
                  <span className="inline-flex items-center gap-1">
                    {c.label}
                    <SortIcon active={sortKey === c.key} direction={sortDir} />
                  </span>
                </th>
              ))}
              <th className="px-4 py-3 text-primary font-semibold text-right">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {paginated.length === 0 ? (
              <tr><td colSpan={columns.length + 1} className="text-center text-hint py-8">Sin registros</td></tr>
            ) : paginated.map(item => (
              <tr key={item.id} className="border-b border-border hover:bg-surface-alt/50 transition-colors">
                {columns.map(c => (
                  <td key={c.key} className="px-4 py-3 text-white">
                    <button onClick={() => onView?.(item)} className="hover:text-primary transition-colors text-left">
                      {renderCell(item, c)}
                    </button>
                  </td>
                ))}
                <td className="px-4 py-3">
                  <div className="flex gap-2 justify-end">
                    <button onClick={() => onEdit(item)} className="text-xs bg-primary/20 text-primary px-3 py-1 rounded-lg hover:bg-primary/40 transition-colors whitespace-nowrap">Editar</button>
                    <button onClick={() => handleDeleteClick(item)} className="text-xs bg-error/20 text-error px-3 py-1 rounded-lg hover:bg-error/40 transition-colors whitespace-nowrap">Eliminar</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <Pagination page={page} totalPages={totalPages} onChange={setPage} />

      {deleteTarget && deleteStep === 1 && (
        <ConfirmDialog
          message={`¿Eliminar el registro con ID ${deleteTarget.id}? Esta acción no se puede deshacer.`}
          onConfirm={handleDeleteConfirm}
          onCancel={() => { setDeleteTarget(null); setDeleteStep(0) }}
        />
      )}
      {deleteTarget && deleteStep === 2 && (
        <ConfirmDialog
          message={`CONFIRMACIÓN FINAL: ¿Seguro que quieres eliminar permanentemente el registro ID ${deleteTarget.id}?`}
          onConfirm={handleDeleteConfirm}
          onCancel={() => { setDeleteTarget(null); setDeleteStep(0) }}
        />
      )}
    </div>
  )
}
