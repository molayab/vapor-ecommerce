import { API_URL } from '../../App'

export async function removeImage(pid, id, image) {
    const response = await fetch(API_URL + '/products/' + pid + '/variants/' + id + '/images', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: image
    })

    return response
}

export async function uploadMultipleImages(pid, id, images) {
    const response = await fetch(API_URL + '/products/' + pid + '/variants/' + id + '/images/multiple', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(images)
    })

    return response
}