import Axios from 'axios'

const sessionStorage = window.sessionStorage
export const request = Axios.create({
  withCredentials: true,
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8080/v1',
  timeout: 1000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json'
  }
})

// This interceptor is used to add the Authorization header to every request
request.interceptors.request.use(
  function (config) {
    const token = sessionStorage.getItem('token')
    config.headers.Authorization = token ? `Bearer ${token}` : ''
    return config
  },
  function (error) {
    return Promise.reject(error)
  }
)

// This interceptor is used to intercept the response and check if the token is expired
// If the token is expired, it will try to refresh it and retry the original request
request.interceptors.response.use(response => response,
  async function (error) {
    const originalRequest = error.config
    const status = error.response ? error.response.status : null

    console.log('[conn] Intercepting response')
    if (status === 403 && !originalRequest._retry) {
      originalRequest._retry = true
      sessionStorage.removeItem('token')

      // Call to refresh token, send request with the cookie
      // If refresh token is valid, set new token in sessionStorage
      // If refresh token is invalid, redirect to login page

      console.log('[conn] Refreshing token')

      try {
        const response = await request.post('/auth/refresh')
        if (response.status === 200) {
          sessionStorage.setItem('token', response.data.accessToken)

          // Retry the original request
          return request(originalRequest)
        }
      } catch (error) {
        console.log(error)
        return Promise.reject(error)
      }
    } else {
      return Promise.reject(error)
    }
  }
)
