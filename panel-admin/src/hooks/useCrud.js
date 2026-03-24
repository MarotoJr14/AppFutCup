import { useState, useEffect, useCallback } from 'react'
import api from '../api/axios'

export default function useCrud(endpoint) {
  // Remove trailing slash if present
  const base = endpoint.replace(/\/$/, '')

  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const fetchAll = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get(base)
      setItems(res.data)
    } catch (e) {
      setError(e.response?.data?.detail || 'Error al cargar datos')
    } finally {
      setLoading(false)
    }
  }, [base])

  useEffect(() => { fetchAll() }, [fetchAll])

  const create = async (data) => {
    const res = await api.post(base, data)
    await fetchAll()
    return res.data
  }

  const update = async (id, data) => {
    const res = await api.patch(`${base}/${id}`, data)
    await fetchAll()
    return res.data
  }

  const remove = async (id) => {
    await api.delete(`${base}/${id}`)
    await fetchAll()
  }

  return { items, loading, error, fetchAll, create, update, remove }
}