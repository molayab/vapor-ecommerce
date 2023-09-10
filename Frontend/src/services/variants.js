import { request } from './request'

export async function fetchVariant (productId, variantId) {
  try {
    return await request.get('/products/' + productId + '/variants/' + variantId)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function createVariant (pid, variant) {
  try {
    return await request.post('/products/' + pid + '/variants', variant)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function updateVariant (pid, id, variant) {
  try {
    return await request.patch('/products/' + pid + '/variants/' + id, variant)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function deleteVariant (pid, id) {
  try {
    return await request.delete('/products/' + pid + '/variants/' + id)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function fetchVariantSales (id) {
  try {
    return await request.get('/orders/variants/' + id)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}
