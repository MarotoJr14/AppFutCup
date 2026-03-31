import { createContext, useContext, useEffect, useRef, useState } from 'react'
import api from '../api/axios'
import { SESSION } from '../session/sessionConfig'
import {
  consumePendingReload,
  consumeReloadBackup,
  getActiveTabIds,
  getOrCreateTabId,
  markPendingReload,
  removeTab,
  setReloadBackup,
  writeTabHeartbeat,
} from '../session/tabRegistry'

const AuthContext = createContext(null)

const now = () => Date.now()

const clearAuthStorage = ({ broadcast = false } = {}) => {
  localStorage.removeItem(SESSION.tokenKey)
  localStorage.removeItem(SESSION.userKey)
  localStorage.removeItem(SESSION.lastActivityKey)
  if (broadcast) localStorage.setItem(SESSION.logoutBroadcastKey, String(now()))
}

const readStoredUser = () => {
  const raw = localStorage.getItem(SESSION.userKey)
  if (!raw) return null
  try { return JSON.parse(raw) } catch { return null }
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const tabIdRef = useRef(null)
  const lastActivityWriteRef = useRef(0)

  useEffect(() => {
    // If we were reloading, restore the auth data that was backed up in this tab.
    const pendingReload = consumePendingReload()
    const backup = consumeReloadBackup()
    if (pendingReload && backup) {
      localStorage.setItem(SESSION.tokenKey, backup.token)
      localStorage.setItem(SESSION.userKey, backup.user)
      localStorage.setItem(SESSION.lastActivityKey, String(now()))
    }

    // If there are no active tabs from a previous session, treat it as end-of-session.
    const token = localStorage.getItem(SESSION.tokenKey)
    const activeBefore = getActiveTabIds()
    if (token && activeBefore.length === 0 && !(pendingReload && backup)) {
      clearAuthStorage()
    }

    // Tab registry + heartbeat
    const tabId = getOrCreateTabId()
    tabIdRef.current = tabId
    writeTabHeartbeat(tabId)
    const hb = window.setInterval(() => writeTabHeartbeat(tabId), SESSION.heartbeatMs)

    const onBeforeUnload = () => {
      // Mark reload intent so we can restore if this navigation was a reload.
      markPendingReload()

      // Remove this tab from the registry.
      removeTab(tabId)

      const activeAfter = getActiveTabIds()
      const tokenNow = localStorage.getItem(SESSION.tokenKey)
      const userNow = localStorage.getItem(SESSION.userKey)

      // If this was the last tab AND we have a session, clear it.
      // For reload, we keep a backup in sessionStorage and restore on next load.
      if (activeAfter.length === 0 && tokenNow && userNow) {
        setReloadBackup(tokenNow, userNow)
        clearAuthStorage({ broadcast: true })
      }
    }

    window.addEventListener('beforeunload', onBeforeUnload)
    window.addEventListener('pagehide', onBeforeUnload)

    // Restore user (if any)
    const storedUser = readStoredUser()
    if (storedUser) setUser(storedUser)
    setLoading(false)

    return () => {
      window.clearInterval(hb)
      window.removeEventListener('beforeunload', onBeforeUnload)
      window.removeEventListener('pagehide', onBeforeUnload)
      removeTab(tabId)
    }
  }, [])

  useEffect(() => {
    const onStorage = (e) => {
      if (e.key === SESSION.logoutBroadcastKey) {
        setUser(null)
      }
      if (e.key === SESSION.tokenKey && !e.newValue) {
        setUser(null)
      }
    }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])

  useEffect(() => {
    // Track activity for idle timeout (only when logged in)
    if (!user) return

    const bump = () => {
      const t = now()
      // throttle writes
      if (t - lastActivityWriteRef.current < 5000) return
      lastActivityWriteRef.current = t
      localStorage.setItem(SESSION.lastActivityKey, String(t))
    }

    const events = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart']
    events.forEach((ev) => window.addEventListener(ev, bump, { passive: true }))
    bump()

    const idleCheck = window.setInterval(() => {
      const token = localStorage.getItem(SESSION.tokenKey)
      if (!token) return
      const last = Number(localStorage.getItem(SESSION.lastActivityKey) || '0')
      if (!last) return
      if (now() - last > SESSION.idleTimeoutMs) {
        clearAuthStorage({ broadcast: true })
        setUser(null)
        window.location.href = '/login'
      }
    }, 30_000)

    return () => {
      events.forEach((ev) => window.removeEventListener(ev, bump))
      window.clearInterval(idleCheck)
    }
  }, [user])

  const login = async (email, password) => {
    const res = await api.post('/auth/login', { email, password })
    const token = res.data.access_token
    localStorage.setItem(SESSION.tokenKey, token)

    const me = await api.get('/users/me')
    if (me.data.role !== 'admin') {
      clearAuthStorage()
      throw new Error('Acceso denegado.')
    }

    localStorage.setItem(SESSION.userKey, JSON.stringify(me.data))
    localStorage.setItem(SESSION.lastActivityKey, String(now()))
    setUser(me.data)
  }

  const logout = () => {
    clearAuthStorage({ broadcast: true })
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)

