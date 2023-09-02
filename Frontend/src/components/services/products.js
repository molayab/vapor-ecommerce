import { API_URL } from '../../App'

export async function createProduct(product) {
    const response = await fetch(API_URL + '/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(product)
    })

    return response
}

export async function updateProduct(id, product) {
    const response = await fetch(API_URL + '/products/' + id, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(product)
    })

    return response
}

export async function deleteProduct(id) {
    const response = await fetch(API_URL + '/products/' + id, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' }
    })

    return response
}

export async function fetchProducts(page, query) {
    const response = await fetch(`${API_URL}/products?per=100&page=${page}${query ? `&query=${query}` : '' }`, {
        method: "GET",
        headers: { "Content-Type": "application/json", }
    })
    
    return response
}