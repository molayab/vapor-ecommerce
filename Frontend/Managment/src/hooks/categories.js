import { useState, useEffect } from 'react'
import { API_URL } from '../App'

/**
 * This hook is used to create a category
 * @param {String} name
 * @returns {UUID} The id of the created category
 */
export function useCreateCategory(name) {
    const [id, setId] = useState(null)
    const createCategory = async () => {
        const response = await fetch(API_URL + '/categories', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title: name })
        })

        return response
    }

    useEffect(() => {
        createCategory().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setId(data.id)
                })
            } else {
                alert("Error creating category")
                setId(null)
            }
        })
    }, [name])

    return succeed
}

export function useCategories() {
    const [categories, setCategories] = useState(null)
    const fetchCategories = async () => {
        const response = await fetch(API_URL + '/categories', {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        })
    
        return response
    }

    useEffect(() => {
        fetchCategories().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setCategories(data)
                })
            } else {
                alert("Error fetching categories")
            }
        })
    }, [])

    return categories
}