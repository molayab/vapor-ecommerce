import { request } from './request'

export async function createProduct (product) {
  try {
    return await request.post('/products', product)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function updateProduct (id, product) {
  try {
    return await request.patch('/products/' + id, product)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function deleteProduct (id) {
  try {
    return await request.delete('/products/' + id)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function fetchProducts (page, query) {
  try {
    return await request.get(`/products?per=100&page=${page}${query ? `&query=${query}` : ''}`)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function fetchProduct (id) {
  try {
    return await request.get('/products/' + id)
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}

export async function fetchAllProductsForPOS () {
  try {
    return await request.get('/products/pos')
  } catch (error) {
    console.log(error)
    return error.response ? { ...error.response } : { status: 500 }
  }
}
