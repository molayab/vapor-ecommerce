import { request } from './request'

export const fetchAllFeatureFlags = async () => {
  try {
    const response = await request.get('/settings/flags')
    return response
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export const toggleFeatureFlag = async (flag) => {
  try {
    const response = await request.patch('/settings/flags/' + flag)
    return response
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}
