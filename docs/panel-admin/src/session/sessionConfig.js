export const SESSION = {
  idleTimeoutMs: 5 * 60 * 1000, // 5 min
  heartbeatMs: 10 * 1000, // 10s
  tabTtlMs: 45 * 1000, // 45s

  tokenKey: 'token',
  userKey: 'user',

  lastActivityKey: 'session:lastActivityAt',
  logoutBroadcastKey: 'session:logoutAt',

  tabIdKey: 'session:tabId',
  tabKeyPrefix: 'session:tab:',

  pendingReloadKey: 'session:pendingReload',
  backupTokenKey: 'session:backupToken',
  backupUserKey: 'session:backupUser',

  lastAuthErrorKey: 'session:lastAuthError',
}
