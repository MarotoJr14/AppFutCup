import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:8000/api/v1',
  headers: { 'Content-Type': 'application/json' },
})

// Ensure all URLs end with a trailing slash to avoid FastAPI redirects
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`

  // Add trailing slash if the URL doesn't already have one and has no query params
  const url = config.url || ''
  if (!url.endsWith('/') && !url.includes('?') && !url.match(/\/\d+$/)) {
    config.url = url + '/'
  }

  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    const isLoginEndpoint = err.config?.url?.includes('/auth/login')
    if (err.response?.status === 401 && !isLoginEndpoint) {
      localStorage.clear()
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api