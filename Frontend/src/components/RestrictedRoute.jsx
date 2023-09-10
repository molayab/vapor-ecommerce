import { Navigate } from 'react-router-dom'

function RestrictedRoute ({ children }) {
  const { sessionStorage } = window

  if (sessionStorage.getItem('token')) {
    return children
  } else {
    return <Navigate to='/login' />
  }
}

export default RestrictedRoute
