import { useEffect, useState } from "react"
import { API_URL } from "../App"

/**
 * This hook is used to delete a variant from a product
 * @param {UUID} productId 
 * @param {UUID} variantId 
 * @returns {Boolean} True if the variant was deleted, false otherwise
 */
export function useDeleteVariant(productId, variantId) {
    const [succeed, setSucceed] = useState(null)
    const deleteProductVariant = async () => {
        const response = await fetch(API_URL + '/products/' + productId + '/variants/' + variantId, {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' }
        })
    
        return response
    }

    useEffect(() => {
        deleteProductVariant().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setSucceed(true)
                })
            } else {
                alert("Error deleting variant")
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
export function useCreateVariant(productId, variant) {
    const [succeed, setSucceed] = useState(null)
    const createProductVariant = async () => {
        const response = await fetch(API_URL + '/products/' + productId + '/variants', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(variant)
        })

        return response
    }

    useEffect(() => {
        createProductVariant().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setSucceed(true)
                })
            } else {
                alert("Error creating variant")
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
export function useUpdateVariant(productId, variantId, variant) {
    const [succeed, setSucceed] = useState(null)
    const updateProductVariant = async () => {
        const response = await fetch(API_URL + '/products/' + productId + '/variants/' + variantId, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(variant)
        })

        return response
    }

    useEffect(() => {
        updateProductVariant().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setSucceed(true)
                })
            } else {
                alert("Error updating variant")
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
export function useVariant(productId, variantId) {
    const [variant, setVariant] = useState(null)
    const fetchProductVariant = async (productId, variantId) => {
        const response = await fetch(API_URL + '/products/' + productId + '/variants/' + variantId, {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' }
        })
    
        return response
    }

    useEffect(() => {
        fetchProductVariant(productId, variantId).then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setVariant(data)
                })
            } else {
                alert("Error fetching variant")
            }
        })
    }, [productId, variantId])

    return variant
}

/**
 * This hook is used to generate a SKU for a product variant
 * @returns {Object} Generated SKU
 */
export function useRequestVariantSKU() {
    const [sku, setSKU] = useState(null)
    const requestVariantSKU = async () => {
        const response = await fetch(`${API_URL}/products/new/variants/sku`, {
            method: "GET",
            headers: { "Content-Type": "application/json" }
        })

        return response
    }

    useEffect(() => {
        requestVariantSKU().then((response) => {
            if (response.status === 200) {
                response.json().then((data) => {
                    setSKU(data)
                })
            } else {
                alert("Error fetching SKU")
            }
        })
    }, [])

    return sku
}