export default function TableToolbar({ title, filters = [], actions = [] }) {
  return (
    <div className="flex items-center gap-3 mb-4 flex-wrap">
      {/* Title */}
      <h2 className="text-xl font-bold text-white mr-auto">{title}</h2>

      {/* Filters */}
      {filters.map((filter, i) => (
        <div key={i}>{filter}</div>
      ))}

      {/* Action buttons — equal width */}
      {actions.map((action, i) => (
        <div key={i} className="[&>*]:w-full [&>button]:w-full">{action}</div>
      ))}
    </div>
  )
}
