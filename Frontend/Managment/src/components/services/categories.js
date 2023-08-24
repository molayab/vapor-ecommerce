import { API_URL } from '../../App'

/**
 * This service is used to create a category
 * @param {String} name
 * @returns {UUID} The id of the created category
 */
export async function createCategory(name) {
    const response = await fetch(API_URL + '/categories', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: name })
    })

    let data = await response.json()
    if (response.status === 200) {
        return data.id
    } else {
        return null
    }
}