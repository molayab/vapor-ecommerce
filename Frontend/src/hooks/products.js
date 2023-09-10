import { useState, useEffect } from 'react'
import { deleteProduct, fetchProduct, fetchProducts } from '../services/products'

/**
 * This hook is used to fetch all products from the backend
 * @returns {Array} Array of products
 */
export function useProducts (page) {
  const [products, setProducts] = useState(null)

  useEffect(() => {
    fetchProducts(page).then((response) => {
      if (response.status === 200) {
        setProducts(response.data)
      } else {
        console.log('Error fetching products')
      }
    })
  }, [])

  return products
}

/**
 * This hook is used to fetch a single product from the backend
 * @param {UUID} id
 * @returns
 */
export function useProduct (id) {
  const [product, setProduct] = useState(null)

  useEffect(() => {
    const fetchProductX = async () => {
      return await fetchProduct(id)
    }

    fetchProductX().then((response) => {
      if (response.status === 200) {
        if (response.data.variants.length === 0) {
          response.data.variants = []
        }

        setProduct(response.data)
      } else {
        console.log('Error fetching product')
      }
    })
  }, [id])

  return product
}

export function useDeleteProduct (id) {
  const [deleted, setDeleted] = useState(null)

  useEffect(() => {
    const deleteProductX = async () => {
      return await deleteProduct(id)
    }

    deleteProductX().then((response) => {
      if (response.status === 200) {
        setDeleted(true)
      } else {
        console.log('Error deleting product')
        setDeleted(false)
      }
    })
  }, [id])

  return deleted
}
