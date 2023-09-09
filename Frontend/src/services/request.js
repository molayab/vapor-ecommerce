import Axios from 'axios'

const sessionStorage = window.sessionStorage
export const request = Axios.create({
  withCredentials: true,
  baseURL: 'http://localhost:8080/v1',
  timeout: 1000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json'
  }
})

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

request.interceptors.response.use(response => response,
  function (error) {
    const status = error.response ? error.response.status : null

    if (error.request.config.url === '/auth/create') {
      return Promise.reject(error)
    }

    console.log('Intercepting response')
    if (status === 401) {
      sessionStorage.removeItem('token')

      // Call to refresh token, send request with the cookie
      // If refresh token is valid, set new token in sessionStorage
      // If refresh token is invalid, redirect to login page

      console.log('Refreshing token')
      request.post('/auth/refresh').then((response) => {
        if (response.status === 200) {
          sessionStorage.setItem('token', response.data.accessToken)

          // Retry the original request
          const config = response.config
          return request.request(config)
        }

        // Log the error
        console.log(response)
      })
    }
  }
)
