import { useState } from 'react'

import './assets/App.css'
import { Route, BrowserRouter, Routes } from 'react-router-dom'
import RestrictedRoute from './components/RestrictedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import ListUsers from './pages/users/ListUsers'

import ListProducts from './pages/products/ListProducts'
import CreateProduct from './pages/products/CreateProduct'
import ShowProductDetails from './pages/products/ShowProductDetails'
import CreateProductVariant from './pages/products/CreateProductVariant'
import CreateClient from './pages/users/create/CreateClient'
import CreateEmployee from './pages/users/create/CreateEmployee'
import CreateProvider from './pages/users/create/CreateProvider'

export const API_URL = 'http://localhost:8080/v1'

const { fetch: originalFetch } = window;
window.fetch = async (...args) => {
  let [resource, options] = args;
  const token = localStorage.getItem('token');

  // options.referrer = 'strict-origin-when-cross-origin';
  if (token) { options.headers['Authorization'] = `Bearer ${token}` }
  options.mode = 'cors'

  const response = await originalFetch(resource, options);
  if (response.status === 401) {
    localStorage.removeItem('token');

    // Call to refresh token and retry request
    const refreshResponse = await originalFetch(API_URL + '/auth/refresh', {
      credentials: 'include',
      mode: 'cors',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const data = await refreshResponse.json();
    if (data.accessToken) {
      localStorage.setItem('token', data.accessToken);
      options.headers['Authorization'] = `Bearer ${data.accessToken}`;

      return originalFetch(resource, options);
    }
  }

  return response;
}

function App() {
  const [count, setCount] = useState(0)

  const dashboard = (
    <RestrictedRoute>
      <Dashboard />
    </RestrictedRoute>
  )

  const listUsers = (
    <RestrictedRoute>
      <ListUsers />
    </RestrictedRoute>
  )

  const createClient = (
    <RestrictedRoute>
      <CreateClient />
    </RestrictedRoute>
  )

  const createEmployee = (
    <RestrictedRoute>
      <CreateEmployee />
    </RestrictedRoute>
  )

  const createProvider = (
    <RestrictedRoute>
      <CreateProvider />
    </RestrictedRoute>
  )

  const listProducts = (
    <RestrictedRoute>
      <ListProducts />
    </RestrictedRoute>
  )

  const createProduct = (
    <RestrictedRoute>
      <CreateProduct />
    </RestrictedRoute>
  )

  const showProductDetails = (
    <RestrictedRoute>
      <ShowProductDetails />
    </RestrictedRoute>
  )

  const createProductVariant = (
    <RestrictedRoute>
      <CreateProductVariant />
    </RestrictedRoute>
  )

  return (
    <>
      <BrowserRouter>
        <Routes>
          <Route path='/' element={dashboard} />
          <Route path='/login' element={<Login />} />
          <Route path='/dashboard' element={dashboard} />
          <Route path='/users' element={listUsers} />
          <Route path='/users/new/provider' element={createProvider} />
          <Route path='/users/new/client' element={createClient} />
          <Route path='/users/new/employee' element={createEmployee} />
          <Route path='/products' element={listProducts} />
          <Route path='/products/new' element={createProduct} />
          <Route path='/products/:id' element={showProductDetails} />
          <Route path='/products/:id/variants/add' element={createProductVariant} />
        </Routes>
      </BrowserRouter>
    </>
  )
}

export default App
