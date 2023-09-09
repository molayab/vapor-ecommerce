import { request } from './request'

export async function fetchVariant (id) {
  try {
    return await request.get('/variants/' + id)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function createVariant (pid, variant) {
  try {
    return await request.post('/products/' + pid + '/variants', variant)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function updateVariant (pid, id, variant) {
  try {
    return await request.patch('/products/' + pid + '/variants/' + id, variant)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function deleteVariant (pid, id) {
  try {
    return await request.delete('/products/' + pid + '/variants/' + id)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}
