import { API_URL } from "../../App"

export async function getOrders() {
    const response = await fetch(`${API_URL}/orders/all`, {
        method: "GET",
        headers: { "Content-Type": "application/json" }
    })

    return response 
}

export async function anulateOrder(id) {
    const response = await fetch(`${API_URL}/orders/anulate`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: id })
    })

    return response 
}