class UserNotificationChannel < ApplicationRecord
  has_many :user_alerts, dependent: :nullify
  
  # Validations
  validates :channel_type, presence: true, inclusion: { in: %w[browser email] }
  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :email_channel?
  validates :enabled, inclusion: { in: [true, false] }
  
  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(channel_type: type) }
  scope :browser_channels, -> { where(channel_type: 'browser') }
  scope :email_channels, -> { where(channel_type: 'email') }
  scope :active, -> { enabled.where('created_at > ?', 30.days.ago) }
  
  # Callbacks
  before_save :normalize_email_address
  after_create :log_channel_creation
  after_update :log_channel_update
  
  # Instance methods
  def browser_channel?
    channel_type == 'browser'
  end
  
  def email_channel?
    channel_type == 'email'
  end
  
  def status
    enabled? ? 'active' : 'inactive'
  end
  
  def channel_description
    case channel_type
    when 'browser'
      'Browser Notifications'
    when 'email'
      "Email: #{email_address}"
    else
      'Unknown Channel'
    end
  end
  
  def send_notification(alert_data)
    case channel_type
    when 'browser'
      # Browser notifications are handled by the frontend
      # We just log that it should be sent
      Rails.logger.info "Browser notification should be sent for alert: #{alert_data[:alert_description]}"
      true
    when 'email'
      send_email_notification(alert_data)
    else
      false
    end
  end
  
  def send_test_notification
    case channel_type
    when 'browser'
      true # Browser test is handled by frontend
    when 'email'
      send_test_email
    else
      false
    end
  end
  
  def preferences_hash
    return {} if preferences.blank?
    
    begin
      JSON.parse(preferences)
    rescue JSON::ParserError
      {}
    end
  end
  
  def update_preferences(new_preferences)
    current_prefs = preferences_hash
    merged_prefs = current_prefs.merge(new_preferences.stringify_keys)
    update(preferences: merged_prefs.to_json)
  end
  
  private
  
  def normalize_email_address
    self.email_address = email_address.downcase.strip if email_address.present?
  end
  
  def log_channel_creation
    Rails.logger.info "Notification Channel created: #{channel_description} (ID: #{id})"
  end
  
  def log_channel_update
    Rails.logger.info "Notification Channel updated: #{channel_description} (ID: #{id})"
  end
  
  def send_email_notification(alert_data)
    return false unless email_channel? && email_address.present?
    
    begin
      # Configure Mailgun
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      
      # Message parameters
      message_params = {
        from: ENV['MAILGUN_FROM_EMAIL'] || 'noreply@yourdomain.com',
        to: email_address,
        subject: "🚨 Crypto Alert: #{alert_data[:symbol]} #{alert_data[:alert_type]} $#{alert_data[:target_price]}",
        text: build_alert_email_text(alert_data),
        html: build_alert_email_html(alert_data)
      }

      # Send the email
      mg_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
      
      # Log the successful email
      Rails.logger.info "Alert email sent successfully to #{email_address} for #{alert_data[:symbol]}"
      true
    rescue => e
      Rails.logger.error "Failed to send alert email: #{e.message}"
      false
    end
  end
  
  def send_test_email
    return false unless email_channel? && email_address.present?
    
    begin
      # Configure Mailgun
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      
      # Message parameters
      message_params = {
        from: ENV['MAILGUN_FROM_EMAIL'] || 'noreply@yourdomain.com',
        to: email_address,
        subject: 'Crypto Alert System - Test Email',
        text: "This is a test email from your crypto alert system.\n\nIf you received this, your email notifications are working correctly!\n\nTimestamp: #{Time.current}",
        html: "<h2>Test Email</h2><p>This is a test email from your crypto alert system.</p><p>If you received this, your email notifications are working correctly!</p><p><strong>Timestamp:</strong> #{Time.current}</p>"
      }

      # Send the email
      mg_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
      
      # Log the successful email
      Rails.logger.info "Test email sent successfully to #{email_address}"
      true
    rescue => e
      Rails.logger.error "Failed to send test email: #{e.message}"
      false
    end
  end
  
  def build_alert_email_text(alert_data)
    <<~EMAIL
      🚨 CRYPTO ALERT TRIGGERED!
      
      Symbol: #{alert_data[:symbol]}
      Alert Type: #{alert_data[:alert_type].upcase}
      Target Price: $#{alert_data[:target_price]}
      Current Price: $#{alert_data[:current_price]}
      Triggered At: #{alert_data[:triggered_at]}
      
      Your cryptocurrency price alert has been triggered!
      
      ---
      Crypto Alert System
      Sent at: #{Time.current}
    EMAIL
  end
  
  def build_alert_email_html(alert_data)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .alert { background-color: #ff4444; color: white; padding: 20px; border-radius: 8px; }
          .details { background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 20px; }
          .price { font-size: 24px; font-weight: bold; color: #ff4444; }
        </style>
      </head>
      <body>
        <div class="alert">
          <h1>🚨 CRYPTO ALERT TRIGGERED!</h1>
        </div>
        
        <div class="details">
          <h2>Alert Details</h2>
          <p><strong>Symbol:</strong> #{alert_data[:symbol]}</p>
          <p><strong>Alert Type:</strong> #{alert_data[:alert_type].upcase}</p>
          <p><strong>Target Price:</strong> <span class="price">$#{alert_data[:target_price]}</span></p>
          <p><strong>Current Price:</strong> <span class="price">$#{alert_data[:current_price]}</span></p>
          <p><strong>Triggered At:</strong> #{alert_data[:triggered_at]}</p>
          
          <p>Your cryptocurrency price alert has been triggered!</p>
        </div>
        
        <hr>
        <p><em>Crypto Alert System - Sent at: #{Time.current}</em></p>
      </body>
      </html>
    HTML
  end
end
