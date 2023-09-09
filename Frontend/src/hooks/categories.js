import { useState, useEffect } from 'react'
import { createCategory, fetchCategories } from '../services/categories'

/**
 * This hook is used to create a category
 * @param {String} name
 * @returns {UUID} The id of the created category
 */
export function useCreateCategory (name) {
  const [id, setId] = useState(null)
  const create = async () => await createCategory(name)

  useEffect(() => {
    create().then((response) => {
      if (response.status === 200) {
        setId(response.data.id)
      } else {
        console.log('Error creating category ' + id)
        setId(null)
      }
    })
  }, [name])
}

/**
 * This hook is used to fetch all categories
 * @returns {Array} An array of categories
 */
export function useCategories () {
  const [categories, setCategories] = useState(null)
  const fetch = async () => await fetchCategories()

  useEffect(() => {
    fetch().then((response) => {
      console.log(response)
      if (response.status === 200) {
        setCategories(response.data)
      } else {
        console.log('Error fetching categories')
      }
    })
  }, [])

  return categories
}
