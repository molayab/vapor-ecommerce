import { request } from './request'

export async function removeImage (pid, id, image) {
  try {
    return await request.delete('/products/' + pid + '/variants/' + id + '/images',
      { data: { content: image } })
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function uploadMultipleImages (pid, id, images) {
  try {
    return await request.post('/products/' + pid + '/variants/' + id + '/images/multiple', images)
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}
