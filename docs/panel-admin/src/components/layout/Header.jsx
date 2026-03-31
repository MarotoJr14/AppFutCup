import { useAuth } from '../../context/AuthContext'
import { useNavigate } from 'react-router-dom'

export default function Header({ title }) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <header className="bg-surface border-b border-border px-6 py-3 flex items-center justify-between sticky top-0 z-40">
      <div className="w-32" />
      <h1 className="text-lg font-bold text-primary text-center">{title}</h1>
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-full bg-primary flex items-center justify-center text-bg font-bold text-sm">
          {user?.username?.[0]?.toUpperCase()}
        </div>
        <div className="hidden sm:block text-right">
          <p className="text-sm font-semibold text-white leading-none">{user?.username}</p>
          <p className="text-xs text-primary">{user?.role}</p>
        </div>
        <button
          onClick={handleLogout}
          className="text-hint hover:text-error transition-colors text-sm ml-2"
          title="Cerrar sesión"
        >
          ⏻
        </button>
      </div>
    </header>
  )
}
