// User Notification Service for managing notification channels via Rails API
class UserNotificationService {
  constructor() {
    this.baseUrl = '/api/v1/user_notification_channels'
  }

  // Supported notification channel types
  static get CHANNEL_TYPES() {
    return {
      BROWSER: 'browser',
      EMAIL: 'email',
      TELEGRAM: 'telegram',
      LOG_FILE: 'log_file',
      OS_NOTIFICATION: 'os_notification'
    }
  }

  // Get all notification channels
  async getNotificationChannels() {
    try {
      const response = await fetch(this.baseUrl, {
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
      console.error('Error fetching notification channels:', error)
      return []
    }
  }

  // Get a specific notification channel by ID
  async getNotificationChannel(channelId) {
    try {
      const response = await fetch(`${this.baseUrl}/${channelId}`, {
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
      console.error('Error fetching notification channel:', error)
      throw error
    }
  }

  // Create a new notification channel
  async createNotificationChannel(channelData) {
    try {
      const formattedData = this.formatChannelForAPI(channelData)
      
      const response = await fetch(this.baseUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user_notification_channel: formattedData })
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data
    } catch (error) {
      console.error('Error creating notification channel:', error)
      throw error
    }
  }

  // Update an existing notification channel
  async updateNotificationChannel(channelId, channelData) {
    try {
      const formattedData = this.formatChannelForAPI(channelData)
      
      const response = await fetch(`${this.baseUrl}/${channelId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user_notification_channel: formattedData })
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const result = await response.json()
      return result.data
    } catch (error) {
      console.error('Error updating notification channel:', error)
      throw error
    }
  }

  // Delete a notification channel
  async deleteNotificationChannel(channelId) {
    try {
      const response = await fetch(`${this.baseUrl}/${channelId}`, {
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
      console.error('Error deleting notification channel:', error)
      throw error
    }
  }

  // Toggle notification channel status (enable/disable)
  async toggleNotificationChannel(channelId) {
    try {
      const response = await fetch(`${this.baseUrl}/${channelId}/toggle`, {
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
      console.error('Error toggling notification channel:', error)
      throw error
    }
  }

  // Test notification channel
  async testNotificationChannel(channelId) {
    try {
      const response = await fetch(`${this.baseUrl}/${channelId}/test`, {
        method: 'POST',
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
      console.error('Error testing notification channel:', error)
      throw error
    }
  }

  // Get notification channels by type
  async getNotificationChannelsByType(channelType) {
    try {
      const response = await fetch(`${this.baseUrl}?channel_type=${encodeURIComponent(channelType)}`, {
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
      console.error('Error fetching notification channels by type:', error)
      return []
    }
  }

  // Get only enabled notification channels
  async getEnabledNotificationChannels() {
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
      console.error('Error fetching enabled notification channels:', error)
      return []
    }
  }

  // Validate notification channel data
  validateChannelData(channelData) {
    const errors = []
    
    if (!channelData.channelType || !Object.values(UserNotificationService.CHANNEL_TYPES).includes(channelData.channelType)) {
      errors.push('Valid channel type is required')
    }
    
    // Email-specific validation
    if (channelData.channelType === UserNotificationService.CHANNEL_TYPES.EMAIL) {
      if (!channelData.emailAddress || !this.isValidEmail(channelData.emailAddress)) {
        errors.push('Valid email address is required for email channels')
      }
    }
    
    // Telegram-specific validation
    if (channelData.channelType === UserNotificationService.CHANNEL_TYPES.TELEGRAM) {
      if (!channelData.telegramChatId || !channelData.telegramBotToken) {
        errors.push('Telegram chat ID and bot token are required for Telegram channels')
      }
    }
    
    // Log file validation
    if (channelData.channelType === UserNotificationService.CHANNEL_TYPES.LOG_FILE) {
      if (!channelData.logFilePath) {
        errors.push('Log file path is required for log file channels')
      }
    }
    
    return errors
  }

  // Format channel data for Rails API
  formatChannelForAPI(channelData) {
    const baseData = {
      channel_type: channelData.channelType,
      enabled: channelData.enabled !== undefined ? channelData.enabled : true,
      user_id: channelData.userId || 1,
      preferences: this.formatPreferencesForAPI(channelData)
    }

    // Add channel-specific fields
    switch (channelData.channelType) {
      case UserNotificationService.CHANNEL_TYPES.EMAIL:
        baseData.email_address = channelData.emailAddress
        break
      case UserNotificationService.CHANNEL_TYPES.TELEGRAM:
        baseData.telegram_chat_id = channelData.telegramChatId
        baseData.telegram_bot_token = channelData.telegramBotToken
        break
      case UserNotificationService.CHANNEL_TYPES.LOG_FILE:
        baseData.log_file_path = channelData.logFilePath
        break
      case UserNotificationService.CHANNEL_TYPES.OS_NOTIFICATION:
        baseData.os_notification_settings = channelData.osNotificationSettings
        break
    }

    return baseData
  }

  // Format preferences for API
  formatPreferencesForAPI(channelData) {
    const preferences = {}
    
    // Common preferences
    if (channelData.enabled !== undefined) preferences.enabled = channelData.enabled
    if (channelData.name) preferences.name = channelData.name
    if (channelData.description) preferences.description = channelData.description
    
    // Channel-specific preferences
    switch (channelData.channelType) {
      case UserNotificationService.CHANNEL_TYPES.BROWSER:
        preferences.sound = channelData.sound !== undefined ? channelData.sound : true
        preferences.duration = channelData.duration || 5000
        preferences.icon = channelData.icon
        break
      case UserNotificationService.CHANNEL_TYPES.EMAIL:
        preferences.html_format = channelData.htmlFormat !== undefined ? channelData.htmlFormat : true
        preferences.frequency = channelData.frequency || 'immediate'
        preferences.subject_template = channelData.subjectTemplate
        break
      case UserNotificationService.CHANNEL_TYPES.TELEGRAM:
        preferences.parse_mode = channelData.parseMode || 'HTML'
        preferences.disable_web_page_preview = channelData.disableWebPagePreview || false
        break
      case UserNotificationService.CHANNEL_TYPES.LOG_FILE:
        preferences.log_level = channelData.logLevel || 'INFO'
        preferences.max_file_size = channelData.maxFileSize || '10MB'
        preferences.rotation = channelData.rotation || 'daily'
        break
      case UserNotificationService.CHANNEL_TYPES.OS_NOTIFICATION:
        preferences.sound = channelData.sound !== undefined ? channelData.sound : true
        preferences.priority = channelData.priority || 'normal'
        preferences.timeout = channelData.timeout || 5000
        break
    }
    
    return JSON.stringify(preferences)
  }

  // Parse Rails API response to frontend format
  parseChannelFromAPI(apiChannel) {
    const preferences = this.parsePreferencesFromAPI(apiChannel.preferences)
    
    return {
      id: apiChannel.id,
      channelType: apiChannel.channel_type,
      enabled: apiChannel.enabled,
      userId: apiChannel.user_id,
      createdAt: apiChannel.created_at,
      updatedAt: apiChannel.updated_at,
      // Channel-specific fields
      emailAddress: apiChannel.email_address,
      telegramChatId: apiChannel.telegram_chat_id,
      telegramBotToken: apiChannel.telegram_bot_token,
      logFilePath: apiChannel.log_file_path,
      osNotificationSettings: apiChannel.os_notification_settings,
      // Preferences
      ...preferences,
      // Computed properties
      status: apiChannel.enabled ? 'active' : 'inactive',
      channelDescription: this.getChannelDescription(apiChannel),
      icon: this.getChannelIcon(apiChannel.channel_type)
    }
  }

  // Parse multiple channels from API response
  parseChannelsFromAPI(apiChannels) {
    return apiChannels.map(channel => this.parseChannelFromAPI(channel))
  }

  // Parse preferences from API
  parsePreferencesFromAPI(preferencesJson) {
    if (!preferencesJson) return {}
    
    try {
      return JSON.parse(preferencesJson)
    } catch (error) {
      console.error('Error parsing preferences:', error)
      return {}
    }
  }

  // Get channel description
  getChannelDescription(channel) {
    switch (channel.channel_type) {
      case UserNotificationService.CHANNEL_TYPES.BROWSER:
        return 'Browser Notifications'
      case UserNotificationService.CHANNEL_TYPES.EMAIL:
        return `Email: ${channel.email_address}`
      case UserNotificationService.CHANNEL_TYPES.TELEGRAM:
        return `Telegram: ${channel.telegram_chat_id}`
      case UserNotificationService.CHANNEL_TYPES.LOG_FILE:
        return `Log File: ${channel.log_file_path}`
      case UserNotificationService.CHANNEL_TYPES.OS_NOTIFICATION:
        return 'OS Notifications'
      default:
        return 'Unknown Channel'
    }
  }

  // Get channel icon
  getChannelIcon(channelType) {
    switch (channelType) {
      case UserNotificationService.CHANNEL_TYPES.BROWSER:
        return '🌐'
      case UserNotificationService.CHANNEL_TYPES.EMAIL:
        return '📧'
      case UserNotificationService.CHANNEL_TYPES.TELEGRAM:
        return '📱'
      case UserNotificationService.CHANNEL_TYPES.LOG_FILE:
        return '📝'
      case UserNotificationService.CHANNEL_TYPES.OS_NOTIFICATION:
        return '🔔'
      default:
        return '❓'
    }
  }

  // Validate email format
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
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

  // Get default preferences for channel type
  getDefaultPreferences(channelType) {
    switch (channelType) {
      case UserNotificationService.CHANNEL_TYPES.BROWSER:
        return {
          sound: true,
          duration: 5000,
          icon: null
        }
      case UserNotificationService.CHANNEL_TYPES.EMAIL:
        return {
          html_format: true,
          frequency: 'immediate',
          subject_template: '🚨 Crypto Alert: {symbol} {alert_type} ${target_price}'
        }
      case UserNotificationService.CHANNEL_TYPES.TELEGRAM:
        return {
          parse_mode: 'HTML',
          disable_web_page_preview: false
        }
      case UserNotificationService.CHANNEL_TYPES.LOG_FILE:
        return {
          log_level: 'INFO',
          max_file_size: '10MB',
          rotation: 'daily'
        }
      case UserNotificationService.CHANNEL_TYPES.OS_NOTIFICATION:
        return {
          sound: true,
          priority: 'normal',
          timeout: 5000
        }
      default:
        return {}
    }
  }
}

export default new UserNotificationService()
