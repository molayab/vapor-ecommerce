import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import posthog from 'posthog-js'

import { PostHogProvider } from 'posthog-js/react'
import { ToastContainer } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'
import './assets/index.css'
import { request } from './services/request.js'
import { connectToWebSocket } from './services/websocket.js'

// This is the entry point of the application, it is responsible for bootstrapping the application.
async function boot () {
  const { sessionStorage } = window
  const settings = (await request.get('/settings')).data

  sessionStorage.setItem('settings', JSON.stringify(settings))
  connectToWebSocket()

  // This configures the PostHog client, it is used to track events and provide feature flags.
  posthog.init(
    settings.postHog.apiKey,
    {
      api_host: settings.postHog.host,
      loaded: function (posthog) {
        if (posthog.isFeatureEnabled('cms_autocapture_enabled')) {
          posthog.config.autocapture = posthog.isFeatureEnabled('cms_autocapture_enabled')
        } else {
          posthog.config.autocapture = false
        }
      }
    }
  )

  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <PostHogProvider client={posthog}>
        <ToastContainer
          position='bottom-right'
          autoClose={15000}
          hideProgressBar={false}
          newestOnTop={false}
          closeOnClick
          rtl={false}
          pauseOnFocusLoss
          draggable
          pauseOnHover
          theme='dark'
        />
        <App />
      </PostHogProvider>
    </React.StrictMode>
  )
}

boot()
