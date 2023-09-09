import { fetchAllFeatureFlags } from '../services/featureFlags'
import { useState, useEffect } from 'react'

export function useFeatureFlags () {
  const [flags, setFlags] = useState(null)

  useEffect(() => {
    const fetchFlags = async () => {
      const response = await fetchAllFeatureFlags()
      setFlags(response.data)
    }

    fetchFlags()
  }, [])

  return flags
}
