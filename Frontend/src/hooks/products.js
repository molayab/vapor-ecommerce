import { useState, useEffect } from "react";
import { API_URL } from "../App";

/**
 * This hook is used to fetch all products from the backend
 * @returns {Array} Array of products
 */
export function useProducts() {
    const [products, setProducts] = useState(null);

    useEffect(() => {
    const fetchProducts = async () => {
        const response = await fetch(`${API_URL}/products`, {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
            }
        })
        
        return response
    }

    fetchProducts().then((response) => {
        if (response.status === 200) {
            response.json().then((data) => {
                setProducts(data)
            })
        } else {
            alert("Error fetching products")
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
export function useProduct(id) {
    const [product, setProduct] = useState(null);

    useEffect(() => {
    const fetchProduct = async () => {
        const response = await fetch(`${API_URL}/products/${id}`, {
            method: "GET",
            headers: { "Content-Type": "application/json" }
        })
        
        return response
    }

    fetchProduct().then((response) => {
        if (response.status === 200) {
            response.json().then((data) => {
                if (data.variants.length === 0) {
                    data.variants = []
                }
                
                setProduct(data)
            })
        } else {
            alert("Error fetching product")
        }
    })
    }, [id])

    return product
}

export function useDeleteProduct(id) {
    const [deleted, setDeleted] = useState(null);

    useEffect(() => {
    const deleteProduct = async () => {
        const response = await fetch(API_URL + '/products/' + id, {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' }
          })
        
        return response
    }

    deleteProduct().then((response) => {
        if (response.status === 200) {
            setDeleted(true)
        } else {
            alert("Error deleting product")
            setDeleted(false)
        }
    })
    }, [id])

    return deleted
}