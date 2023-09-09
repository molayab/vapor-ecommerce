import { request } from './request'

export async function getOrders () {
  try {
    return await request.get('/orders')
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}

export async function anulateOrder (id) {
  try {
    return await request.delete('/orders/anulate', {
      data: { id }
    })
  } catch (error) {
    console.log(error)
    return { status: error.response.status }
  }
}
