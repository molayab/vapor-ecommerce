import { request } from './request'

export const fetchAllFeatureFlags = async () => {
  try {
    const response = await request.get('/settings/flags')
    return response
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}
