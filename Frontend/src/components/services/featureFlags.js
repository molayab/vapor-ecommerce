import { API_URL } from '../../App'

export const fetchAllFeatureFlags = async () => {
    const response = await fetch(API_URL + '/settings/flags', {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
    })

    return response
}