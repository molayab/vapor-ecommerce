import { request } from './request'

export async function getOrders () {
  try {
    return await request.get('/orders')
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function fetchOrders (page) {
  try {
    return await request.get(`/orders/all?page=${page}&per=100`)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function anulateOrder (id) {
  try {
    return await request.delete('/orders/anulate', {
      data: { id }
    })
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}
