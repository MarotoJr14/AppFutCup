import { useEffect } from 'react'

export default function Toast({ message, type = 'success', onClose }) {
  useEffect(() => {
    const t = setTimeout(onClose, 3000)
    return () => clearTimeout(t)
  }, [onClose])

  const color = type === 'success' ? 'bg-success' : 'bg-error'
  return (
    <div className={`fixed bottom-6 right-6 z-50 ${color} text-white px-5 py-3 rounded-xl shadow-lg font-medium`}>
      {message}
    </div>
  )
}
