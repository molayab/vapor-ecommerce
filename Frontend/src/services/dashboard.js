import { request } from './request'

export async function fetchDashboardStats () {
  try {
    return await request.get('/dashboard/stats')
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}
