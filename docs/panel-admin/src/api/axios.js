import axios from 'axios'
import { SESSION } from '../session/sessionConfig'

const clearSession = () => {
  localStorage.removeItem(SESSION.tokenKey)
  localStorage.removeItem(SESSION.userKey)
  localStorage.removeItem(SESSION.lastActivityKey)
}

const broadcastLogout = () => {
  localStorage.setItem(SESSION.logoutBroadcastKey, String(Date.now()))
}

const api = axios.create({
  baseURL: 'https://futcup-backend.up.railway.app/api/v1',
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
