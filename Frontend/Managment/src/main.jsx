import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './assets/index.css'

import posthog from 'posthog-js';
import { PostHogProvider} from 'posthog-js/react'

posthog.init(
  "phc_BrMnlFwv0JkfNj0CpKhaq5fIkfllqzjdH7BorLQpLtX",
  {
    api_host: "https://app.posthog.com",
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
