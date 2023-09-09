import { request } from './request'

export async function fetchRoles () {
  try {
    return await request.get('/users/available/roles')
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}
