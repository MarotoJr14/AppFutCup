import { SESSION } from './sessionConfig'

const now = () => Date.now()

export function getOrCreateTabId() {
  const existing = sessionStorage.getItem(SESSION.tabIdKey)
  if (existing) return existing
  const id = typeof crypto !== 'undefined' && crypto.randomUUID
    ? crypto.randomUUID()
    : `${now()}-${Math.random().toString(16).slice(2)}`
  sessionStorage.setItem(SESSION.tabIdKey, id)
  return id
}

const tabKey = (tabId) => `${SESSION.tabKeyPrefix}${tabId}`

export function writeTabHeartbeat(tabId, ts = now()) {
  localStorage.setItem(tabKey(tabId), String(ts))
}

export function removeTab(tabId) {
  localStorage.removeItem(tabKey(tabId))
}

export function getActiveTabIds(ts = now()) {
  const active = []
  const keysToDelete = []

  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i)
    if (!k || !k.startsWith(SESSION.tabKeyPrefix)) continue
    const raw = localStorage.getItem(k)
    const t = raw ? Number(raw) : NaN
    if (!Number.isFinite(t) || ts - t > SESSION.tabTtlMs) {
      keysToDelete.push(k)
    } else {
      active.push(k.slice(SESSION.tabKeyPrefix.length))
    }
  }

  keysToDelete.forEach((k) => localStorage.removeItem(k))
  return active
}

export function markPendingReload() {
  sessionStorage.setItem(SESSION.pendingReloadKey, '1')
}

export function consumePendingReload() {
  const v = sessionStorage.getItem(SESSION.pendingReloadKey)
  if (v) sessionStorage.removeItem(SESSION.pendingReloadKey)
  return Boolean(v)
}

export function setReloadBackup(token, userJson) {
  sessionStorage.setItem(SESSION.backupTokenKey, token)
  sessionStorage.setItem(SESSION.backupUserKey, userJson)
}

export function consumeReloadBackup() {
  const token = sessionStorage.getItem(SESSION.backupTokenKey)
  const user = sessionStorage.getItem(SESSION.backupUserKey)
  if (token) sessionStorage.removeItem(SESSION.backupTokenKey)
  if (user) sessionStorage.removeItem(SESSION.backupUserKey)
  if (!token || !user) return null
  return { token, user }
}

