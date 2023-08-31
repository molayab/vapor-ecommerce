import { API_URL } from '../../App'

export async function fetchVariant(id) {
    const response = await fetch(API_URL + '/variants/' + id, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
    })

    return response
}

export async function createVariant(pid, variant) {
    const response = await fetch(API_URL + '/products/' + pid + '/variants', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(variant)
    })

    return response
}

export async function updateVariant(pid, id, variant) {
    const response = await fetch(API_URL + '/products/' + pid + '/variants/' + id, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(variant)
    })

    return response
}

export async function deleteVariant(pid, id) {
    const response = await fetch(API_URL + '/products/' + pid + '/variants/' + id, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' }
    })

    return response
}