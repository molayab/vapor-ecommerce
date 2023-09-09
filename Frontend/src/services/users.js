import { request } from './request'

export async function removeUser (id) {
  try {
    return await request.delete('/users/' + id)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function fetchUsers (page, query) {
  try {
    return await request.get(`/users?per=100&page=${page}${query ? `&query=${query}` : ''}`)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function fetchClients (page) {
  try {
    return await request.get('/users/all/clients?page=' + page)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function fetchEmployees (page) {
  try {
    return await request.get('/users/all/employees?page=' + page)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function fetchProviders (page) {
  try {
    return await request.get('/users/all/providers?page=' + page)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function createClientUser (user) {
  try {
    return await request.post('/users/create', user)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function createEmployeeUser (user) {
  try {
    return await request.post('/users/create/employee', user)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function createProviderUser (user) {
  try {
    return await request.post('/users/create/provider', user)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}
