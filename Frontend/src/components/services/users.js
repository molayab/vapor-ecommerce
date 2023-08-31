import { API_URL } from "../../App"

export async function removeUser(id) {
    const response = await fetch(`${API_URL}/users/${id}`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" }
    })

    return response
}