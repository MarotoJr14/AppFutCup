import { useState } from 'react'

export default function useImportData() {
  const [importing, setImporting] = useState(false)

  const importData = async (file, format, onRow) => {
    setImporting(true)
    try {
      const text = await file.text()
      const rows = format === 'json' ? _parseJson(text) : _parseCsv(text)
      if (!rows) return { success: 0, errors: ['Archivo inválido o vacío'] }

      const results = { success: 0, errors: [] }
      for (const row of rows) {
        try {
          await onRow(row)
          results.success++
        } catch (e) {
          results.errors.push(e.response?.data?.detail || `Error en fila: ${JSON.stringify(row)}`)
        }
      }
      return results
    } catch {
      return { success: 0, errors: ['Error al leer el archivo'] }
    } finally {
      setImporting(false)
    }
  }

  const _parseCsv = (text) => {
    const lines = text.trim().split('\n')
    if (lines.length < 2) return []
    const headers = lines[0].split(',').map(h => h.replace(/"/g, '').trim())
    return lines.slice(1).map(line => {
      const values = line.match(/(".*?"|[^,]+)(?=,|$)/g) || []
      const obj = {}
      headers.forEach((h, i) => { obj[h] = (values[i] || '').replace(/"/g, '').trim() })
      return obj
    })
  }

  const _parseJson = (text) => {
    try {
      const parsed = JSON.parse(text)
      return Array.isArray(parsed) ? parsed : null
    } catch {
      return null
    }
  }

  return { importData, importing }
}
