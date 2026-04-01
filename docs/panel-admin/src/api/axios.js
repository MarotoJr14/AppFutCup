import axios from 'axios'
import { SESSION } from '../session/sessionConfig'

const resolveApiBaseUrl = () => {
  const envUrl = import.meta.env.VITE_API_BASE_URL
  if (envUrl) return envUrl

  // Dev: backend usually runs separately on localhost:8000
  if (import.meta.env.DEV) return 'http://localhost:8000/api/v1'

  // Prod: prefer same-origin (works when served behind a reverse-proxy)
  return `${window.location.origin}/api/v1`
}

const clearSession = () => {
  localStorage.removeItem(SESSION.tokenKey)
  localStorage.removeItem(SESSION.userKey)
  localStorage.removeItem(SESSION.lastActivityKey)
}

const broadcastLogout = () => {
  localStorage.setItem(SESSION.logoutBroadcastKey, String(Date.now()))
}

const api = axios.create({
  baseURL: resolveApiBaseUrl(),
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(SESSION.tokenKey)
  if (token) config.headers.Authorization = `Bearer ${token}`

  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    const isLoginEndpoint = err.config?.url?.includes('/auth/login')
    if (err.response?.status === 401 && !isLoginEndpoint) {
      const detail = err.response?.data?.detail
      sessionStorage.setItem(SESSION.lastAuthErrorKey, detail || 'Token inválido o expirado')
      clearSession()
      broadcastLogout()
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api
