// Alert service for managing price alerts via Rails API
class AlertService {
  constructor() {
    this.baseUrl = '/api/v1/user_alerts' // Updated to match Rails routes
  }

  // Fetch all alerts for the current user
  async getAlerts() {
    try {
      const response = await fetch(this.baseUrl, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers when you implement auth
          // 'Authorization': `Bearer ${token}`
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data || [] // Extract data from Rails API response
    } catch (error) {
      console.error('Error fetching alerts:', error)
      return []
    }
  }

  // Get a specific alert by ID
  async getAlert(alertId) {
    try {
      const response = await fetch(`${this.baseUrl}/${alertId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data
    } catch (error) {
      console.error('Error fetching alert:', error)
      throw error
    }
  }

  // Create a new price alert
  async createAlert(alertData) {
    try {
      const formattedData = this.formatAlertForAPI(alertData)
      
      const response = await fetch(this.baseUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user_alert: formattedData })
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data
    } catch (error) {
      console.error('Error creating alert:', error)
      throw error
    }
  }

  // Update an existing alert
  async updateAlert(alertId, alertData) {
    try {
      const formattedData = this.formatAlertForAPI(alertData)
      
      const response = await fetch(`${this.baseUrl}/${alertId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user_alert: formattedData })
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data
    } catch (error) {
      console.error('Error updating alert:', error)
      throw error
    }
  }

  // Delete an alert
  async deleteAlert(alertId) {
    try {
      const response = await fetch(`${this.baseUrl}/${alertId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      return true
    } catch (error) {
      console.error('Error deleting alert:', error)
      throw error
    }
  }

  // Toggle alert status (enable/disable) - maps to PATCH /:id/toggle
  async toggleAlert(alertId) {
    try {
      const response = await fetch(`${this.baseUrl}/${alertId}/toggle`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data
    } catch (error) {
      console.error('Error toggling alert:', error)
      throw error
    }
  }

  // Check if any alerts should be triggered based on current prices
  // Maps to GET /check_triggers endpoint
  async checkAlertTriggers(currentPrices) {
    try {
      // Convert currentPrices object to query parameters
      const params = new URLSearchParams()
      Object.entries(currentPrices).forEach(([symbol, price]) => {
        params.append(`current_prices[${symbol}]`, price)
      })
      
      const response = await fetch(`${this.baseUrl}/check_triggers?${params.toString()}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data || []
    } catch (error) {
      console.error('Error checking alert triggers:', error)
      return []
    }
  }

  // Get alerts by symbol
  async getAlertsBySymbol(symbol) {
    try {
      const response = await fetch(`${this.baseUrl}?symbol=${encodeURIComponent(symbol)}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data || []
    } catch (error) {
      console.error('Error fetching alerts by symbol:', error)
      return []
    }
  }

  // Get alerts by type (above/below)
  async getAlertsByType(alertType) {
    try {
      const response = await fetch(`${this.baseUrl}?alert_type=${encodeURIComponent(alertType)}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data || []
    } catch (error) {
      console.error('Error fetching alerts by type:', error)
      return []
    }
  }

  // Get only enabled alerts
  async getEnabledAlerts() {
    try {
      const response = await fetch(`${this.baseUrl}?enabled=true`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data || []
    } catch (error) {
      console.error('Error fetching enabled alerts:', error)
      return []
    }
  }

  // Validate alert data before sending to API
  validateAlertData(alertData) {
    const errors = []
    
    if (!alertData.symbol || alertData.symbol.trim() === '') {
      errors.push('Symbol is required')
    }
    
    if (!alertData.targetPrice || isNaN(alertData.targetPrice) || alertData.targetPrice <= 0) {
      errors.push('Valid target price is required')
    }
    
    if (!['above', 'below'].includes(alertData.type)) {
      errors.push('Alert type must be either "above" or "below"')
    }
    
    return errors
  }

  // Format alert data for Rails API
  formatAlertForAPI(alertData) {
    return {
      symbol: alertData.symbol?.toUpperCase(),
      target_price: parseFloat(alertData.targetPrice),
      alert_type: alertData.type,
      enabled: alertData.enabled !== undefined ? alertData.enabled : true,
      user_id: alertData.userId || 1, // Default user ID, should be dynamic
      notification_channel_id: alertData.notificationChannelId || null
    }
  }

  // Parse Rails API response to frontend format
  parseAlertFromAPI(apiAlert) {
    return {
      id: apiAlert.id,
      symbol: apiAlert.symbol,
      targetPrice: parseFloat(apiAlert.target_price),
      type: apiAlert.alert_type,
      enabled: apiAlert.enabled,
      userId: apiAlert.user_id,
      notificationChannelId: apiAlert.notification_channel_id,
      createdAt: apiAlert.created_at,
      updatedAt: apiAlert.updated_at,
      // Computed properties
      status: apiAlert.enabled ? 'active' : 'inactive',
      alertDescription: `${apiAlert.symbol} ${apiAlert.alert_type} $${apiAlert.target_price}`
    }
  }

  // Parse multiple alerts from API response
  parseAlertsFromAPI(apiAlerts) {
    return apiAlerts.map(alert => this.parseAlertFromAPI(alert))
  }

  // Handle API errors consistently
  handleApiError(error, defaultMessage = 'An error occurred') {
    if (error.message) {
      return error.message
    }
    
    if (error.errors && Array.isArray(error.errors)) {
      return error.errors.join(', ')
    }
    
    return defaultMessage
  }

  // Check if alert should be triggered based on current price
  shouldTriggerAlert(alert, currentPrice) {
    if (!alert.enabled) return false
    
    switch (alert.type) {
      case 'above':
        return currentPrice >= alert.targetPrice
      case 'below':
        return currentPrice <= alert.targetPrice
      default:
        return false
    }
  }

  // Get triggered alerts for current prices
  getTriggeredAlerts(alerts, currentPrices) {
    return alerts.filter(alert => {
      const currentPrice = currentPrices[alert.symbol]
      return currentPrice && this.shouldTriggerAlert(alert, currentPrice)
    })
  }
}

export default new AlertService()
