// Alert service for managing price alerts via Rails API
class AlertService {
  constructor() {
    this.baseUrl = '/api/v1/alerts' // This will be your Rails API endpoint
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
      
      return await response.json()
    } catch (error) {
      console.error('Error fetching alerts:', error)
      // Return empty array for now, will be replaced with actual API call
      return []
    }
  }

  // Create a new price alert
  async createAlert(alertData) {
    try {
      const response = await fetch(this.baseUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers when you implement auth
          // 'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(alertData)
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      return await response.json()
    } catch (error) {
      console.error('Error creating alert:', error)
      throw error
    }
  }

  // Update an existing alert
  async updateAlert(alertId, alertData) {
    try {
      const response = await fetch(`${this.baseUrl}/${alertId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers when you implement auth
          // 'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(alertData)
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      return await response.json()
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
          // Add authentication headers when you implement auth
          // 'Authorization': `Bearer ${token}`
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      return true
    } catch (error) {
      console.error('Error deleting alert:', error)
      throw error
    }
  }

  // Toggle alert status (enable/disable)
  async toggleAlert(alertId, enabled) {
    try {
      const response = await fetch(`${this.baseUrl}/${alertId}/toggle`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers when you implement auth
          // 'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ enabled })
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      return await response.json()
    } catch (error) {
      console.error('Error toggling alert:', error)
      throw error
    }
  }

  // Check if any alerts should be triggered based on current prices
  async checkAlertTriggers(currentPrices) {
    try {
      const response = await fetch(`${this.baseUrl}/check_triggers`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers when you implement auth
          // 'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ current_prices: currentPrices })
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      return await response.json()
    } catch (error) {
      console.error('Error checking alert triggers:', error)
      return []
    }
  }

  // Get alert history
  async getAlertHistory(limit = 50) {
    try {
      const response = await fetch(`${this.baseUrl}/history?limit=${limit}`, {
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
      
      return await response.json()
    } catch (error) {
      console.error('Error fetching alert history:', error)
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

  // Format alert data for API
  formatAlertForAPI(alertData) {
    return {
      symbol: alertData.symbol.toUpperCase(),
      target_price: alertData.targetPrice,
      alert_type: alertData.type,
      enabled: alertData.enabled,
      // Add any additional fields your Rails API expects
      // user_id: currentUserId,
      // created_at: new Date().toISOString()
    }
  }
}

export default new AlertService()
