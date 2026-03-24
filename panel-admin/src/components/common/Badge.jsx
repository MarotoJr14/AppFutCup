const colors = {
  admin: 'bg-error/20 text-error',
  org:   'bg-warning/20 text-warning',
  user:  'bg-success/20 text-success',
  Pending:  'bg-warning/20 text-warning',
  Playing:  'bg-success/20 text-success',
  Finished: 'bg-hint/20 text-hint',
  true:  'bg-success/20 text-success',
  false: 'bg-hint/20 text-hint',
}

export default function Badge({ value }) {
  const cls = colors[String(value)] || 'bg-surface-alt text-white'
  const labels = { true: 'Sí', false: 'No', Pending: 'Pendiente', Playing: 'En juego', Finished: 'Finalizado' }
  return <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${cls}`}>{labels[String(value)] ?? value}</span>
}
