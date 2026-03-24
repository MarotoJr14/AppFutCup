import { useState, useRef, useEffect } from 'react'

export default function ExportMenu({ onExport }) {
  const [open, setOpen] = useState(false)
  const ref = useRef()

  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setOpen(o => !o)}
        className="btn-secondary text-sm flex items-center gap-1"
      >
        ⬆ Exportar <span className="text-hint text-xs">▾</span>
      </button>
      {open && (
        <div className="absolute right-0 top-full mt-1 z-50 bg-surface border border-border rounded-xl shadow-xl overflow-hidden w-36">
          <button
            onClick={() => { onExport('csv'); setOpen(false) }}
            className="w-full text-left px-4 py-3 text-sm text-white hover:bg-surface-alt transition-colors flex items-center gap-2"
          >
            <span>📄</span> CSV
          </button>
          <div className="border-t border-border" />
          <button
            onClick={() => { onExport('json'); setOpen(false) }}
            className="w-full text-left px-4 py-3 text-sm text-white hover:bg-surface-alt transition-colors flex items-center gap-2"
          >
            <span>🗂️</span> JSON
          </button>
        </div>
      )}
    </div>
  )
}
