import { fetchAllFeatureFlags } from "../components/services/featureFlags"
import { useState, useEffect } from 'react'

export function useFeatureFlags() {
    const [flags, setFlags] = useState(null)

    useEffect(() => {
        const fetchFlags = async () => {
            const response = await fetchAllFeatureFlags()
            const data = await response.json()
            console.log(data)
            setFlags(data)
        }

        fetchFlags()
    }, [])

    return flags
}