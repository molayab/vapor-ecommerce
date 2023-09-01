import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import posthog from 'posthog-js'

import { PostHogProvider} from 'posthog-js/react'
import { API_URL } from './App.jsx'
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import './assets/index.css'

let socket = new WebSocket(import.meta.env.VITE_WS_URL || 'ws://localhost:8080/notifications')
socket.onopen = function(e) {
  console.log("[open] Connection established");
}
socket.onclose = function(event) {
  if (event.wasClean) {
    console.log(`[close] Connection closed cleanly, code=${event.code} reason=${event.reason}`);
  } else {
    console.log('[close] Connection died');
  }
}
socket.onerror = function(error) {
  console.log(`[error] ${error.message}`);
}
socket.onmessage = function(event) {
  toast(event.data)
  console.log(`[message] Data received from server: ${event.data}`)
}

async function boot() {
  const settings = (await (await fetch(API_URL + '/settings', {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' }
  })).json())

  sessionStorage.setItem('settings', JSON.stringify(settings))
  posthog.init(
    settings.postHog.apiKey,
    {
      api_host: settings.postHog.host,
      loaded: function (posthog) {
        if (posthog.isFeatureEnabled('cms_autocapture_enabled')) {
          posthog.config.autocapture = posthog.isFeatureEnabled('cms_autocapture_enabled');
        } else {
          posthog.config.autocapture = false;
        }
      }
    }
  );
  
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <PostHogProvider client={posthog}>
        <ToastContainer
          position="bottom-right"
          autoClose={30000}
          hideProgressBar={false}
          newestOnTop={false}
          closeOnClick
          rtl={false}
          pauseOnFocusLoss
          draggable
          pauseOnHover
          theme="dark"
          />
        <App />
      </PostHogProvider>
    </React.StrictMode>
  )
}

boot()
