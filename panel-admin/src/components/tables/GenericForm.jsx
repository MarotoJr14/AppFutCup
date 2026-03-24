import { useState, useEffect, useRef } from 'react'

export default function GenericForm({ fields, initial = {}, onSubmit, onCancel, submitLabel = 'Guardar' }) {
  const [form, setForm] = useState(() => {
    const defaults = {}
    fields.forEach(f => {
      const val = initial[f.key]
      if (val !== undefined && val !== null) {
        defaults[f.key] = f.type === 'boolean' ? String(val) : val
      } else {
        defaults[f.key] = f.default ?? ''
      }
    })
    return defaults
  })
  const [errors, setErrors] = useState({})
  const initialKey = useRef(JSON.stringify(initial))

  useEffect(() => {
    const newKey = JSON.stringify(initial)
    if (newKey === initialKey.current) return
    initialKey.current = newKey
    const defaults = {}
    fields.forEach(f => {
      const val = initial[f.key]
      if (val !== undefined && val !== null) {
        defaults[f.key] = f.type === 'boolean' ? String(val) : val
      } else {
        defaults[f.key] = f.default ?? ''
      }
    })
    setForm(defaults)
    setErrors({})
  }, [initial])

  const set = (k, v) => setForm(p => ({ ...p, [k]: v }))

  const validate = () => {
    const errs = {}
    fields.forEach(f => {
      if (f.required) {
        const v = form[f.key]
        if (v === '' || v === null || v === undefined) errs[f.key] = 'Campo requerido'
      }
    })
    setErrors(errs)
    return Object.keys(errs).length === 0
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (!validate()) return
    const payload = {}
    fields.forEach(f => {
      let val = form[f.key]
      if ((val === '' || val === null || val === undefined) && !f.required) return
      if (f.type === 'number' && val !== '') val = Number(val)
      if (f.type === 'boolean') val = val === 'true' || val === true
      payload[f.key] = val
    })
    onSubmit(payload)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {fields.map(f => (
        <div key={f.key}>
          <label className="text-sm text-hint mb-1 block">
            {f.label}{f.required && <span className="text-error ml-1">*</span>}
          </label>

          {f.type === 'select' ? (
            <select value={form[f.key] ?? ''} onChange={e => set(f.key, e.target.value)} className="input-base bg-surface-alt">
              <option value="">— Selecciona —</option>
              {f.options?.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          ) : f.type === 'boolean' ? (
            <select value={String(form[f.key] ?? 'false')} onChange={e => set(f.key, e.target.value)} className="input-base bg-surface-alt">
              <option value="true">Sí</option>
              <option value="false">No</option>
            </select>
          ) : f.type === 'textarea' ? (
            <textarea value={form[f.key] ?? ''} onChange={e => set(f.key, e.target.value)} rows={3} className="input-base resize-none" placeholder={f.placeholder} />
          ) : f.type === 'datetime' ? (
            <input type="datetime-local" value={form[f.key] ?? ''} onChange={e => set(f.key, e.target.value)} className="input-base" />
          ) : (
            <input type={f.type || 'text'} value={form[f.key] ?? ''} onChange={e => set(f.key, e.target.value)} className="input-base" placeholder={f.placeholder} readOnly={f.readOnly} />
          )}

          {errors[f.key] && <p className="text-error text-xs mt-1">{errors[f.key]}</p>}
          {f.hint && <p className="text-hint text-xs mt-1">{f.hint}</p>}
        </div>
      ))}

      <div className="flex gap-3 justify-end pt-2">
        <button type="button" onClick={onCancel} className="btn-secondary">Cancelar</button>
        <button type="submit" className="btn-primary">{submitLabel}</button>
      </div>
    </form>
  )
}
