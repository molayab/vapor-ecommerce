import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import posthog from 'posthog-js'

import { PostHogProvider} from 'posthog-js/react'
import { API_URL } from './App.jsx'

import './assets/index.css'

(async () => {
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
        <App />
      </PostHogProvider>
    </React.StrictMode>
  )
})()
