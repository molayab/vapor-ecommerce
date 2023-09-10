import { request } from './request'

/**
 * This service is used to create a category
 * @param {String} name
 * @returns {UUID} The id of the created category
 */
export async function createCategory (name) {
  try {
    const response = await request.post('/categories', { title: name })
    if (response.status === 200) {
      return response.data.id
    } else {
      return null
    }
  } catch (error) {
    console.log(error)
    return error.response ? error.response ? { ...error.response } : { status: 500 } : { status: 500 }
  }
}

export async function fetchCategories () {
  try {
    return await request.get('/categories')
  } catch (error) {
    console.log(error)
    return error.response ? error.response ? { ...error.response } : { status: 500 } : { status: 500 }
  }
}

export async function updateCategory (id, name) {
  try {
    const response = await request.patch('/categories/' + id, { title: name })
    if (response.status === 200) {
      return response.data
    } else {
      return null
    }
  } catch (error) {
    console.log(error)
    return error.response ? error.response ? { ...error.response } : { status: 500 } : { status: 500 }
  }
}

export async function deleteCategory (id) {
  try {
    const response = await request.delete('/categories/' + id)
    if (response.status === 200) {
      return true
    } else {
      return false
    }
  } catch (error) {
    console.log(error)
    return false
  }
}
