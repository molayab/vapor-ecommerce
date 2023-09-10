import { useEffect, useState } from 'react'
import { createVariant, deleteVariant, fetchVariant, updateVariant } from '../services/variants'
import { request } from '../services/request'

/**
 * This hook is used to delete a variant from a product
 * @param {UUID} productId
 * @param {UUID} variantId
 * @returns {Boolean} True if the variant was deleted, false otherwise
 */
export function useDeleteVariant (productId, variantId) {
  const [succeed, setSucceed] = useState(null)
  const deleteProductVariant = async () => {
    return await deleteVariant(productId, variantId)
  }

  useEffect(() => {
    deleteProductVariant().then((response) => {
      if (response.status === 200) {
        setSucceed(true)
      } else {
        console.log('Error deleting variant')
        setSucceed(false)
      }
    })
  }, [productId, variantId])

  return succeed
}

/**
 * This hook is used to create a variant for a product
 * @param {UUID} productId
 * @param {Object} variant
 * @returns {Boolean} True if the variant was created, false otherwise
 */
export function useCreateVariant (productId, variant) {
  const [succeed, setSucceed] = useState(null)
  const createProductVariant = async () => {
    return await createVariant(productId, variant)
  }

  useEffect(() => {
    createProductVariant().then((response) => {
      if (response.status === 200) {
        setSucceed(true)
      } else {
        console.log('Error creating variant')
        setSucceed(false)
      }
    })
  }, [productId, variant])

  return succeed
}

/**
 * This hook is used to update a variant for a product
 * @param {UUID} productId
 * @param {UUID} variantId
 * @param {Object} variant
 */
export function useUpdateVariant (productId, variantId, variant) {
  const [succeed, setSucceed] = useState(null)
  const updateProductVariant = async () => {
    return await updateVariant(productId, variantId, variant)
  }

  useEffect(() => {
    updateProductVariant().then((response) => {
      if (response.status === 200) {
        setSucceed(true)
      } else {
        console.log('Error updating variant')
        setSucceed(false)
      }
    })
  }, [productId, variantId, variant])

  return succeed
}

/**
 * This hook is used to fetch single variant from a product
 * @param {UUID} productId
 * @param {UUID} variantId
 * @returns {Object} Variant object
 */
export function useVariant (productId, variantId) {
  const [variant, setVariant] = useState(null)
  const fetchProductVariant = async (productId, variantId) => {
    return await fetchVariant(productId, variantId)
  }

  useEffect(() => {
    fetchProductVariant(productId, variantId).then((response) => {
      if (response.status === 200) {
        setVariant(response.data)
      } else {
        console.log('Error fetching variant')
      }
    })
  }, [productId, variantId])

  return variant
}

/**
 * This hook is used to generate a SKU for a product variant
 * @returns {Object} Generated SKU
 */
export function useRequestVariantSKU () {
  const [sku, setSKU] = useState(null)
  const requestVariantSKU = async () => {
    return await request.get('/products/new/variants/sku')
  }

  useEffect(() => {
    requestVariantSKU().then((response) => {
      if (response.status === 200) {
        setSKU(response.data)
      } else {
        console.log('Error fetching SKU')
      }
    })
  }, [])

  return sku
}
