import { useState } from 'react'

import './assets/App.css'
import { Route, BrowserRouter, Routes } from 'react-router-dom'
import RestrictedRoute from './components/RestrictedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import ListUsers from './pages/users/ListUsers'

import ListProducts from './pages/products/ListProducts'
import CreateProduct from './pages/products/CreateProduct'
import CreateProductVariant from './pages/products/CreateProductVariant'
import CreateClient from './pages/users/create/CreateClient'
import CreateEmployee from './pages/users/create/CreateEmployee'
import CreateProvider from './pages/users/create/CreateProvider'
import POS from './pages/POS'
import Settings from './pages/Settings'
import Orders from './pages/Orders'
import FeatureNotAvailable from './pages/FeatureNotAvailable'
import AddCost from './pages/AddCost'
import Finances from './pages/Finances'
import UpdateProduct from './pages/products/UpdateProduct'
import UpdateProductVariant from './pages/products/UpdateProductVariant'

const setttings = JSON.parse(sessionStorage.getItem('settings'))
export const API_URL = setttings.apiUrl + '/v1'
export const RES_URL = setttings.apiUrl

export async function isFeatureEnabled(key) {
  const featureFlags = await getAllFeatureFlags()
  return featureFlags.results.find((flag) => flag.key === key).active
}
export async function getAllFeatureFlags() {
  // Get local feature flags check for expired flags
  if (localStorage.getItem('featureFlags')) {
    const localFlags = JSON.parse(localStorage.getItem('featureFlags'))

    if (localFlags.expiresAt < Date.now()) {
      localStorage.removeItem('featureFlags')
    } else {
      return localFlags.flags
    }
  }

  // Get remote feature flags
  const response = await fetch(API_URL + '/settings/flags', {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' }
  })

  const data = await response.json()
  if (data.error) {
    return
  }

  // Save remote feature flags
  const flags = {
    expiresAt: Date.now() + 1000 * 60 * 60,
    flags: data
  }
  localStorage.setItem('featureFlags', JSON.stringify(flags))
  return flags.flags
}

const { fetch: originalFetch } = window;
window.fetch = async (...args) => {
  let [resource, options] = args;
  const token = sessionStorage.getItem('token');

  // options.referrer = 'strict-origin-when-cross-origin';
  if (token) { options.headers['Authorization'] = `Bearer ${token}` }
  options.mode = 'cors'

  const response = await originalFetch(resource, options);
  if (response.status === 401) {
    sessionStorage.removeItem('token');

    // Call to refresh token and retry request
    const refreshResponse = await originalFetch(API_URL + '/auth/refresh', {
      credentials: 'include',
      mode: 'cors',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    })

    const data = await refreshResponse.json();
    if (data.accessToken) {
      sessionStorage.setItem('token', data.accessToken);
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

  const createProductVariant = (
    <RestrictedRoute>
      <CreateProductVariant />
    </RestrictedRoute>
  )

  const pos = (
    <RestrictedRoute>
      <POS />
    </RestrictedRoute>
  )

  const settings = (
    <RestrictedRoute>
      <Settings />
    </RestrictedRoute>
  )

  const orders = (
    <RestrictedRoute>
      <Orders />
    </RestrictedRoute>
  )

  const restrictedFeature = (
    <RestrictedRoute>
      <FeatureNotAvailable />
    </RestrictedRoute>
  )

  const addCost = (
    <RestrictedRoute>
      <AddCost />
    </RestrictedRoute>
  )

  const finances = (
    <RestrictedRoute>
      <Finances />
    </RestrictedRoute>
  )

  const updateProduct = (
    <RestrictedRoute>
      <UpdateProduct />
    </RestrictedRoute>
  )

  const updateProductVariant = (
    <RestrictedRoute>
      <UpdateProductVariant />
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
          <Route path='/products/:id' element={updateProduct} />
          <Route path='/products/:id/variant' element={createProductVariant} />
          <Route path='/products/:pid/variants/:id' element={updateProductVariant} />
          <Route path='/products/:id/variants' element={updateProduct} />
          <Route path='/products/:pid/variants/:id/edit' element={updateProductVariant} />
          <Route path='/pos' element={pos} />
          <Route path='/settings' element={settings} />
          <Route path='/orders' element={orders} />
          <Route path='/feature-not-available' element={restrictedFeature} />
          <Route path='/add-cost' element={addCost} />
          <Route path='/finances' element={finances} />
        </Routes>
      </BrowserRouter>
    </>
  )
}

export default App
//  <Route path='/products/:pid/variants/:id/edit' element={createProductVariant} />