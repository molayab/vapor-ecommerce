import { useState, useEffect } from 'react'
import { createCategory, fetchCategories } from '../components/services/categories'

/**
 * This hook is used to create a category
 * @param {String} name
 * @returns {UUID} The id of the created category
 */
export function useCreateCategory(name) {
    const [id, setId] = useState(null)
    const create = async () => await createCategory(name)

    useEffect(() => {
        create().then((response) => {
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

/**
 * This hook is used to fetch all categories
 * @returns {Array} An array of categories
 */
export function useCategories() {
    const [categories, setCategories] = useState(null)
    const fetch = async () => await fetchCategories()

    useEffect(() => {
        fetch().then((response) => {
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