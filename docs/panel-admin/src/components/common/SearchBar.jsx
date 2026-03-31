export default function SearchBar({ value, onChange, placeholder = '🔍 Buscar...' }) {
  return (
    <div className="relative">
      <input
        type="text"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        className="input-base pl-8"
      />
    </div>
  )
}
