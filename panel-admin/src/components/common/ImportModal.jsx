import { useState, useRef } from 'react'
import Modal from './Modal'

export default function ImportModal({ title, templateHeaders, contextFields = [], onImport, onClose }) {
  const [format, setFormat] = useState('csv')
  const [file, setFile] = useState(null)
  const [context, setContext] = useState({})
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const fileRef = useRef()

  const downloadTemplate = () => {
    let content, filename, mimeType
    if (format === 'csv') {
      content = '\ufeff' + templateHeaders.map(h => `"${h}"`).join(',') + '\n'
      filename = `futcup_plantilla_${title.toLowerCase().replace(/\s/g, '_')}.csv`
      mimeType = 'text/csv;charset=utf-8;'
    } else {
      const example = {}
      templateHeaders.forEach(h => { example[h] = '' })
      content = JSON.stringify([example], null, 2)
      filename = `futcup_plantilla_${title.toLowerCase().replace(/\s/g, '_')}.json`
      mimeType = 'application/json'
    }
    const blob = new Blob([content], { type: mimeType })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    URL.revokeObjectURL(url)
  }

  const handleSubmit = async () => {
    if (!file) return
    setLoading(true)
    const res = await onImport(file, format, context)
    setResult(res)
    setLoading(false)
  }

  const contextComplete = contextFields.every(f => context[f.key])
  const acceptedTypes = format === 'csv' ? '.csv' : '.json'

  return (
    <Modal title={`Importar ${title}`} onClose={onClose}>
      <div className="space-y-5">

        {/* Format selector */}
        <div>
          <p className="text-white text-sm font-semibold mb-2">Formato</p>
          <div className="flex gap-2">
            {['csv', 'json'].map(f => (
              <button
                key={f}
                onClick={() => { setFormat(f); setFile(null) }}
                className={`flex-1 py-2 rounded-lg text-sm font-semibold border transition-colors
                  ${format === f
                    ? 'bg-primary text-bg border-primary'
                    : 'bg-surface-alt text-white border-border hover:border-primary'}`}
              >
                {f === 'csv' ? '📄 CSV' : '🗂️ JSON'}
              </button>
            ))}
          </div>
        </div>

        {/* Step 1 - Download template */}
        <div className="bg-surface-alt rounded-lg p-4">
          <p className="text-white text-sm font-semibold mb-1">Paso 1 — Descarga la plantilla</p>
          <p className="text-hint text-xs mb-3">
            {format === 'csv'
              ? 'Rellena el CSV y vuelve a subirlo. No cambies los nombres de las columnas.'
              : 'Rellena el JSON manteniendo la misma estructura de claves.'}
          </p>
          <button onClick={downloadTemplate} className="btn-secondary text-sm w-full">
            ⬇ Descargar plantilla {format.toUpperCase()}
          </button>
        </div>

        {/* Step 2 - Context selectors */}
        {contextFields.length > 0 && (
          <div className="bg-surface-alt rounded-lg p-4">
            <p className="text-white text-sm font-semibold mb-3">Paso 2 — Selecciona el destino</p>
            <div className="space-y-3">
              {contextFields.map(f => (
                <div key={f.key}>
                  <label className="text-hint text-xs mb-1 block">{f.label} *</label>
                  <select
                    value={context[f.key] || ''}
                    onChange={e => setContext(c => ({ ...c, [f.key]: e.target.value }))}
                    className="input-base bg-bg"
                  >
                    <option value="">— Selecciona —</option>
                    {f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                  </select>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 3 - Upload file */}
        <div className="bg-surface-alt rounded-lg p-4">
          <p className="text-white text-sm font-semibold mb-3">
            Paso {contextFields.length > 0 ? '3' : '2'} — Sube el archivo {format.toUpperCase()}
          </p>
          <input
            ref={fileRef}
            type="file"
            accept={acceptedTypes}
            className="hidden"
            onChange={e => setFile(e.target.files[0])}
          />
          <button onClick={() => fileRef.current.click()} className="btn-secondary text-sm w-full mb-2">
            {file ? `📄 ${file.name}` : `📂 Seleccionar archivo ${format.toUpperCase()}`}
          </button>
          {file && <p className="text-hint text-xs text-center">{file.name}</p>}
        </div>

        {/* Result */}
        {result && (
          <div className={`rounded-lg p-3 text-sm ${result.errors.length === 0 ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'}`}>
            <p className="font-semibold">{result.success} registros importados correctamente</p>
            {result.errors.length > 0 && (
              <ul className="mt-2 space-y-1 text-xs max-h-32 overflow-y-auto">
                {result.errors.map((e, i) => <li key={i}>• {e}</li>)}
              </ul>
            )}
          </div>
        )}

        <div className="flex gap-3 justify-end">
          <button onClick={onClose} className="btn-secondary">Cerrar</button>
          <button
            onClick={handleSubmit}
            disabled={!file || loading || (contextFields.length > 0 && !contextComplete)}
            className="btn-primary"
          >
            {loading ? 'Importando...' : 'Importar'}
          </button>
        </div>
      </div>
    </Modal>
  )
}
