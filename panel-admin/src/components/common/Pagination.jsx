export default function Pagination({ page, totalPages, onChange }) {
  if (totalPages <= 1) return null
  return (
    <div className="flex items-center justify-center gap-2 mt-4">
      <button onClick={() => onChange(page - 1)} disabled={page === 1} className="btn-secondary px-3 py-1 text-sm disabled:opacity-40">‹</button>
      {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
        <button key={p} onClick={() => onChange(p)}
          className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${p === page ? 'bg-primary text-bg' : 'bg-surface-alt text-white hover:border-primary border border-border'}`}>
          {p}
        </button>
      ))}
      <button onClick={() => onChange(page + 1)} disabled={page === totalPages} className="btn-secondary px-3 py-1 text-sm disabled:opacity-40">›</button>
    </div>
  )
}
