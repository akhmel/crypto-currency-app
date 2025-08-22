import { useState, useEffect, useRef, useCallback } from 'react'
import * as ActionCable from '@rails/actioncable'

// ActionCable connection setup
let cable = null
let subscription = null

const useCryptoDataStream = () => {
  const [cryptoData, setCryptoData] = useState([])
  const [isConnected, setIsConnected] = useState(false)
  const [connectionStatus, setConnectionStatus] = useState('disconnected')
  const [lastUpdate, setLastUpdate] = useState(null)
  const [error, setError] = useState(null)
  
  const dataRef = useRef(new Map()) // Store latest data for each symbol
  const reconnectTimeoutRef = useRef(null)

  // Initialize ActionCable connection
  const initializeConnection = useCallback(() => {
    try {
      // Create ActionCable consumer
      console.log("Creating ActionCable consumer...")
      setIsConnected(true) // Set connected state to true
      cable = ActionCable.createConsumer('/cable')
      
      subscription = cable.subscriptions.create(
        { channel: 'CryptoDataChannel' },
        {
          connected() {
            console.log('Connected to CryptoDataChannel')
            setIsConnected(true)
            setConnectionStatus('connected')
            setError(null)
            
            // Clear any reconnect timeout
            if (reconnectTimeoutRef.current) {
              clearTimeout(reconnectTimeoutRef.current)
              reconnectTimeoutRef.current = null
            }
          },
          
          disconnected() {
            console.log('Disconnected from CryptoDataChannel')
            setIsConnected(false)
            setConnectionStatus('disconnected')
            
            // Attempt to reconnect after 5 seconds
            reconnectTimeoutRef.current = setTimeout(() => {
              console.log('Attempting to reconnect...')
              setConnectionStatus('reconnecting')
              initializeConnection()
            }, 5000)
          },
          
          rejected() {
            console.error('Connection to CryptoDataChannel was rejected')
            setConnectionStatus('rejected')
            setError('Connection rejected by server')
          },
          
          received(data) {
            handleReceivedData(data)
          }
        }
      )
    } catch (err) {
      console.error('Failed to initialize ActionCable connection:', err)
      setError('Failed to establish connection')
      setConnectionStatus('error')
    }
  }, [])

  // Handle received data from ActionCable
  const handleReceivedData = useCallback((data) => {
    try {
      switch (data.type) {
        case 'initial_data':
          // Initial data when first connecting
          if (data.data && Array.isArray(data.data)) {
            data.data.forEach(item => {
              dataRef.current.set(item.symbol, item)
            })
            setCryptoData(Array.from(dataRef.current.values()))
          }
          break
          
        case 'price_update':
          // Real-time price update
          if (data.data) {
            const symbol = data.data.symbol
            dataRef.current.set(symbol, data.data)
            
            // Update the state with all current data
            setCryptoData(Array.from(dataRef.current.values()))
            setLastUpdate(new Date())
          }
          break
          
        case 'latest_data':
          // Latest data for specific symbol
          if (data.data) {
            dataRef.current.set(data.symbol, data.data)
            setCryptoData(Array.from(dataRef.current.values()))
          }
          break
          
        case 'all_latest_data':
          // All latest data
          if (data.data && Array.isArray(data.data)) {
            data.data.forEach(item => {
              dataRef.current.set(item.symbol, item)
            })
            setCryptoData(Array.from(dataRef.current.values()))
          }
          break
          
        default:
          console.log('Received unknown data type:', data.type)
      }
    } catch (err) {
      console.error('Error handling received data:', err)
      setError('Error processing received data')
    }
  }, [])

  // Request latest data for a specific symbol
  const requestLatestData = useCallback((symbol = null) => {
    if (subscription && isConnected) {
      subscription.perform('request_latest_data', { symbol })
    }
  }, [isConnected])

  // Request all latest data
  const requestAllLatestData = useCallback(() => {
    requestLatestData()
  }, [requestLatestData])

  // Request historical data (placeholder for future implementation)
  const requestHistoricalData = useCallback((params = {}) => {
    if (subscription && isConnected) {
      subscription.perform('request_historical_data', params)
    }
  }, [isConnected])

  // Manual refresh function
  const refreshData = useCallback(() => {
    if (isConnected) {
      requestAllLatestData()
    }
  }, [isConnected, requestAllLatestData])

  // Initialize connection on mount
  useEffect(() => {
    initializeConnection()
    
    // Cleanup on unmount
    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current)
      }
      
      if (subscription) {
        subscription.unsubscribe()
      }
      
      if (cable) {
        cable.disconnect()
      }
    }
  }, [initializeConnection])

  // Auto-refresh data every 30 seconds if connected
  useEffect(() => {
    if (!isConnected) return
    
    const interval = setInterval(() => {
      refreshData()
    }, 30000)
    
    return () => clearInterval(interval)
  }, [isConnected, refreshData])

  return {
    // Data
    cryptoData,
    isConnected,
    connectionStatus,
    lastUpdate,
    error,
    
    // Actions
    refreshData,
    requestLatestData,
    requestAllLatestData,
    requestHistoricalData,
    
    // Utility
    getDataForSymbol: (symbol) => dataRef.current.get(symbol),
    hasData: cryptoData.length > 0
  }
}

export default useCryptoDataStream
