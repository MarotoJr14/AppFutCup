export default function useExportData() {
  const exportData = (items, columns, filename = 'export', format = 'csv') => {
    if (!items || items.length === 0) return
    if (format === 'csv') _exportCsv(items, columns, filename)
    else _exportJson(items, columns, filename)
  }

  const _exportCsv = (items, columns, filename) => {
    const headers = columns.map(c => c.label)
    const rows = items.map(item =>
      columns.map(c => {
        const val = item[c.key]
        if (val === null || val === undefined) return ''
        if (c.csvRender) return c.csvRender(val, item)
        return String(val).replace(/"/g, '""')
      })
    )
    const content = [headers, ...rows]
      .map(row => row.map(cell => `"${cell}"`).join(','))
      .join('\n')
    _download('\ufeff' + content, `${filename}_${_today()}.csv`, 'text/csv;charset=utf-8;')
  }

  const _exportJson = (items, columns, filename) => {
    const data = items.map(item => {
      const obj = {}
      columns.forEach(c => {
        const val = item[c.key]
        obj[c.key] = c.jsonRender ? c.jsonRender(val, item) : (val ?? null)
      })
      return obj
    })
    _download(JSON.stringify(data, null, 2), `${filename}_${_today()}.json`, 'application/json')
  }

  const _download = (content, filename, mimeType) => {
    const blob = new Blob([content], { type: mimeType })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    URL.revokeObjectURL(url)
  }

  const _today = () => new Date().toISOString().slice(0, 10)

  return { exportData }
}
