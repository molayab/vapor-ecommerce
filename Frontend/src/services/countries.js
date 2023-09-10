import { request } from './request'

export async function fetchCountries () {
  try {
    const response = await request.get('/countries')
    return response
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function fetchAvailableCountryIds () {
  try {
    const response = await request.get('/users/available/national/ids')
    return response
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}
