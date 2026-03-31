import { useState } from 'react'

export default function useToast() {
  const [toast, setToast] = useState(null)

  const formatMessage = (message) => {
    if (message === null || message === undefined) return ''
    if (typeof message === 'string') return message
    if (typeof message === 'number' || typeof message === 'boolean') return String(message)
    if (Array.isArray(message)) {
      return message
        .map((m) => {
          if (typeof m === 'string') return m
          if (m?.loc && m?.msg) {
            const loc = Array.isArray(m.loc) ? m.loc.join('.') : String(m.loc)
            return `${loc}: ${m.msg}`
          }
          if (m?.msg) return m.msg
          return JSON.stringify(m)
        })
        .filter(Boolean)
        .join(' · ')
    }
    if (typeof message === 'object') {
      if (typeof message.message === 'string') return message.message
      return JSON.stringify(message)
    }
    return String(message)
  }

  const showToast = (message, type = 'success') => setToast({ message: formatMessage(message), type })
  const hideToast = () => setToast(null)

  return { toast, showToast, hideToast }
}
