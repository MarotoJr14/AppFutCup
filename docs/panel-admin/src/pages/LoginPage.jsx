import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { SESSION } from '../session/sessionConfig'
import logoDark from '../assets/futcup_logo_letrablanca.png'

export default function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const logoSrc = logoDark

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [showPass, setShowPass] = useState(false)

  useEffect(() => {
    const msg = sessionStorage.getItem(SESSION.lastAuthErrorKey)
    if (msg) {
      sessionStorage.removeItem(SESSION.lastAuthErrorKey)
      setError(msg)
    }
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      await login(email, password)
      navigate('/')
    } catch (err) {
      const detail = err.response?.data?.detail
      setError(detail || 'Usuario o contraseña incorrectos')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <img src={logoSrc} alt="FutCup" className="h-20 w-auto mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-primary">FutCup App Admin Panel</h1>
          <p className="text-hint text-sm mt-1">Panel de administración</p>
        </div>

        <form onSubmit={handleSubmit} className="card space-y-4">
          <div>
            <label className="text-sm text-hint mb-1 block">Usuario</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="input-base"
              placeholder="usuario"
              required
            />
          </div>

          <div>
            <label className="text-sm text-hint mb-1 block">Contraseña</label>
            <div className="relative">
              <input
                type={showPass ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="input-base pr-10"
                placeholder="••••••••"
                required
              />
              <button
                type="button"
                onClick={() => setShowPass(!showPass)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-hint hover:text-white"
                title={showPass ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                👁
              </button>
            </div>
          </div>

          {error && <p className="text-error text-sm bg-error/10 border border-error/30 rounded-lg px-3 py-2">{error}</p>}

          <button type="submit" disabled={loading} className="btn-primary w-full py-2.5">
            {loading ? 'Iniciando sesión...' : 'Iniciar sesión'}
          </button>
        </form>
      </div>
    </div>
  )
}

