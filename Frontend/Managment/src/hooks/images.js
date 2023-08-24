import { useState, useEffect } from 'react'
import { API_URL } from '../App'

/**
 * This hook is used to upload images to a variant
 * @param {Array} resources
 * @returns {Boolean} True if the images were uploaded, false otherwise
 * 
 * Example of resources:
 * [
 *    {
 *      "name": "image1",
 *      "size": 123456,
 *      "ext": "image/png",
 *      "dat": "<base64 encoded image>"
 *     }
 * ]
*/
export function useUploadImages(resources) {
    const [succeed, setSucceed] = useState(null)
    const uploadImages = async () => {
        const response = await fetch(API_URL + '/products/' + pid + '/variants/' + id + '/images/multiple', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(resources)
        })

        return response
    }

    useEffect(() => {
        uploadImages().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setSucceed(true)
                })
            } else {
                alert("Error uploading images")
                setSucceed(false)
            }
        })
    }, [])

    return succeed
}