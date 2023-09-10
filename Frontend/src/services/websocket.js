import { toast } from 'react-toastify'

export function connectToWebSocket () {
  const { WebSocket } = window
  const socket = new WebSocket(import.meta.env.VITE_WS_URL || 'ws://localhost:8080/notifications')
  socket.onopen = function (e) {
    console.log('[sock][open] Connection established')
  }
  socket.onclose = function (event) {
    if (event.wasClean) {
      console.log(`[sock][close] Connection closed cleanly, code=${event.code} reason=${event.reason}`)
    } else {
      console.log('[sock][close] Connection died')
    }
  }
  socket.onerror = function (error) {
    console.log(`[sock][error] ${error.message}`)
  }
  socket.onmessage = function (event) {
    toast(event.data)
    console.log(`[sock][message] Data received from server: ${event.data}`)
  }
}
